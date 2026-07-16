extends Control
## Auto: menu bypass → setup board → make e2e4 → stay alive. Log every step.

const ChessBoard = preload("res://core/board.gd")
const GameState = preload("res://core/game_state.gd")
const PieceCatalog = preload("res://core/piece_catalog.gd")

var log_path: String = "user://autoplay_log.txt"
var step: int = 0
var board_view: Control


func _ready() -> void:
	_log("autoplay start")
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	# Load real board view
	var scene: PackedScene = load("res://scenes/game.tscn")
	_log("scene load ok")
	var game = scene.instantiate()
	GameBus.pending_vs_ai = false
	add_child(game)
	_log("game added")
	await get_tree().process_frame
	await get_tree().process_frame
	board_view = game.get_node_or_null("BoardView")
	_log("board_view=%s" % str(board_view))
	if board_view and board_view.has_method("setup"):
		board_view.setup(false)
		_log("setup done")
	await get_tree().create_timer(0.3).timeout
	_log("calling execute_move e2e4")
	if board_view and board_view.has_method("_execute_move"):
		board_view.call("_execute_move", ChessBoard.sq_of(4, 1), ChessBoard.sq_of(4, 3), 0)
		_log("execute_move returned")
	await get_tree().process_frame
	_log("frame after move")
	await get_tree().create_timer(0.5).timeout
	_log("calling second move e7e5 via try")
	if board_view and board_view.get("state"):
		var st = board_view.state
		var info = st.try_move(ChessBoard.sq_of(4, 6), ChessBoard.sq_of(4, 4))
		_log("second move ok=%s" % str(info.get("ok", false)))
		board_view.queue_redraw()
	await get_tree().create_timer(1.0).timeout
	_log("STILL ALIVE after 1s — no crash")
	# Keep window open a bit
	await get_tree().create_timer(2.0).timeout
	_log("done ok")
	get_tree().quit(0)


func _log(msg: String) -> void:
	var line := "[%s] %s" % [Time.get_datetime_string_from_system(), msg]
	print(line)
	var f := FileAccess.open(log_path, FileAccess.READ_WRITE)
	if f == null:
		f = FileAccess.open(log_path, FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_line(line)
		f.close()
