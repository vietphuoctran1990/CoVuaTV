extends RefCounted
## Map loại quân cờ ↔ nhân vật Doraemon (cách điệu) cho HUD và placeholder art.

enum Type { NONE = 0, PAWN = 1, KNIGHT = 2, BISHOP = 3, ROOK = 4, QUEEN = 5, KING = 6 }
enum Side { WHITE = 0, BLACK = 1 }  # WHITE = phe Xanh, BLACK = phe Cam

const TYPE_NAMES := {
	Type.PAWN: "Tốt",
	Type.KNIGHT: "Mã",
	Type.BISHOP: "Tượng",
	Type.ROOK: "Xe",
	Type.QUEEN: "Hậu",
	Type.KING: "Vua",
}

const CHAR_NAMES := {
	Type.PAWN: "Mini-Dora",
	Type.KNIGHT: "Nobita",
	Type.BISHOP: "Xeko",
	Type.ROOK: "Chaien",
	Type.QUEEN: "Xuka",
	Type.KING: "Doraemon",
}

const HINTS := {
	Type.PAWN: "Đi tới 1 ô, ăn chéo. Lượt đầu có thể 2 ô.",
	Type.KNIGHT: "Nobita nhảy chữ L — bay qua quân khác được!",
	Type.BISHOP: "Xeko đi chéo bao xa tùy thích.",
	Type.ROOK: "Chaien đi ngang hoặc dọc thật mạnh.",
	Type.QUEEN: "Xuka đi mọi hướng — quân mạnh nhất!",
	Type.KING: "Doraemon đi 1 ô mọi hướng. Phải bảo vệ!",
}

const BADGES := {
	Type.PAWN: "●",
	Type.KNIGHT: "M",
	Type.BISHOP: "T",
	Type.ROOK: "X",
	Type.QUEEN: "H",
	Type.KING: "V",
}

## Màu nền placeholder (phe Xanh = logic trắng, phe Cam = logic đen)
const SIDE_FILL := {
	Side.WHITE: Color("4FC3F7"),  # xanh dương Doraemon
	Side.BLACK: Color("FF8A65"),  # cam ấm
}

const SIDE_BORDER := {
	Side.WHITE: Color("0277BD"),
	Side.BLACK: Color("BF360C"),
}

const SIDE_LABEL := {
	Side.WHITE: "Phe Xanh",
	Side.BLACK: "Phe Cam",
}


static func char_name(t: int) -> String:
	return CHAR_NAMES.get(t, "?")


static func role_name(t: int) -> String:
	return TYPE_NAMES.get(t, "?")


static func display_name(t: int) -> String:
	return "%s (%s)" % [char_name(t), role_name(t)]


static func hint(t: int) -> String:
	return HINTS.get(t, "")


static func badge(t: int) -> String:
	return BADGES.get(t, "?")


static func side_name(side: int) -> String:
	return SIDE_LABEL.get(side, "?")


static func fill_color(side: int) -> Color:
	return SIDE_FILL.get(side, Color.WHITE)


static func border_color(side: int) -> Color:
	return SIDE_BORDER.get(side, Color.BLACK)


## Encyclopedia entries for character intro screen
static func all_entries() -> Array:
	return [
		{"type": Type.KING, "extra": "Thủ lĩnh đội — khi Doraemon bị chiếu hết, đội thua."},
		{"type": Type.QUEEN, "extra": "Bạn thân dịu dàng nhưng trên bàn cờ rất mạnh."},
		{"type": Type.ROOK, "extra": "Khỏe như Chaien — lao thẳng hàng ngang dọc."},
		{"type": Type.BISHOP, "extra": "Xeko khéo léo đi chéo khắp bàn."},
		{"type": Type.KNIGHT, "extra": "Nobita có bảo bối — nhảy chữ L bất ngờ!"},
		{"type": Type.PAWN, "extra": "Các Mini-Dora tiến lên. Tới cuối bàn có thể hóa Xuka!"},
	]
