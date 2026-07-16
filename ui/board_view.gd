extends Control
## Ban co TV — KHONG focus/IME, KHONG Button, cap nhat Label (an toan driver).

const ChessBoard = preload("res://core/board.gd")
const GameState = preload("res://core/game_state.gd")
const PieceCatalog = preload("res://core/piece_catalog.gd")

signal exit_requested
signal game_finished(text)

const SQ := 88
const ORIGIN := Vector2(300, 90)

var state
var cursor := Vector2i(4, 1)
var selected_sq: int = -1
var legal_targets: Dictionary = {}
var hint_from: int = -1
var hint_to: int = -1
var overlay_text: String = ""
var promotion_pending: Dictionary = {}
var promo_index: int = 0
const PROMO_TYPES: Array = [5, 4, 3, 2]  # Q,R,B,N type ids

var _input_lock: float = 0.35
var _esc_armed: bool = false
var _esc_arm_timer: float = 0.0
var _ai_timer: float = -1.0
var _toast_timer: float = 0.0
var _last_accept_ms: int = 0
var _built: bool = false

var _cells: Array = []
var _piece_labels: Array = []
var _dots: Array = []
var _cursor_rect: ColorRect
var _turn_label: Label
var _toast_label: Label
var _promo_label: Label
var _overlay_label: Label


func _ready() -> void:
	_disable_text_input()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	# Nhan input o day, KHONG can focus (tranh IME Unikey/Windows)
	set_process_input(true)
	set_process_unhandled_input(false)
	if state == null:
		state = GameState.new()
		state.new_game(false)
	_build_ui()
	_refresh_all()
	_input_lock = 0.25


func setup(vs_ai: bool) -> void:
	_disable_text_input()
	state = GameState.new()
	state.new_game(vs_ai, 0)
	selected_sq = -1
	legal_targets.clear()
	hint_from = -1
	hint_to = -1
	overlay_text = ""
	promotion_pending.clear()
	cursor = Vector2i(4, 1)
	_input_lock = 0.25
	_esc_armed = false
	_ai_timer = -1.0
	if not _built:
		_build_ui()
	_refresh_all()


func _disable_text_input() -> void:
	# Tat IME — nguyen nhan crash khi go phim sau Enter tren Windows VN
	if DisplayServer.has_method("window_set_ime_active"):
		DisplayServer.window_set_ime_active(false)
	var vp := get_viewport()
	if vp:
		vp.gui_release_focus()


func _build_ui() -> void:
	if _built:
		return
	_built = true

	var bg := ColorRect.new()
	bg.color = Color("1A237E")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.focus_mode = Control.FOCUS_NONE
	add_child(bg)

	for rank in 8:
		for file in 8:
			var draw_rank: int = 7 - rank
			var pos := ORIGIN + Vector2(file * SQ, draw_rank * SQ)

			var cell := ColorRect.new()
			cell.position = pos
			cell.size = Vector2(SQ, SQ)
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell.focus_mode = Control.FOCUS_NONE
			cell.color = Color("FFF8E1") if ((file + rank) % 2 == 0) else Color("81D4FA")
			add_child(cell)
			_cells.append(cell)

			var dot := ColorRect.new()
			dot.position = pos + Vector2(33, 33)
			dot.size = Vector2(22, 22)
			dot.color = Color(0.2, 0.8, 0.3, 0.75)
			dot.visible = false
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			dot.focus_mode = Control.FOCUS_NONE
			add_child(dot)
			_dots.append(dot)

			# Label chu cai quan — KHONG TextureRect (tranh crash GPU/texture)
			var lab := Label.new()
			lab.position = pos + Vector2(4, 20)
			lab.size = Vector2(SQ - 8, 50)
			lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lab.add_theme_font_size_override("font_size", 18)
			lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
			lab.focus_mode = Control.FOCUS_NONE
			add_child(lab)
			_piece_labels.append(lab)

	_cursor_rect = ColorRect.new()
	_cursor_rect.color = Color(1, 0.9, 0.2, 0.4)
	_cursor_rect.size = Vector2(SQ, SQ)
	_cursor_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cursor_rect.focus_mode = Control.FOCUS_NONE
	add_child(_cursor_rect)

	_turn_label = Label.new()
	_turn_label.position = Vector2(30, 30)
	_turn_label.add_theme_font_size_override("font_size", 26)
	_turn_label.add_theme_color_override("font_color", Color.WHITE)
	_turn_label.focus_mode = Control.FOCUS_NONE
	_turn_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_turn_label)

	var help := Label.new()
	help.position = Vector2(30, 70)
	help.add_theme_font_size_override("font_size", 16)
	help.add_theme_color_override("font_color", Color("B3E5FC"))
	help.text = "Arrows=move  Enter=select  Esc=cancel  Escx2=menu  H=hint  U=undo"
	help.focus_mode = Control.FOCUS_NONE
	help.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(help)

	var legend := Label.new()
	legend.position = Vector2(1050, 120)
	legend.add_theme_font_size_override("font_size", 16)
	legend.add_theme_color_override("font_color", Color.WHITE)
	legend.text = "D=King  Xuka=Q\nChaien=R  Xeko=B\nNobita=N  Mini=P"
	legend.focus_mode = Control.FOCUS_NONE
	legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(legend)

	_toast_label = Label.new()
	_toast_label.position = Vector2(30, 640)
	_toast_label.size = Vector2(1000, 40)
	_toast_label.add_theme_font_size_override("font_size", 22)
	_toast_label.add_theme_color_override("font_color", Color("FFD54F"))
	_toast_label.focus_mode = Control.FOCUS_NONE
	_toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast_label)

	_promo_label = Label.new()
	_promo_label.position = Vector2(300, 520)
	_promo_label.visible = false
	_promo_label.add_theme_font_size_override("font_size", 22)
	_promo_label.add_theme_color_override("font_color", Color.WHITE)
	_promo_label.focus_mode = Control.FOCUS_NONE
	_promo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_promo_label)

	_overlay_label = Label.new()
	_overlay_label.position = Vector2(300, 280)
	_overlay_label.size = Vector2(600, 120)
	_overlay_label.visible = false
	_overlay_label.add_theme_font_size_override("font_size", 28)
	_overlay_label.add_theme_color_override("font_color", Color("FFF59D"))
	_overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_label.focus_mode = Control.FOCUS_NONE
	_overlay_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay_label)


func _process(delta: float) -> void:
	if _input_lock > 0.0:
		_input_lock = maxf(0.0, _input_lock - delta)
	if _esc_arm_timer > 0.0:
		_esc_arm_timer -= delta
		if _esc_arm_timer <= 0.0:
			_esc_armed = false
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0 and _toast_label:
			_toast_label.text = ""
	if _ai_timer > 0.0:
		_ai_timer -= delta
		if _ai_timer <= 0.0:
			_ai_timer = -1.0
			_run_ai_move()


func _input(event: InputEvent) -> void:
	if not is_inside_tree() or not visible:
		return
	# Chi xu ly phim vat ly — bo qua IME / text events
	if not (event is InputEventKey):
		return
	var k := event as InputEventKey
	if not k.pressed or k.echo:
		return
	# physical_keycode on dinh hon keycode khi IME bat
	var code: int = k.physical_keycode
	if code == 0:
		code = k.keycode
	if code == 0:
		return
	_handle_key(code)
	var vp := get_viewport()
	if vp:
		vp.set_input_as_handled()


func _handle_key(code: int) -> void:
	if _input_lock > 0.0:
		return

	if overlay_text != "":
		if code == KEY_ENTER or code == KEY_KP_ENTER or code == KEY_ESCAPE or code == KEY_SPACE:
			emit_signal("exit_requested")
		return

	if not promotion_pending.is_empty():
		_handle_promo_key(code)
		return

	match code:
		KEY_LEFT:
			_move_cursor(-1, 0)
		KEY_RIGHT:
			_move_cursor(1, 0)
		KEY_UP:
			_move_cursor(0, 1)
		KEY_DOWN:
			_move_cursor(0, -1)
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			var now: int = Time.get_ticks_msec()
			if now - _last_accept_ms < 300:
				return
			_last_accept_ms = now
			_on_ok()
		KEY_ESCAPE:
			_on_escape()
		KEY_H:
			_do_hint()
		KEY_U:
			_do_undo()
		_:
			pass


func _handle_promo_key(code: int) -> void:
	if code == KEY_LEFT:
		promo_index = (promo_index + PROMO_TYPES.size() - 1) % PROMO_TYPES.size()
		_update_promo_label()
	elif code == KEY_RIGHT:
		promo_index = (promo_index + 1) % PROMO_TYPES.size()
		_update_promo_label()
	elif code == KEY_ENTER or code == KEY_KP_ENTER or code == KEY_SPACE:
		var fr: int = int(promotion_pending.get("from", -1))
		var to: int = int(promotion_pending.get("to", -1))
		var pt: int = int(PROMO_TYPES[promo_index])
		promotion_pending.clear()
		_promo_label.visible = false
		if fr >= 0 and to >= 0:
			_execute_move(fr, to, pt)
	elif code == KEY_ESCAPE:
		promotion_pending.clear()
		_promo_label.visible = false
		_clear_selection()
		_show_toast("Promo cancelled")


func _move_cursor(dx: int, dy: int) -> void:
	cursor.x = clampi(cursor.x + dx, 0, 7)
	cursor.y = clampi(cursor.y + dy, 0, 7)
	_esc_armed = false
	_update_cursor()


func _cursor_sq() -> int:
	return ChessBoard.sq_of(cursor.x, cursor.y)


func _on_ok() -> void:
	if state == null:
		return
	if not state.is_human_turn():
		_show_toast("Wait...")
		return
	var sq: int = _cursor_sq()
	if selected_sq < 0:
		var p: int = state.board.get_piece(sq)
		if ChessBoard.is_empty(p) or ChessBoard.piece_side(p) != state.board.side_to_move:
			_show_toast("Select your piece")
			return
		selected_sq = sq
		_fill_legal(sq)
		_show_toast(PieceCatalog.display_name(ChessBoard.piece_type(p)))
		_refresh_highlights()
		return
	if sq == selected_sq:
		_clear_selection()
		return
	if not legal_targets.has(sq):
		var p2: int = state.board.get_piece(sq)
		if not ChessBoard.is_empty(p2) and ChessBoard.piece_side(p2) == state.board.side_to_move:
			selected_sq = sq
			_fill_legal(sq)
			_refresh_highlights()
			return
		_show_toast("Illegal")
		return
	if _needs_promo(selected_sq, sq):
		promotion_pending = {"from": selected_sq, "to": sq}
		promo_index = 0
		_promo_label.visible = true
		_update_promo_label()
		_show_toast("Promote: Left/Right + Enter")
		return
	var fr: int = selected_sq
	_execute_move(fr, sq, 0)


func _needs_promo(from_sq: int, to_sq: int) -> bool:
	for m in state.get_legal_from(from_sq):
		if int(m.to_sq) == to_sq and int(m.promotion) != 0:
			return true
	return false


func _fill_legal(sq: int) -> void:
	legal_targets.clear()
	for m in state.get_legal_from(sq):
		var is_cap: bool = bool(m.is_en_passant)
		if not is_cap:
			var tp: int = state.board.get_piece(int(m.to_sq))
			is_cap = not ChessBoard.is_empty(tp)
		legal_targets[int(m.to_sq)] = is_cap


func _execute_move(from_sq: int, to_sq: int, promo: int) -> void:
	_input_lock = 0.4
	_esc_armed = false
	_disable_text_input()
	if CrashGuard:
		CrashGuard.block_close(4000)
	print("[MOVE] ", from_sq, "->", to_sq)
	var promo_type: int = promo if promo != 0 else PieceCatalog.Type.QUEEN
	var info: Dictionary = state.try_move(from_sq, to_sq, promo_type)
	selected_sq = -1
	legal_targets.clear()
	hint_from = -1
	hint_to = -1
	if not info.get("ok", false):
		_show_toast("Move failed")
		_refresh_highlights()
		return
	if str(info.get("capture_name", "")) != "":
		_show_toast("Capture!")
	else:
		_show_toast("OK")
	if info.get("check", false) and str(info.get("result_text", "")) == "":
		_show_toast("Check!")
	_refresh_all()
	var result_text: String = str(info.get("result_text", ""))
	if result_text != "":
		overlay_text = result_text
		_overlay_label.text = result_text + "\nEnter = menu"
		_overlay_label.visible = true
		emit_signal("game_finished", result_text)
		return
	if state.vs_ai and not state.is_human_turn():
		_ai_timer = 0.45
		_input_lock = 0.55
	# Quan trong: nha focus/IME sau moi nuoc
	_disable_text_input()
	print("[MOVE] done")


func _run_ai_move() -> void:
	if state == null or not state.vs_ai or state.is_human_turn():
		return
	var ai_info: Dictionary = state.ai_move_if_needed()
	if ai_info.get("ok", false):
		var rt: String = str(ai_info.get("result_text", ""))
		if rt != "":
			overlay_text = rt
			_overlay_label.text = rt + "\nEnter = menu"
			_overlay_label.visible = true
			emit_signal("game_finished", rt)
		else:
			_show_toast("AI moved")
	_refresh_all()
	_input_lock = 0.3
	_disable_text_input()


func _clear_selection() -> void:
	selected_sq = -1
	legal_targets.clear()
	_refresh_highlights()


func _on_escape() -> void:
	if selected_sq >= 0 or not promotion_pending.is_empty():
		promotion_pending.clear()
		if _promo_label:
			_promo_label.visible = false
		_clear_selection()
		_esc_armed = false
		_show_toast("Deselected")
		return
	if not _esc_armed:
		_esc_armed = true
		_esc_arm_timer = 2.0
		_show_toast("Esc again = menu")
		return
	emit_signal("exit_requested")


func _do_hint() -> void:
	if AppSettings != null and not AppSettings.hints_enabled:
		_show_toast("Hints off")
		return
	var m = state.hint_move()
	if m == null:
		_show_toast("No hint")
		return
	hint_from = int(m.from_sq)
	hint_to = int(m.to_sq)
	cursor = Vector2i(ChessBoard.file_of(hint_from), ChessBoard.rank_of(hint_from))
	_show_toast("Hint " + ChessBoard.sq_name(hint_from) + "->" + ChessBoard.sq_name(hint_to))
	_update_cursor()
	_refresh_highlights()


func _do_undo() -> void:
	if state.undo():
		_clear_selection()
		overlay_text = ""
		if _overlay_label:
			_overlay_label.visible = false
		_show_toast("Undone")
		_refresh_all()
	else:
		_show_toast("No undo")


func _show_toast(msg: String, dur: float = 1.6) -> void:
	if _toast_label:
		_toast_label.text = msg
	_toast_timer = dur


func _update_promo_label() -> void:
	if _promo_label == null:
		return
	var names: Array = []
	for i in PROMO_TYPES.size():
		var n: String = PieceCatalog.char_name(int(PROMO_TYPES[i]))
		if i == promo_index:
			names.append(">" + n + "<")
		else:
			names.append(n)
	_promo_label.text = "Promote: " + "  ".join(names)


func _update_cursor() -> void:
	if _cursor_rect == null:
		return
	_cursor_rect.position = ORIGIN + Vector2(cursor.x * SQ, (7 - cursor.y) * SQ)


func _refresh_highlights() -> void:
	if not _built:
		return
	for i in 64:
		var file: int = i % 8
		var rank: int = int(i / 8)
		var light: bool = (file + rank) % 2 == 0
		var base: Color = Color("FFF8E1") if light else Color("81D4FA")
		var cell: ColorRect = _cells[i]
		if i == selected_sq:
			cell.color = Color("64B5F6")
		elif i == hint_from or i == hint_to:
			cell.color = Color("FFF59D")
		else:
			cell.color = base
		var dot: ColorRect = _dots[i]
		if legal_targets.has(i):
			dot.visible = true
			dot.color = Color(1.0, 0.35, 0.2, 0.8) if legal_targets[i] else Color(0.2, 0.85, 0.3, 0.75)
		else:
			dot.visible = false
	_update_cursor()


func _piece_text(p: int) -> String:
	var t: int = ChessBoard.piece_type(p)
	var side: int = ChessBoard.piece_side(p)
	var name: String = PieceCatalog.char_name(t)
	# Rut gon de hien tren o
	var short: String = name
	if short.length() > 6:
		short = short.substr(0, 6)
	var tag: String = "B" if side == 0 else "O"
	return tag + ":" + short


func _refresh_pieces() -> void:
	if not _built or state == null:
		return
	for i in 64:
		var p: int = state.board.get_piece(i)
		var lab: Label = _piece_labels[i]
		if ChessBoard.is_empty(p):
			lab.text = ""
		else:
			lab.text = _piece_text(p)
			var side: int = ChessBoard.piece_side(p)
			lab.add_theme_color_override("font_color", PieceCatalog.fill_color(side))


func _refresh_hud() -> void:
	if _turn_label == null or state == null:
		return
	var side: int = state.board.side_to_move
	var mode := "AI" if state.vs_ai else "2P"
	_turn_label.text = "Doraemon Chess  |  %s  |  %s" % [PieceCatalog.side_name(side), mode]
	_turn_label.add_theme_color_override("font_color", PieceCatalog.fill_color(side))


func _refresh_all() -> void:
	if not _built or state == null:
		return
	_refresh_pieces()
	_refresh_highlights()
	_refresh_hud()
