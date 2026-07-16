extends Node
## Chan quit/close bat ngo sau nuoc di; log ly do.

var _block_until_ms: int = 0
var _log_path: String = "user://session_log.txt"


var _inited: bool = false


func _ready() -> void:
	if _inited:
		return
	_inited = true
	get_tree().auto_accept_quit = false
	get_tree().quit_on_go_back = false
	if DisplayServer.has_method("window_set_ime_active"):
		DisplayServer.window_set_ime_active(false)
	var root := get_tree().root
	if root != null and root.has_signal("close_requested"):
		if not root.close_requested.is_connected(_on_close_requested):
			root.close_requested.connect(_on_close_requested)
	_log("CrashGuard ready")


func block_close(duration_ms: int = 2500) -> void:
	_block_until_ms = Time.get_ticks_msec() + duration_ms
	# Khong ghi file o day (tranh I/O crash)


func _on_close_requested() -> void:
	var now: int = Time.get_ticks_msec()
	if now < _block_until_ms:
		_log("BLOCKED window close_requested (spurious after move?)")
		return
	_log("Accept quit via window close")
	get_tree().quit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		var now2: int = Time.get_ticks_msec()
		if now2 < _block_until_ms:
			_log("BLOCKED NOTIFICATION_WM_CLOSE_REQUEST")
			return
		_log("Quit via NOTIFICATION_WM_CLOSE_REQUEST")
		get_tree().quit()


func _log(msg: String) -> void:
	var line := "%s | %s" % [Time.get_datetime_string_from_system(), msg]
	print("[GUARD] ", line)
	var f := FileAccess.open(_log_path, FileAccess.READ_WRITE)
	if f == null:
		f = FileAccess.open(_log_path, FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_line(line)
		f.close()
