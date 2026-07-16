extends RefCounted
## 8x8 board state. Squares 0..63, file = i % 8, rank = i / 8 (rank 0 = white home).

const PieceCatalog = preload("res://core/piece_catalog.gd")

const EMPTY := 0
# Encode: type in low 3 bits (1-6), side in bit 3 (0 white / 1 black) → value 1-6 white, 9-14 black
# Actually use: piece = type | (side << 3) with type 1-6


static func make_piece(type: int, side: int) -> int:
	return type | (side << 3)


static func piece_type(p: int) -> int:
	return p & 7


static func piece_side(p: int) -> int:
	return (p >> 3) & 1


static func is_empty(p: int) -> bool:
	return p == EMPTY


var squares: Array = []  # 64 ints
var side_to_move: int = PieceCatalog.Side.WHITE
var castling_rights: int = 0b1111  # KQkq bits: white K, white Q, black K, black Q
var ep_square: int = -1  # en passant target square index, or -1
var halfmove_clock: int = 0
var fullmove_number: int = 1


func _init() -> void:
	squares.resize(64)
	for i in 64:
		squares[i] = EMPTY


func clear() -> void:
	for i in 64:
		squares[i] = EMPTY
	side_to_move = PieceCatalog.Side.WHITE
	castling_rights = 0b1111
	ep_square = -1
	halfmove_clock = 0
	fullmove_number = 1


func setup_start() -> void:
	clear()
	var T := PieceCatalog.Type
	var W := PieceCatalog.Side.WHITE
	var B := PieceCatalog.Side.BLACK
	# White (Xanh) rank 0-1
	var back_w := [T.ROOK, T.KNIGHT, T.BISHOP, T.QUEEN, T.KING, T.BISHOP, T.KNIGHT, T.ROOK]
	for f in 8:
		squares[f] = make_piece(back_w[f], W)
		squares[8 + f] = make_piece(T.PAWN, W)
		squares[48 + f] = make_piece(T.PAWN, B)
		squares[56 + f] = make_piece(back_w[f], B)


func get_piece(sq: int) -> int:
	if sq < 0 or sq > 63:
		return EMPTY
	return squares[sq]


func set_piece(sq: int, p: int) -> void:
	squares[sq] = p


func clone():
	var b = get_script().new()
	b.squares = squares.duplicate()
	b.side_to_move = side_to_move
	b.castling_rights = castling_rights
	b.ep_square = ep_square
	b.halfmove_clock = halfmove_clock
	b.fullmove_number = fullmove_number
	return b


static func sq_of(file: int, rank: int) -> int:
	return rank * 8 + file


static func file_of(sq: int) -> int:
	return sq % 8


static func rank_of(sq: int) -> int:
	return sq / 8


static func in_bounds(file: int, rank: int) -> bool:
	return file >= 0 and file < 8 and rank >= 0 and rank < 8


static func sq_name(sq: int) -> String:
	if sq < 0:
		return "-"
	return "%s%d" % [char(97 + file_of(sq)), rank_of(sq) + 1]


func find_king(side: int) -> int:
	var k := make_piece(PieceCatalog.Type.KING, side)
	for i in 64:
		if squares[i] == k:
			return i
	return -1
