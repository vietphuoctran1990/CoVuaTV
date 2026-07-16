extends RefCounted
## AI rất dễ / vừa cho bé 7 tuổi — minimax nông + random trong top moves.

const ChessBoard = preload("res://core/board.gd")
const ChessMove = preload("res://core/move.gd")
const MoveGen = preload("res://core/move_gen.gd")
const PieceCatalog = preload("res://core/piece_catalog.gd")

const VAL := {
	PieceCatalog.Type.PAWN: 100,
	PieceCatalog.Type.KNIGHT: 320,
	PieceCatalog.Type.BISHOP: 330,
	PieceCatalog.Type.ROOK: 500,
	PieceCatalog.Type.QUEEN: 900,
	PieceCatalog.Type.KING: 20000,
}


static func choose_move(board, depth: int = 1):
	var moves: Array = MoveGen.legal_moves(board)
	if moves.is_empty():
		return null
	var side: int = board.side_to_move
	var scored: Array = []
	for m in moves:
		var b2 = board.clone()
		var mm = m.duplicate_move()
		MoveGen.apply_move(b2, mm)
		var s: int = -_negamax(b2, depth - 1, -999999, 999999, 1 - side, side)
		# Noise so AI is imperfect and fun
		s += randi_range(-30, 30)
		scored.append({"m": m, "s": s})
	scored.sort_custom(func(a, b): return a.s > b.s)
	# Pick randomly among top 3
	var top_n: int = mini(3, scored.size())
	return scored[randi() % top_n].m


static func _negamax(board, depth: int, alpha: int, beta: int, side: int, root_side: int) -> int:
	if depth <= 0:
		return _eval(board, root_side)
	var moves: Array = MoveGen.legal_moves(board)
	if moves.is_empty():
		if MoveGen.is_in_check(board, board.side_to_move):
			return -100000 + (3 - depth)  # mate
		return 0  # stalemate
	var best: int = -999999
	for m in moves:
		var b2 = board.clone()
		MoveGen.apply_move(b2, m.duplicate_move())
		var s: int = -_negamax(b2, depth - 1, -beta, -alpha, 1 - side, root_side)
		if s > best:
			best = s
		if best > alpha:
			alpha = best
		if alpha >= beta:
			break
	return best


static func _eval(board, for_side: int) -> int:
	var score: int = 0
	for i in 64:
		var p: int = board.squares[i]
		if ChessBoard.is_empty(p):
			continue
		var v: int = VAL.get(ChessBoard.piece_type(p), 0)
		if ChessBoard.piece_side(p) == for_side:
			score += v
		else:
			score -= v
	return score
