extends Control
## Single-scene chess. Polling input only. No scene change. Minimal draw.
## Designed to avoid Windows IME / dual-process / file-IO crashes.

const ChessBoard = preload("res://core/board.gd")
const GameState = preload("res://core/game_state.gd")
const PieceCatalog = preload("res://core/piece_catalog.gd")

enum Mode { MENU, PLAY, TUTORIAL, CHARS, SETTINGS }

const SQ := 80
const OX := 280.0
const OY := 70.0
const PROMO := [5, 4, 3, 2]

var mode: int = Mode.MENU
var menu_i: int = 0
var set_i: int = 0
var char_i: int = 0
var tut_i: int = 0

var state
var cursor := Vector2i(4, 1)
var selected: int = -1
var legal: Dictionary = {}
var in_promo: bool = false
var promo_from: int = -1
var promo_to: int = -1
var promo_i: int = 0
var overlay: String = ""
var toast: String = ""
var toast_t: float = 0.0
var lock_t: float = 0.0
var esc_arm: bool = false
var esc_t: float = 0.0
var ai_t: float = -1.0
var vs_ai: bool = false
var dirty: bool = true

# Snapshot for drawing — never touch live board mid-draw
var snap: Array = []
var snap_side: int = 0

var _held: Dictionary = {}

const MENU := ["2 Players", "vs AI", "Tutorial", "Characters", "Settings", "Quit"]


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	focus_mode = FOCUS_NONE
	mouse_filter = MOUSE_FILTER_STOP
	set_process(true)
	set_process_input(false)
	set_process_unhandled_input(false)
	set_process_unhandled_key_input(false)
	get_tree().auto_accept_quit = false
	get_tree().quit_on_go_back = false
	if DisplayServer.has_method("window_set_ime_active"):
		DisplayServer.window_set_ime_active(false)
	for a in ["ui_accept", "ui_cancel", "ui_select", "ui_focus_next", "ui_focus_prev"]:
		if InputMap.has_action(a):
			InputMap.action_erase_events(a)
	var vp := get_viewport()
	if vp:
		vp.gui_release_focus()
	_snapshot_empty()
	dirty = true


func _snapshot_empty() -> void:
	snap.clear()
	snap.resize(64)
	for i in 64:
		snap[i] = 0


func _take_snapshot() -> void:
	if state == null or state.board == null:
		_snapshot_empty()
		return
	snap = state.board.squares.duplicate()
	snap_side = state.board.side_to_move


func _process(delta: float) -> void:
	if lock_t > 0.0:
		lock_t -= delta
	if toast_t > 0.0:
		toast_t -= delta
		if toast_t <= 0.0:
			toast = ""
			dirty = true
	if esc_t > 0.0:
		esc_t -= delta
		if esc_t <= 0.0:
			esc_arm = false
	if ai_t > 0.0:
		ai_t -= delta
		if ai_t <= 0.0:
			ai_t = -1.0
			_ai()

	_poll()

	if dirty:
		dirty = false
		queue_redraw()


func _edge(code: int) -> bool:
	var down: bool = Input.is_physical_key_pressed(code)
	var was: bool = bool(_held.get(code, false))
	_held[code] = down
	return down and not was


func _sync_held() -> void:
	var codes := [
		KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_W, KEY_A, KEY_S, KEY_D,
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE, KEY_H, KEY_U,
	]
	for c in codes:
		_held[c] = Input.is_physical_key_pressed(c)


func _poll() -> void:
	# While locked after a move: only sync held keys (no actions)
	if lock_t > 0.0 and mode == Mode.PLAY:
		_sync_held()
		return

	if _edge(KEY_UP) or _edge(KEY_W):
		_on_key(KEY_UP)
	elif _edge(KEY_DOWN) or _edge(KEY_S):
		_on_key(KEY_DOWN)
	elif _edge(KEY_LEFT) or _edge(KEY_A):
		_on_key(KEY_LEFT)
	elif _edge(KEY_RIGHT) or _edge(KEY_D):
		_on_key(KEY_RIGHT)
	elif _edge(KEY_ENTER) or _edge(KEY_KP_ENTER) or _edge(KEY_SPACE):
		_on_key(KEY_ENTER)
	elif _edge(KEY_ESCAPE):
		_on_key(KEY_ESCAPE)
	elif _edge(KEY_H):
		_on_key(KEY_H)
	elif _edge(KEY_U):
		_on_key(KEY_U)


func _on_key(code: int) -> void:
	match mode:
		Mode.MENU:
			_menu(code)
		Mode.PLAY:
			_play(code)
		Mode.TUTORIAL:
			_tut(code)
		Mode.CHARS:
			_chars(code)
		Mode.SETTINGS:
			_settings(code)
	dirty = true


func _menu(code: int) -> void:
	if code == KEY_UP:
		menu_i = (menu_i + MENU.size() - 1) % MENU.size()
	elif code == KEY_DOWN:
		menu_i = (menu_i + 1) % MENU.size()
	elif code == KEY_ENTER:
		match menu_i:
			0:
				_start(false)
			1:
				_start(true)
			2:
				mode = Mode.TUTORIAL
				tut_i = 0
			3:
				mode = Mode.CHARS
				char_i = 0
			4:
				mode = Mode.SETTINGS
				set_i = 0
			5:
				get_tree().quit()


func _start(p_ai: bool) -> void:
	vs_ai = p_ai
	state = GameState.new()
	state.new_game(vs_ai, 0)
	cursor = Vector2i(4, 1)
	selected = -1
	legal.clear()
	in_promo = false
	overlay = ""
	toast = "Good luck"
	toast_t = 1.2
	esc_arm = false
	lock_t = 0.15
	ai_t = -1.0
	mode = Mode.PLAY
	_take_snapshot()
	if DisplayServer.has_method("window_set_ime_active"):
		DisplayServer.window_set_ime_active(false)
	if get_viewport():
		get_viewport().gui_release_focus()


func _play(code: int) -> void:
	if overlay != "":
		if code == KEY_ENTER or code == KEY_ESCAPE:
			mode = Mode.MENU
			overlay = ""
		return

	if in_promo:
		if code == KEY_LEFT:
			promo_i = (promo_i + 3) % 4
		elif code == KEY_RIGHT:
			promo_i = (promo_i + 1) % 4
		elif code == KEY_ENTER:
			_move(promo_from, promo_to, int(PROMO[promo_i]))
			in_promo = false
		elif code == KEY_ESCAPE:
			in_promo = false
			selected = -1
			legal.clear()
		return

	if code == KEY_LEFT:
		cursor.x = maxi(0, cursor.x - 1)
	elif code == KEY_RIGHT:
		cursor.x = mini(7, cursor.x + 1)
	elif code == KEY_UP:
		cursor.y = mini(7, cursor.y + 1)
	elif code == KEY_DOWN:
		cursor.y = maxi(0, cursor.y - 1)
	elif code == KEY_ENTER:
		_ok()
	elif code == KEY_ESCAPE:
		if selected >= 0:
			selected = -1
			legal.clear()
			_toast("Cancel")
		elif not esc_arm:
			esc_arm = true
			esc_t = 2.0
			_toast("Esc again = menu")
		else:
			mode = Mode.MENU
			esc_arm = false
	elif code == KEY_H:
		_hint()
	elif code == KEY_U:
		_undo()


func _csq() -> int:
	return ChessBoard.sq_of(cursor.x, cursor.y)


func _ok() -> void:
	if state == null:
		return
	if not state.is_human_turn():
		_toast("Wait")
		return
	var sq: int = _csq()
	if selected < 0:
		var p: int = state.board.get_piece(sq)
		if ChessBoard.is_empty(p) or ChessBoard.piece_side(p) != state.board.side_to_move:
			_toast("Your piece")
			return
		selected = sq
		_fill(sq)
		_toast(PieceCatalog.char_name(ChessBoard.piece_type(p)))
		return
	if sq == selected:
		selected = -1
		legal.clear()
		return
	if not legal.has(sq):
		var p2: int = state.board.get_piece(sq)
		if not ChessBoard.is_empty(p2) and ChessBoard.piece_side(p2) == state.board.side_to_move:
			selected = sq
			_fill(sq)
			return
		_toast("Illegal")
		return
	for m in state.get_legal_from(selected):
		if int(m.to_sq) == sq and int(m.promotion) != 0:
			in_promo = true
			promo_from = selected
			promo_to = sq
			promo_i = 0
			_toast("Promote L/R Enter")
			return
	var fr: int = selected
	_move(fr, sq, 0)


func _fill(from_sq: int) -> void:
	legal.clear()
	for m in state.get_legal_from(from_sq):
		var to: int = int(m.to_sq)
		var cap: bool = bool(m.is_en_passant)
		if not cap:
			cap = not ChessBoard.is_empty(state.board.get_piece(to))
		legal[to] = cap


func _move(fr: int, to: int, promo: int) -> void:
	# Long lock: ignore all keys while we settle (prevents Enter-repeat crash path)
	lock_t = 0.55
	esc_arm = false
	var pt: int = promo if promo != 0 else 5
	var info: Dictionary = state.try_move(fr, to, pt)
	selected = -1
	legal.clear()
	if not info.get("ok", false):
		_toast("Fail")
		_take_snapshot()
		return
	_toast("OK")
	if info.get("check", false) and str(info.get("result_text", "")) == "":
		_toast("Check")
	var rt: String = str(info.get("result_text", ""))
	if rt != "":
		overlay = "Game over"
	_take_snapshot()
	if vs_ai and state != null and not state.is_human_turn() and overlay == "":
		ai_t = 0.5
		lock_t = 0.6
	if DisplayServer.has_method("window_set_ime_active"):
		DisplayServer.window_set_ime_active(false)
	if get_viewport():
		get_viewport().gui_release_focus()
	# Force held Enter to be considered still down so release won't re-trigger weirdly
	_sync_held()
	dirty = true


func _ai() -> void:
	if state == null or not vs_ai or state.is_human_turn():
		return
	var info: Dictionary = state.ai_move_if_needed()
	if info.get("ok", false):
		if str(info.get("result_text", "")) != "":
			overlay = "Game over"
		else:
			_toast("AI")
	_take_snapshot()
	lock_t = 0.35
	_sync_held()
	dirty = true


func _hint() -> void:
	if state == null:
		return
	var m = state.hint_move()
	if m == null:
		_toast("No hint")
		return
	cursor = Vector2i(ChessBoard.file_of(int(m.from_sq)), ChessBoard.rank_of(int(m.from_sq)))
	_toast("Hint")


func _undo() -> void:
	if state and state.undo():
		selected = -1
		legal.clear()
		overlay = ""
		_toast("Undo")
		_take_snapshot()
	else:
		_toast("No undo")


func _toast(m: String) -> void:
	toast = m
	toast_t = 1.2
	dirty = true


func _tut(code: int) -> void:
	if code == KEY_RIGHT or code == KEY_ENTER:
		tut_i += 1
		if tut_i > 4:
			mode = Mode.MENU
	elif code == KEY_LEFT:
		tut_i = maxi(0, tut_i - 1)
	elif code == KEY_ESCAPE:
		mode = Mode.MENU


func _chars(code: int) -> void:
	var n: int = 6
	if code == KEY_LEFT:
		char_i = (char_i + n - 1) % n
	elif code == KEY_RIGHT:
		char_i = (char_i + 1) % n
	elif code == KEY_ENTER or code == KEY_ESCAPE:
		mode = Mode.MENU


func _settings(code: int) -> void:
	if code == KEY_UP:
		set_i = (set_i + 6) % 7
	elif code == KEY_DOWN:
		set_i = (set_i + 1) % 7
	elif code == KEY_ENTER or code == KEY_LEFT or code == KEY_RIGHT:
		if set_i == 6:
			if AppSettings:
				AppSettings.save_settings()
			mode = Mode.MENU
		elif AppSettings:
			match set_i:
				0:
					AppSettings.hints_enabled = not AppSettings.hints_enabled
				1:
					AppSettings.undo_enabled = not AppSettings.undo_enabled
				2:
					AppSettings.learn_mode = not AppSettings.learn_mode
				3:
					AppSettings.ai_difficulty = 1 - AppSettings.ai_difficulty
				4:
					AppSettings.sfx_enabled = not AppSettings.sfx_enabled
				5:
					AppSettings.music_enabled = not AppSettings.music_enabled
	elif code == KEY_ESCAPE:
		if AppSettings:
			AppSettings.save_settings()
		mode = Mode.MENU


func _draw() -> void:
	var w: float = maxf(size.x, 1.0)
	var h: float = maxf(size.y, 1.0)
	draw_rect(Rect2(0, 0, w, h), Color(0.05, 0.15, 0.45))
	var font = ThemeDB.fallback_font
	if font == null:
		return
	match mode:
		Mode.MENU:
			_d_menu(font)
		Mode.PLAY:
			_d_play(font)
		Mode.TUTORIAL:
			_d_tut(font)
		Mode.CHARS:
			_d_chars(font)
		Mode.SETTINGS:
			_d_set(font)


func _d_menu(font) -> void:
	draw_string(font, Vector2(80, 80), "DORAEMON CHESS TV", HORIZONTAL_ALIGNMENT_LEFT, -1, 42, Color(1, 0.95, 0.4))
	draw_string(font, Vector2(80, 130), "Turn OFF Unikey (use EN). Arrows + Enter.", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	var y := 190.0
	for i in MENU.size():
		var sel: bool = i == menu_i
		draw_rect(Rect2(80, y, 640, 52), Color(0.1, 0.4, 0.75) if sel else Color(0.08, 0.12, 0.35))
		if sel:
			draw_rect(Rect2(80, y, 640, 52), Color(1, 0.9, 0.2), false, 3.0)
		draw_string(font, Vector2(100, y + 36), ("> " if sel else "  ") + MENU[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
		y += 62


func _d_play(font) -> void:
	# Use snapshot only
	for rank in 8:
		for file in 8:
			var sq: int = rank * 8 + file
			var r := Rect2(OX + file * SQ, OY + (7 - rank) * SQ, SQ, SQ)
			var light: bool = ((file + rank) % 2 == 0)
			var col := Color(1, 0.97, 0.88) if light else Color(0.5, 0.83, 0.98)
			if sq == selected:
				col = Color(0.4, 0.7, 1.0)
			draw_rect(r, col)
			if legal.has(sq):
				var mark := Color(1, 0.3, 0.2, 0.4) if legal[sq] else Color(0.2, 0.8, 0.3, 0.4)
				draw_rect(r.grow(-10), mark)
			if sq < snap.size():
				var p: int = int(snap[sq])
				if p != 0:
					var t: int = p & 7
					var side: int = (p >> 3) & 1
					var ch: String = ["?", "P", "N", "B", "R", "Q", "K"][t] if t <= 6 else "?"
					var nm: String = ["?", "Mini", "Nobi", "Xeko", "Chai", "Xuka", "Dora"][t] if t <= 6 else "?"
					var fc := Color(0.3, 0.75, 1.0) if side == 0 else Color(1.0, 0.55, 0.35)
					draw_string(font, r.position + Vector2(10, 30), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, fc)
					draw_string(font, r.position + Vector2(8, 55), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, fc)
			if file == cursor.x and rank == cursor.y:
				draw_rect(r, Color(1, 0.9, 0.1), false, 4.0)

	var side_name := "Blue" if snap_side == 0 else "Orange"
	draw_string(font, Vector2(40, 36), "Turn: %s  %s" % [side_name, "AI" if vs_ai else "2P"], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
	draw_string(font, Vector2(40, 620), "H=hint U=undo Esc=menu", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.7))
	if toast != "":
		draw_string(font, Vector2(40, 655), toast, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 0.85, 0.2))
	if in_promo:
		draw_string(font, Vector2(300, 530), "Promo Q/R/B/N index=%d (L/R Enter)" % promo_i, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	if overlay != "":
		draw_rect(Rect2(250, 260, 600, 140), Color(0.05, 0.2, 0.1, 0.95))
		draw_string(font, Vector2(280, 330), overlay, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color.WHITE)
		draw_string(font, Vector2(280, 370), "Enter = menu", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.95, 0.5))


func _d_tut(font) -> void:
	var steps := [
		"1. Arrows move cursor, Enter select.",
		"2. Blue moves first, then Orange.",
		"3. D=King Xuka=Q Chai=R Xeko=B Nobi=N Mini=P",
		"4. H hint, U undo, Esc menu.",
		"5. Ready! Enter to finish.",
	]
	draw_string(font, Vector2(80, 100), "TUTORIAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color(1, 0.95, 0.4))
	draw_string(font, Vector2(80, 200), steps[clampi(tut_i, 0, 4)], HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
	draw_string(font, Vector2(80, 500), "Left/Right  Enter  Esc", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.7))


func _d_chars(font) -> void:
	var names := ["Doraemon King", "Xuka Queen", "Chaien Rook", "Xeko Bishop", "Nobita Knight", "Mini Pawn"]
	draw_string(font, Vector2(80, 100), "CHARACTERS", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color(1, 0.95, 0.4))
	draw_string(font, Vector2(80, 220), names[clampi(char_i, 0, 5)], HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color.WHITE)
	draw_string(font, Vector2(80, 400), "Left/Right  Enter back", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)


func _d_set(font) -> void:
	draw_string(font, Vector2(80, 80), "SETTINGS", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color(1, 0.95, 0.4))
	var items: Array = ["Hints", "Undo", "Learn", "AI level", "SFX", "Music", "Back"]
	if AppSettings:
		items = [
			"Hints: " + ("On" if AppSettings.hints_enabled else "Off"),
			"Undo: " + ("On" if AppSettings.undo_enabled else "Off"),
			"Learn: " + ("On" if AppSettings.learn_mode else "Off"),
			"AI: " + ("Easy" if AppSettings.ai_difficulty == 0 else "Med"),
			"SFX: " + ("On" if AppSettings.sfx_enabled else "Off"),
			"Music: " + ("On" if AppSettings.music_enabled else "Off"),
			"Back",
		]
	var y := 150.0
	for i in items.size():
		var sel: bool = i == set_i
		draw_rect(Rect2(80, y, 640, 48), Color(0.1, 0.4, 0.75) if sel else Color(0.08, 0.12, 0.35))
		draw_string(font, Vector2(100, y + 32), ("> " if sel else "  ") + str(items[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
		y += 56
