extends Node
## Chuyển scene an toàn (luôn deferred — không đổi scene giữa input).

signal move_made(move, captured_type, captured_side)
signal check_occurred(side_in_check)
signal game_over(result_text, winner_side)
signal turn_changed(side)
signal toast(message)
signal request_promotion(from_sq, to_sq)
signal board_needs_refresh

var pending_vs_ai: bool = false
var _changing: bool = false


func go_menu() -> void:
	_change("res://scenes/main_menu.tscn")


func go_game(vs_ai: bool) -> void:
	pending_vs_ai = vs_ai
	_change("res://scenes/game.tscn")


func go_tutorial() -> void:
	_change("res://scenes/tutorial.tscn")


func _change(path: String) -> void:
	if _changing:
		return
	_changing = true
	# Đợi hết frame input hiện tại
	call_deferred("_do_change", path)


func _do_change(path: String) -> void:
	var tree := get_tree()
	if tree == null:
		_changing = false
		return
	var err := tree.change_scene_to_file(path)
	if err != OK:
		push_error("change_scene failed: %s err=%s" % [path, str(err)])
		_changing = false
		return
	# Reset flag next frame (không await — tránh coroutine kẹt)
	tree.create_timer(0.05).timeout.connect(func(): _changing = false, CONNECT_ONE_SHOT)
