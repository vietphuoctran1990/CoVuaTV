extends SceneTree
## Chạy: godot --headless --path . --script tests/smoke_test.gd

const ChessBoard = preload("res://core/board.gd")
const MoveGen = preload("res://core/move_gen.gd")
const GameState = preload("res://core/game_state.gd")
const PieceCatalog = preload("res://core/piece_catalog.gd")


func _init() -> void:
	print("=== Doraemon Chess smoke test ===")
	var ok := true
	ok = _test_start_moves() and ok
	ok = _test_scholars_path() and ok
	print("=== RESULT: %s ===" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)


func _test_start_moves() -> bool:
	var b := ChessBoard.new()
	b.setup_start()
	var moves: Array = MoveGen.legal_moves(b)
	print("Start legal moves: ", moves.size())
	# Standard chess: 20 moves
	if moves.size() != 20:
		print("FAIL expected 20 opening moves, got ", moves.size())
		return false
	print("OK opening moves")
	return true


func _test_scholars_path() -> bool:
	# e4 e5 Qh5 Nc6 Bc4 Nf6 Qxf7 mate
	var gs := GameState.new()
	gs.new_game(false)
	var seq := [
		[ChessBoard.sq_of(4, 1), ChessBoard.sq_of(4, 3)], # e2e4
		[ChessBoard.sq_of(4, 6), ChessBoard.sq_of(4, 4)], # e7e5
		[ChessBoard.sq_of(3, 0), ChessBoard.sq_of(7, 4)], # d1h5
		[ChessBoard.sq_of(1, 7), ChessBoard.sq_of(2, 5)], # b8c6
		[ChessBoard.sq_of(5, 0), ChessBoard.sq_of(2, 3)], # f1c4
		[ChessBoard.sq_of(6, 7), ChessBoard.sq_of(5, 5)], # g8f6
		[ChessBoard.sq_of(7, 4), ChessBoard.sq_of(5, 6)], # h5f7
	]
	for step in seq:
		var info: Dictionary = gs.try_move(step[0], step[1])
		if not info.ok:
			print("FAIL move ", ChessBoard.sq_name(step[0]), "->", ChessBoard.sq_name(step[1]))
			return false
	if gs.last_result != 1:  # Result.CHECKMATE
		print("FAIL expected checkmate after scholar pattern, got ", gs.last_result)
		return false
	print("OK scholar mate pattern")
	return true
