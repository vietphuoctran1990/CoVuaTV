extends RefCounted
## Sinh nước đi hợp lệ (legal) — lọc chiếu vua.

const ChessBoard = preload("res://core/board.gd")
const ChessMove = preload("res://core/move.gd")
const PieceCatalog = preload("res://core/piece_catalog.gd")

const KNIGHT_DELTAS := [Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, -1), Vector2i(1, -2),
	Vector2i(-1, -2), Vector2i(-2, -1), Vector2i(-2, 1), Vector2i(-1, 2)]
const KING_DELTAS := [Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1),
	Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1)]
const BISHOP_DIRS := [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
const ROOK_DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]


static func legal_moves(board) -> Array:
	var result: Array = []
	var side: int = board.side_to_move
	for sq in 64:
		var p: int = board.squares[sq]
		if ChessBoard.is_empty(p) or ChessBoard.piece_side(p) != side:
			continue
		var pseudo: Array = _pseudo_moves_from(board, sq)
		for m in pseudo:
			if _is_legal(board, m):
				result.append(m)
	return result


static func legal_moves_from(board, from_sq: int) -> Array:
	var result: Array = []
	var p: int = board.get_piece(from_sq)
	if ChessBoard.is_empty(p) or ChessBoard.piece_side(p) != board.side_to_move:
		return result
	for m in _pseudo_moves_from(board, from_sq):
		if _is_legal(board, m):
			result.append(m)
	return result


static func is_in_check(board, side: int) -> bool:
	var ksq: int = board.find_king(side)
	if ksq < 0:
		return true
	return is_square_attacked(board, ksq, 1 - side)


static func is_square_attacked(board, sq: int, by_side: int) -> bool:
	var tf: int = ChessBoard.file_of(sq)
	var tr: int = ChessBoard.rank_of(sq)
	# Knights
	for d in KNIGHT_DELTAS:
		var f: int = tf + d.x
		var r: int = tr + d.y
		if not ChessBoard.in_bounds(f, r):
			continue
		var p: int = board.get_piece(ChessBoard.sq_of(f, r))
		if not ChessBoard.is_empty(p) and ChessBoard.piece_side(p) == by_side \
				and ChessBoard.piece_type(p) == PieceCatalog.Type.KNIGHT:
			return true
	# King
	for d in KING_DELTAS:
		var f2: int = tf + d.x
		var r2: int = tr + d.y
		if not ChessBoard.in_bounds(f2, r2):
			continue
		var p2: int = board.get_piece(ChessBoard.sq_of(f2, r2))
		if not ChessBoard.is_empty(p2) and ChessBoard.piece_side(p2) == by_side \
				and ChessBoard.piece_type(p2) == PieceCatalog.Type.KING:
			return true
	# Pawns
	var pawn_dir: int = 1 if by_side == PieceCatalog.Side.WHITE else -1
	for df in [-1, 1]:
		var pf: int = tf + df
		var pr: int = tr - pawn_dir  # square pawn would attack FROM
		if not ChessBoard.in_bounds(pf, pr):
			continue
		var pp: int = board.get_piece(ChessBoard.sq_of(pf, pr))
		if not ChessBoard.is_empty(pp) and ChessBoard.piece_side(pp) == by_side \
				and ChessBoard.piece_type(pp) == PieceCatalog.Type.PAWN:
			return true
	# Sliding
	if _slider_attacks(board, sq, by_side, BISHOP_DIRS, [PieceCatalog.Type.BISHOP, PieceCatalog.Type.QUEEN]):
		return true
	if _slider_attacks(board, sq, by_side, ROOK_DIRS, [PieceCatalog.Type.ROOK, PieceCatalog.Type.QUEEN]):
		return true
	return false


static func _slider_attacks(board, sq: int, by_side: int, dirs: Array, types: Array) -> bool:
	var tf: int = ChessBoard.file_of(sq)
	var tr: int = ChessBoard.rank_of(sq)
	for d in dirs:
		var f: int = tf + d.x
		var r: int = tr + d.y
		while ChessBoard.in_bounds(f, r):
			var p: int = board.get_piece(ChessBoard.sq_of(f, r))
			if not ChessBoard.is_empty(p):
				if ChessBoard.piece_side(p) == by_side and ChessBoard.piece_type(p) in types:
					return true
				break
			f += d.x
			r += d.y
	return false


static func _is_legal(board, move) -> bool:
	var b2 = board.clone()
	_apply_raw(b2, move)
	return not is_in_check(b2, board.side_to_move)


static func apply_move(board, move) -> void:
	move.prev_castling = board.castling_rights
	move.prev_ep = board.ep_square
	move.prev_halfmove = board.halfmove_clock
	var moving: int = board.get_piece(move.from_sq)
	var mtype: int = ChessBoard.piece_type(moving)
	if move.is_en_passant:
		move.captured = board.get_piece(ChessBoard.sq_of(ChessBoard.file_of(move.to_sq), ChessBoard.rank_of(move.from_sq)))
	else:
		move.captured = board.get_piece(move.to_sq)
	_apply_raw(board, move)
	# clocks
	if mtype == PieceCatalog.Type.PAWN or move.captured != 0:
		board.halfmove_clock = 0
	else:
		board.halfmove_clock += 1
	if board.side_to_move == PieceCatalog.Side.BLACK:
		board.fullmove_number += 1
	board.side_to_move = 1 - board.side_to_move


static func undo_move(board, move) -> void:
	board.side_to_move = 1 - board.side_to_move
	if board.side_to_move == PieceCatalog.Side.BLACK:
		board.fullmove_number = max(1, board.fullmove_number - 1)
	board.castling_rights = move.prev_castling
	board.ep_square = move.prev_ep
	board.halfmove_clock = move.prev_halfmove

	var moving: int = board.get_piece(move.to_sq)
	# Undo promotion
	if move.promotion != 0:
		moving = ChessBoard.make_piece(PieceCatalog.Type.PAWN, ChessBoard.piece_side(moving))

	board.set_piece(move.from_sq, moving)
	board.set_piece(move.to_sq, ChessBoard.EMPTY)

	if move.is_castle:
		var rf: int = ChessBoard.file_of(move.to_sq)
		var rank: int = ChessBoard.rank_of(move.from_sq)
		if rf == 6:  # king side
			board.set_piece(ChessBoard.sq_of(5, rank), ChessBoard.EMPTY)
			board.set_piece(ChessBoard.sq_of(7, rank), ChessBoard.make_piece(PieceCatalog.Type.ROOK, board.side_to_move))
		elif rf == 2:  # queen side
			board.set_piece(ChessBoard.sq_of(3, rank), ChessBoard.EMPTY)
			board.set_piece(ChessBoard.sq_of(0, rank), ChessBoard.make_piece(PieceCatalog.Type.ROOK, board.side_to_move))
	elif move.is_en_passant:
		var cap_sq: int = ChessBoard.sq_of(ChessBoard.file_of(move.to_sq), ChessBoard.rank_of(move.from_sq))
		board.set_piece(cap_sq, move.captured)
	elif move.captured != 0:
		board.set_piece(move.to_sq, move.captured)


static func _apply_raw(board, move) -> void:
	var moving: int = board.get_piece(move.from_sq)
	var side: int = ChessBoard.piece_side(moving)
	var mtype: int = ChessBoard.piece_type(moving)

	board.set_piece(move.from_sq, ChessBoard.EMPTY)

	if move.is_en_passant:
		var cap_sq: int = ChessBoard.sq_of(ChessBoard.file_of(move.to_sq), ChessBoard.rank_of(move.from_sq))
		board.set_piece(cap_sq, ChessBoard.EMPTY)

	if move.is_castle:
		var rank: int = ChessBoard.rank_of(move.from_sq)
		if ChessBoard.file_of(move.to_sq) == 6:
			board.set_piece(ChessBoard.sq_of(7, rank), ChessBoard.EMPTY)
			board.set_piece(ChessBoard.sq_of(5, rank), ChessBoard.make_piece(PieceCatalog.Type.ROOK, side))
		else:
			board.set_piece(ChessBoard.sq_of(0, rank), ChessBoard.EMPTY)
			board.set_piece(ChessBoard.sq_of(3, rank), ChessBoard.make_piece(PieceCatalog.Type.ROOK, side))

	var place: int = moving
	if move.promotion != 0:
		place = ChessBoard.make_piece(move.promotion, side)
	board.set_piece(move.to_sq, place)

	# EP target
	board.ep_square = -1
	if mtype == PieceCatalog.Type.PAWN and absi(ChessBoard.rank_of(move.to_sq) - ChessBoard.rank_of(move.from_sq)) == 2:
		var mid_rank: int = int((ChessBoard.rank_of(move.from_sq) + ChessBoard.rank_of(move.to_sq)) / 2)
		board.ep_square = ChessBoard.sq_of(ChessBoard.file_of(move.from_sq), mid_rank)


	# Castling rights
	_update_castling_rights(board, move, moving)


static func _update_castling_rights(board, move, moving: int) -> void:
	var rights: int = board.castling_rights
	var mtype: int = ChessBoard.piece_type(moving)
	var side: int = ChessBoard.piece_side(moving)
	if mtype == PieceCatalog.Type.KING:
		if side == PieceCatalog.Side.WHITE:
			rights &= ~0b0011
		else:
			rights &= ~0b1100
	if mtype == PieceCatalog.Type.ROOK:
		if move.from_sq == 0:
			rights &= ~0b0010
		elif move.from_sq == 7:
			rights &= ~0b0001
		elif move.from_sq == 56:
			rights &= ~0b1000
		elif move.from_sq == 63:
			rights &= ~0b0100
	# Captured rook on corner
	if move.to_sq == 0:
		rights &= ~0b0010
	elif move.to_sq == 7:
		rights &= ~0b0001
	elif move.to_sq == 56:
		rights &= ~0b1000
	elif move.to_sq == 63:
		rights &= ~0b0100
	board.castling_rights = rights


static func _pseudo_moves_from(board, from_sq: int) -> Array:
	var p: int = board.get_piece(from_sq)
	var t: int = ChessBoard.piece_type(p)
	match t:
		PieceCatalog.Type.PAWN:
			return _pawn_moves(board, from_sq)
		PieceCatalog.Type.KNIGHT:
			return _delta_moves(board, from_sq, KNIGHT_DELTAS, false)
		PieceCatalog.Type.BISHOP:
			return _slide_moves(board, from_sq, BISHOP_DIRS)
		PieceCatalog.Type.ROOK:
			return _slide_moves(board, from_sq, ROOK_DIRS)
		PieceCatalog.Type.QUEEN:
			return _slide_moves(board, from_sq, BISHOP_DIRS + ROOK_DIRS)
		PieceCatalog.Type.KING:
			var moves: Array = _delta_moves(board, from_sq, KING_DELTAS, false)
			moves.append_array(_castle_moves(board, from_sq))
			return moves
	return []


static func _pawn_moves(board, from_sq: int) -> Array:
	var moves: Array = []
	var p: int = board.get_piece(from_sq)
	var side: int = ChessBoard.piece_side(p)
	var f: int = ChessBoard.file_of(from_sq)
	var r: int = ChessBoard.rank_of(from_sq)
	var dir: int = 1 if side == PieceCatalog.Side.WHITE else -1
	var start_rank: int = 1 if side == PieceCatalog.Side.WHITE else 6
	var promo_rank: int = 7 if side == PieceCatalog.Side.WHITE else 0

	# Forward
	var r1: int = r + dir
	if ChessBoard.in_bounds(f, r1) and ChessBoard.is_empty(board.get_piece(ChessBoard.sq_of(f, r1))):
		_add_pawn_to(moves, from_sq, ChessBoard.sq_of(f, r1), r1 == promo_rank)
		if r == start_rank:
			var r2: int = r + 2 * dir
			if ChessBoard.is_empty(board.get_piece(ChessBoard.sq_of(f, r2))):
				_add_pawn_to(moves, from_sq, ChessBoard.sq_of(f, r2), false)

	# Captures
	for df in [-1, 1]:
		var cf: int = f + df
		var cr: int = r + dir
		if not ChessBoard.in_bounds(cf, cr):
			continue
		var to: int = ChessBoard.sq_of(cf, cr)
		var target: int = board.get_piece(to)
		if not ChessBoard.is_empty(target) and ChessBoard.piece_side(target) != side:
			_add_pawn_to(moves, from_sq, to, cr == promo_rank)
		elif to == board.ep_square:
			var m = ChessMove.new(from_sq, to)
			m.is_en_passant = true
			moves.append(m)
	return moves


static func _add_pawn_to(moves: Array, from_sq: int, to_sq: int, promo: bool) -> void:
	if promo:
		for pt in [PieceCatalog.Type.QUEEN, PieceCatalog.Type.ROOK, PieceCatalog.Type.BISHOP, PieceCatalog.Type.KNIGHT]:
			var m = ChessMove.new(from_sq, to_sq)
			m.promotion = pt
			moves.append(m)
	else:
		moves.append(ChessMove.new(from_sq, to_sq))


static func _delta_moves(board, from_sq: int, deltas: Array, _unused: bool) -> Array:
	var moves: Array = []
	var side: int = ChessBoard.piece_side(board.get_piece(from_sq))
	var f0: int = ChessBoard.file_of(from_sq)
	var r0: int = ChessBoard.rank_of(from_sq)
	for d in deltas:
		var f: int = f0 + d.x
		var r: int = r0 + d.y
		if not ChessBoard.in_bounds(f, r):
			continue
		var to: int = ChessBoard.sq_of(f, r)
		var t: int = board.get_piece(to)
		if ChessBoard.is_empty(t) or ChessBoard.piece_side(t) != side:
			moves.append(ChessMove.new(from_sq, to))
	return moves


static func _slide_moves(board, from_sq: int, dirs: Array) -> Array:
	var moves: Array = []
	var side: int = ChessBoard.piece_side(board.get_piece(from_sq))
	var f0: int = ChessBoard.file_of(from_sq)
	var r0: int = ChessBoard.rank_of(from_sq)
	for d in dirs:
		var f: int = f0 + d.x
		var r: int = r0 + d.y
		while ChessBoard.in_bounds(f, r):
			var to: int = ChessBoard.sq_of(f, r)
			var t: int = board.get_piece(to)
			if ChessBoard.is_empty(t):
				moves.append(ChessMove.new(from_sq, to))
			else:
				if ChessBoard.piece_side(t) != side:
					moves.append(ChessMove.new(from_sq, to))
				break
			f += d.x
			r += d.y
	return moves


static func _castle_moves(board, from_sq: int) -> Array:
	var moves: Array = []
	var side: int = ChessBoard.piece_side(board.get_piece(from_sq))
	var rank: int = 0 if side == PieceCatalog.Side.WHITE else 7
	if ChessBoard.rank_of(from_sq) != rank or ChessBoard.file_of(from_sq) != 4:
		return moves
	if is_in_check(board, side):
		return moves
	var enemy: int = 1 - side
	# King side
	var ks_bit: int = 0b0001 if side == PieceCatalog.Side.WHITE else 0b0100
	if board.castling_rights & ks_bit:
		if ChessBoard.is_empty(board.get_piece(ChessBoard.sq_of(5, rank))) \
				and ChessBoard.is_empty(board.get_piece(ChessBoard.sq_of(6, rank))):
			if not is_square_attacked(board, ChessBoard.sq_of(5, rank), enemy) \
					and not is_square_attacked(board, ChessBoard.sq_of(6, rank), enemy):
				var m = ChessMove.new(from_sq, ChessBoard.sq_of(6, rank))
				m.is_castle = true
				moves.append(m)
	# Queen side
	var qs_bit: int = 0b0010 if side == PieceCatalog.Side.WHITE else 0b1000
	if board.castling_rights & qs_bit:
		if ChessBoard.is_empty(board.get_piece(ChessBoard.sq_of(1, rank))) \
				and ChessBoard.is_empty(board.get_piece(ChessBoard.sq_of(2, rank))) \
				and ChessBoard.is_empty(board.get_piece(ChessBoard.sq_of(3, rank))):
			if not is_square_attacked(board, ChessBoard.sq_of(3, rank), enemy) \
					and not is_square_attacked(board, ChessBoard.sq_of(2, rank), enemy):
				var m2 = ChessMove.new(from_sq, ChessBoard.sq_of(2, rank))
				m2.is_castle = true
				moves.append(m2)
	return moves
