extends RefCounted
## Một nước đi (kể cả nhập thành, en passant, phong cấp).

var from_sq: int = 0
var to_sq: int = 0
var promotion: int = 0  # PieceCatalog.Type or 0
var is_castle: bool = false
var is_en_passant: bool = false
var captured: int = 0  # piece code before move (0 if none)
var prev_castling: int = 0
var prev_ep: int = -1
var prev_halfmove: int = 0


func _init(from: int = 0, to: int = 0) -> void:
	from_sq = from
	to_sq = to


func duplicate_move():
	var m = get_script().new(from_sq, to_sq)
	m.promotion = promotion
	m.is_castle = is_castle
	m.is_en_passant = is_en_passant
	m.captured = captured
	m.prev_castling = prev_castling
	m.prev_ep = prev_ep
	m.prev_halfmove = prev_halfmove
	return m


func equals(other) -> bool:
	return from_sq == other.from_sq and to_sq == other.to_sq and promotion == other.promotion
