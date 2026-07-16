extends Control
## 5 bước học chơi cho bé 7 tuổi — điều khiển remote.

const PieceCatalog = preload("res://core/piece_catalog.gd")
const PieceSprites = preload("res://core/piece_sprites.gd")

var step: int = 0

const STEPS := [
	{
		"title": "Bước 1/5 — Chào mừng!",
		"body": "Xin chào! Đây là cờ vua cùng Doraemon và bạn bè.\nBố mẹ và bé ngồi sofa, cầm remote TV.\n\n• Mũi tên ↑↓←→ : di chuyển\n• Nút OK : chọn\n• Nút Back : quay lại\n\nNhấn OK để tiếp tục nhé!",
		"type": PieceCatalog.Type.KING,
	},
	{
		"title": "Bước 2/5 — Hai đội",
		"body": "Có 2 đội trên bàn cờ:\n\n• Phe Xanh — đi trước\n• Phe Cam — đi sau\n\nMỗi đội có một Doraemon (Vua).\nBảo vệ Doraemon của mình — nếu bị chiếu hết là thua!",
		"type": PieceCatalog.Type.KING,
	},
	{
		"title": "Bước 3/5 — Bạn bè là quân cờ",
		"body": "• Doraemon = Vua (đi 1 ô)\n• Xuka = Hậu (đi xa mọi hướng)\n• Chaien = Xe (ngang / dọc)\n• Xeko = Tượng (chéo)\n• Nobita = Mã (nhảy chữ L)\n• Mini-Dora = Tốt (đi tới, ăn chéo)\n\nNhìn hình và nhớ bạn nào làm gì!",
		"type": PieceCatalog.Type.QUEEN,
	},
	{
		"title": "Bước 4/5 — Cách đi một nước",
		"body": "1) Đưa khung vàng tới quân của mình\n2) Nhấn OK — ô xanh = đi được, ô cam = ăn được\n3) Đưa khung tới ô đích → OK\n\nGợi ý: phím H (Dorami giúp)\nHoàn tác: phím U (nếu bật trong Cài đặt)\n\nKhông vội — không có đồng hồ đếm!",
		"type": PieceCatalog.Type.KNIGHT,
	},
	{
		"title": "Bước 5/5 — Ăn quân & thắng",
		"body": "• Ăn quân: đi vào ô có quân đối phương\n• Chiếu: Doraemon đối phương đang bị đe dọa (❗)\n• Chiếu hết: đối phương không cứu được → bạn thắng!\n\nMini-Dora tới cuối bàn có thể hóa Xuka.\n\nSẵn sàng chưa? OK để về menu và chơi thật!",
		"type": PieceCatalog.Type.PAWN,
	},
]


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	set_process_input(true)
	if DisplayServer.has_method("window_set_ime_active"):
		DisplayServer.window_set_ime_active(false)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var k := event as InputEventKey
	if not k.pressed or k.echo:
		return
	var code: int = k.physical_keycode if k.physical_keycode != 0 else k.keycode
	if code == KEY_RIGHT or code == KEY_ENTER or code == KEY_KP_ENTER or code == KEY_SPACE:
		_next()
	elif code == KEY_LEFT:
		_prev()
	elif code == KEY_ESCAPE:
		_back_menu()
	else:
		return
	var vp := get_viewport()
	if vp:
		vp.set_input_as_handled()


func _next() -> void:
	AudioMgr.play(AudioMgr.Sfx.CLICK)
	if step >= STEPS.size() - 1:
		_back_menu()
		return
	step += 1
	queue_redraw()


func _prev() -> void:
	AudioMgr.play(AudioMgr.Sfx.CLICK)
	step = maxi(0, step - 1)
	queue_redraw()


func _back_menu() -> void:
	AudioMgr.play(AudioMgr.Sfx.CLICK)
	GameBus.go_menu()


func _draw() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), Color("0D47A1"))
	draw_circle(Vector2(160, 140), 90, Color(0.16, 0.71, 0.96, 0.2))
	draw_circle(Vector2(size.x - 140, size.y - 120), 120, Color(1.0, 0.54, 0.4, 0.15))

	var data: Dictionary = STEPS[step]
	var font := ThemeDB.fallback_font

	draw_string(font, Vector2(100, 80), "HỌC CHƠI CÙNG DORAMI", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color("FFF59D"))
	draw_string(font, Vector2(100, 130), str(data.title), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color.WHITE)

	# Card
	var card := Rect2(100, 170, size.x - 200, size.y - 320)
	draw_rect(card, Color("1565C0"))
	draw_rect(card, Color("FFD54F"), false, 4.0)

	# Big character portrait
	var tex: Texture2D = PieceSprites.get_texture(data.type, PieceCatalog.Side.WHITE)
	var portrait := Rect2(card.position.x + 40, card.position.y + 40, 280, 280)
	draw_rect(portrait, Color(0.05, 0.1, 0.25, 0.5))
	if tex:
		draw_texture_rect(tex, portrait.grow(-10), false)
	else:
		draw_circle(portrait.get_center(), 100, PieceCatalog.fill_color(PieceCatalog.Side.WHITE))

	var name: String = PieceCatalog.display_name(data.type)
	draw_string(font, Vector2(portrait.position.x + 20, portrait.end.y + 36), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("E1F5FE"))

	# Body text — simple line split
	var body: String = str(data.body)
	var lines: PackedStringArray = body.split("\n")
	var ty: float = card.position.y + 50
	var tx: float = card.position.x + 360
	for line in lines:
		draw_string(font, Vector2(tx, ty), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color.WHITE)
		ty += 34

	# Progress dots
	var dx: float = size.x * 0.5 - (STEPS.size() - 1) * 20
	for i in STEPS.size():
		var c := Color("FFEB3B") if i == step else Color(1, 1, 1, 0.35)
		draw_circle(Vector2(dx + i * 40, size.y - 90), 10, c)

	draw_string(font, Vector2(100, size.y - 50), "← bước trước   ·   OK / → bước sau   ·   Back về menu", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.75))
