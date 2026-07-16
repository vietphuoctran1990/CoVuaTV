extends Control
## Scene chơi: gắn BoardView full màn hình.

@export var vs_ai: bool = false

@onready var board_view: Control = $BoardView


func _ready() -> void:
	# Full viewport (tránh size 0x0 khi change_scene)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# vs_ai từ menu qua GameBus
	vs_ai = GameBus.pending_vs_ai

	if board_view == null:
		push_error("BoardView missing")
		return

	if board_view.has_method("setup"):
		board_view.setup(vs_ai)
	if board_view.has_signal("exit_requested"):
		if not board_view.exit_requested.is_connected(_on_exit):
			board_view.exit_requested.connect(_on_exit)
	if board_view.has_signal("game_finished"):
		if not board_view.game_finished.is_connected(_on_finished):
			board_view.game_finished.connect(_on_finished)


func _on_exit() -> void:
	# Trì hoãn 1 frame — tránh đổi scene giữa lúc xử lý input
	call_deferred("_go_menu_safe")


func _go_menu_safe() -> void:
	if is_inside_tree():
		GameBus.go_menu()


func _on_finished(_text: String) -> void:
	pass  # overlay trong board_view; OK/Back → exit_requested
