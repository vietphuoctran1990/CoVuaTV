extends SceneTree

func _init() -> void:
	print("=== start game crash test ===")
	var GameState = load("res://core/game_state.gd")
	var gs = GameState.new()
	gs.new_game(false)
	print("state ok pieces: ", gs.board.get_piece(0))
	var scene: PackedScene = load("res://scenes/game.tscn")
	print("scene loaded: ", scene != null)
	var game = scene.instantiate()
	game.vs_ai = false
	root.add_child(game)
	print("game added, children: ", root.get_child_count())
	await process_frame
	await process_frame
	await process_frame
	print("still alive after 3 frames")
	var bv = game.get_node_or_null("BoardView")
	print("board_view: ", bv)
	if bv:
		print("state: ", bv.state)
		print("size: ", bv.size)
	quit(0)
