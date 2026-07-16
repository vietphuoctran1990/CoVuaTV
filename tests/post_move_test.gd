extends SceneTree

const ChessBoard = preload("res://core/board.gd")
const MoveGen = preload("res://core/move_gen.gd")
const GameState = preload("res://core/game_state.gd")
const PieceCatalog = preload("res://core/piece_catalog.gd")

func _init() -> void:
	print("=== post-move eval test ===")
	var gs = GameState.new()
	gs.new_game(false)
	# e2e4
	var info = gs.try_move(ChessBoard.sq_of(4, 1), ChessBoard.sq_of(4, 3))
	print("move ok=", info.ok, " check=", info.check, " result=", info.result_text, " last=", gs.last_result)
	print("side to move=", gs.board.side_to_move)
	print("black in check=", MoveGen.is_in_check(gs.board, PieceCatalog.Side.BLACK))
	print("white in check=", MoveGen.is_in_check(gs.board, PieceCatalog.Side.WHITE))
	var lm = MoveGen.legal_moves(gs.board)
	print("legal moves for side=", lm.size())
	# d2d4
	gs.new_game(false)
	info = gs.try_move(ChessBoard.sq_of(3, 1), ChessBoard.sq_of(3, 3))
	print("d4 ok=", info.ok, " result=", info.result_text, " legal after=", MoveGen.legal_moves(gs.board).size())
	# knight
	gs.new_game(false)
	info = gs.try_move(ChessBoard.sq_of(1, 0), ChessBoard.sq_of(2, 2))
	print("Nc3 ok=", info.ok, " result=", info.result_text, " legal after=", MoveGen.legal_moves(gs.board).size())
	# full opening both sides a few moves
	gs.new_game(false)
	var seq = [
		[ChessBoard.sq_of(4,1), ChessBoard.sq_of(4,3)],
		[ChessBoard.sq_of(4,6), ChessBoard.sq_of(4,4)],
		[ChessBoard.sq_of(6,0), ChessBoard.sq_of(5,2)],
		[ChessBoard.sq_of(1,7), ChessBoard.sq_of(2,5)],
	]
	for s in seq:
		info = gs.try_move(s[0], s[1])
		print("step ", ChessBoard.sq_name(s[0]), "->", ChessBoard.sq_name(s[1]), " ok=", info.ok, " res=", info.result_text, " last=", gs.last_result, " legal=", MoveGen.legal_moves(gs.board).size())
		if not info.ok:
			break
	quit(0)
