extends RefCounted
## Load & cache piece textures (blue/orange teams).

const PieceCatalog = preload("res://core/piece_catalog.gd")

const FILES := {
	PieceCatalog.Type.KING: "king_doraemon.png",
	PieceCatalog.Type.QUEEN: "queen_xuka.png",
	PieceCatalog.Type.ROOK: "rook_chaien.png",
	PieceCatalog.Type.BISHOP: "bishop_xeko.png",
	PieceCatalog.Type.KNIGHT: "knight_nobita.png",
	PieceCatalog.Type.PAWN: "pawn_minidora.png",
}

static var _cache: Dictionary = {}  # "side_type" -> Texture2D


static func get_texture(piece_type: int, side: int) -> Texture2D:
	var key := "%d_%d" % [side, piece_type]
	if _cache.has(key):
		return _cache[key]
	var folder := "blue" if side == PieceCatalog.Side.WHITE else "orange"
	var fname: String = FILES.get(piece_type, "")
	if fname == "":
		return null
	var path := "res://assets/pieces/%s/%s" % [folder, fname]
	if not ResourceLoader.exists(path):
		push_warning("Missing piece texture: " + path)
		return null
	var tex: Texture2D = load(path)
	_cache[key] = tex
	return tex


static func clear_cache() -> void:
	_cache.clear()
