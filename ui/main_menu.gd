extends Control
## Menu TV — KHONG grab_focus (tranh IME), chi unhandled key.

const PieceCatalog = preload("res://core/piece_catalog.gd")

enum Screen { MAIN, SETTINGS, CHARACTERS }

var screen: int = Screen.MAIN
var menu_index: int = 0
var settings_index: int = 0
var char_index: int = 0
var _last_accept_ms: int = 0

const MAIN_ITEMS := [
	"Choi 2 nguoi (bo me + be)",
	"Choi voi may (de)",
	"Hoc choi (5 buoc)",
	"Gioi thieu nhan vat",
	"Cai dat",
	"Thoat",
]

const SETTINGS_ITEMS := [
	"Goi y nuoc",
	"Hoan tac",
	"Che do hoc choi",
	"Do kho may",
	"Am thanh FX",
	"Nhac nen",
	"Quay lai",
]


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	set_process_input(true)
	if DisplayServer.has_method("window_set_ime_active"):
		DisplayServer.window_set_ime_active(false)
	var vp := get_viewport()
	if vp:
		vp.gui_release_focus()
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var k := event as InputEventKey
	if not k.pressed or k.echo:
		return
	var code: int = k.physical_keycode if k.physical_keycode != 0 else k.keycode
	match screen:
		Screen.MAIN:
			_key_main(code)
		Screen.SETTINGS:
			_key_settings(code)
		Screen.CHARACTERS:
			_key_chars(code)
	var v := get_viewport()
	if v:
		v.set_input_as_handled()


func _accept_ok() -> bool:
	var now: int = Time.get_ticks_msec()
	if now - _last_accept_ms < 280:
		return false
	_last_accept_ms = now
	return true


func _key_main(code: int) -> void:
	if code == KEY_UP:
		menu_index = (menu_index + MAIN_ITEMS.size() - 1) % MAIN_ITEMS.size()
		queue_redraw()
	elif code == KEY_DOWN:
		menu_index = (menu_index + 1) % MAIN_ITEMS.size()
		queue_redraw()
	elif code == KEY_ENTER or code == KEY_KP_ENTER or code == KEY_SPACE:
		if _accept_ok():
			call_deferred("_activate_main")


func _activate_main() -> void:
	if not is_inside_tree():
		return
	match menu_index:
		0:
			GameBus.go_game(false)
		1:
			GameBus.go_game(true)
		2:
			GameBus.go_tutorial()
		3:
			screen = Screen.CHARACTERS
			char_index = 0
			queue_redraw()
		4:
			screen = Screen.SETTINGS
			settings_index = 0
			queue_redraw()
		5:
			get_tree().quit()


func _key_settings(code: int) -> void:
	if code == KEY_UP:
		settings_index = (settings_index + SETTINGS_ITEMS.size() - 1) % SETTINGS_ITEMS.size()
	elif code == KEY_DOWN:
		settings_index = (settings_index + 1) % SETTINGS_ITEMS.size()
	elif code == KEY_ENTER or code == KEY_LEFT or code == KEY_RIGHT or code == KEY_SPACE:
		_toggle_setting()
	elif code == KEY_ESCAPE:
		AppSettings.save_settings()
		screen = Screen.MAIN
	else:
		return
	queue_redraw()


func _toggle_setting() -> void:
	match settings_index:
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
			if AudioMgr:
				AudioMgr.update_music_setting()
		6:
			AppSettings.save_settings()
			screen = Screen.MAIN


func _key_chars(code: int) -> void:
	var n: int = PieceCatalog.all_entries().size()
	if code == KEY_LEFT:
		char_index = (char_index + n - 1) % n
	elif code == KEY_RIGHT:
		char_index = (char_index + 1) % n
	elif code == KEY_ENTER or code == KEY_ESCAPE or code == KEY_SPACE:
		screen = Screen.MAIN
	else:
		return
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), Color("0D47A1"))
	var font = ThemeDB.fallback_font
	if font == null:
		return
	match screen:
		Screen.MAIN:
			_draw_main(font)
		Screen.SETTINGS:
			_draw_settings(font)
		Screen.CHARACTERS:
			_draw_characters(font)


func _draw_main(font) -> void:
	draw_string(font, Vector2(100, 90), "DORAEMON CHESS TV", HORIZONTAL_ALIGNMENT_LEFT, -1, 48, Color("FFF59D"))
	draw_string(font, Vector2(100, 140), "Remote / Keyboard — arrows + Enter", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
	var y := 210.0
	for i in MAIN_ITEMS.size():
		var selected: bool = i == menu_index
		var r := Rect2(100, y, 900, 64)
		draw_rect(r, Color("1565C0") if selected else Color(0.1, 0.14, 0.49, 0.75))
		if selected:
			draw_rect(r, Color("FFEB3B"), false, 3.0)
		var prefix := "> " if selected else "  "
		draw_string(font, Vector2(120, y + 42), prefix + MAIN_ITEMS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color.WHITE)
		y += 76
	draw_string(font, Vector2(100, size.y - 50), "Up/Down select | Enter OK", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 1, 0.7))


func _draw_settings(font) -> void:
	draw_string(font, Vector2(100, 90), "SETTINGS", HORIZONTAL_ALIGNMENT_LEFT, -1, 42, Color("FFF59D"))
	var vals := [
		"On" if AppSettings.hints_enabled else "Off",
		"On" if AppSettings.undo_enabled else "Off",
		"On" if AppSettings.learn_mode else "Off",
		"Easy" if AppSettings.ai_difficulty == 0 else "Medium",
		"On" if AppSettings.sfx_enabled else "Off",
		"On" if AppSettings.music_enabled else "Off",
		"",
	]
	var y := 180.0
	for i in SETTINGS_ITEMS.size():
		var selected: bool = i == settings_index
		var r := Rect2(100, y, 950, 58)
		draw_rect(r, Color("1565C0") if selected else Color(0.1, 0.14, 0.49, 0.75))
		if selected:
			draw_rect(r, Color("FFEB3B"), false, 3.0)
		var label: String = SETTINGS_ITEMS[i]
		if vals[i] != "":
			label += " : " + vals[i]
		draw_string(font, Vector2(120, y + 40), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
		y += 70


func _draw_characters(font) -> void:
	var entries: Array = PieceCatalog.all_entries()
	var e: Dictionary = entries[char_index]
	var t: int = int(e.type)
	draw_string(font, Vector2(100, 90), "CHARACTERS", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color("FFF59D"))
	draw_string(font, Vector2(100, 150), "Left/Right | Enter back", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	var panel := Rect2(200, 200, 880, 400)
	draw_rect(panel, Color("1565C0"))
	draw_rect(panel, Color("FFD54F"), false, 3.0)
	draw_string(font, Vector2(240, 280), PieceCatalog.display_name(t), HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color.WHITE)
	draw_string(font, Vector2(240, 340), PieceCatalog.hint(t), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("E1F5FE"))
	draw_string(font, Vector2(240, 400), str(e.extra), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("FFF59D"))
	draw_string(font, Vector2(240, 480), "%d / %d" % [char_index + 1, entries.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 1, 0.7))
