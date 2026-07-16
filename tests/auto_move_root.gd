extends Control

const ChessBoard = preload("res://core/board.gd")

func _ready() -> void:
	print("AUTO: start")
	await get_tree().process_frame
	await get_tree().process_frame
	var bv = get_node_or_null("BoardView")
	if bv == null and get_child_count() > 0:
		# if this IS the board view
		bv = self
	# When used as root of game.tscn structure: parent GameRoot
	print("AUTO: self=", name, " children=", get_child_count())
	var board = get_node_or_null("BoardView")
	print("AUTO: board=", board)
	if board:
		if board.has_method("setup"):
			board.setup(false)
		await get_tree().create_timer(0.5).timeout
		print("AUTO: calling execute e2e4")
		board.call("_execute_move", ChessBoard.sq_of(4,1), ChessBoard.sq_of(4,3), 0)
		print("AUTO: execute returned")
		for i in 30:
			await get_tree().process_frame
			print("AUTO: frame ", i)
		print("AUTO: survived 30 frames")
	await get_tree().create_timer(1.0).timeout
	print("AUTO: quit ok")
	get_tree().quit(0)
