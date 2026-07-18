# Thay hình nhân vật (gần “nguyên mẫu” hơn)

## Vì sao app không kèm ảnh chính thức?

**Doraemon, Nobita, Xuka (Shizuka), Chaien (Gian), Xeko (Suneo), Mini-Dora** thuộc bản quyền **Fujiko Pro / nhà phát hành**.  
Không được tải ảnh từ phim, truyện, web hay AI “copy y hệt” rồi đóng gói vào APK (kể cả chơi nhà, vẫn là phân phối tác phẩm).

| Được | Không được |
|------|------------|
| Ảnh **bạn tự có quyền** dùng riêng (ví dụ file gia đình được phép, asset mua có license) | Ảnh official / scan truyện / cắt frame phim / tải từ Google |
| Art **gốc** chibi cách điệu (bản hiện tại trong repo) | Claim “hình chính thức Doraemon” |
| Chơi **nội bộ gia đình** với pack bạn tự thay | Đưa APK + art official lên mạng / bán |

Mục tiêu của bé “không lệch hình kinh điển” → **bạn cung cấp ảnh đúng**, app chỉ **nhận file** theo đúng tên.

## Map nhân vật → file

Đặt PNG **nền trong suốt**, khuyến nghị **256×256** (hoặc lớn hơn, vuông):

| Nhân vật | Quân cờ | Phe Xanh | Phe Cam |
|----------|---------|----------|---------|
| Doraemon | Vua | `blue/king_doraemon.png` | `orange/king_doraemon.png` |
| Xuka | Hậu | `blue/queen_xuka.png` | `orange/queen_xuka.png` |
| Chaien | Xe | `blue/rook_chaien.png` | `orange/rook_chaien.png` |
| Xeko | Tượng | `blue/bishop_xeko.png` | `orange/bishop_xeko.png` |
| Nobita | Mã | `blue/knight_nobita.png` | `orange/knight_nobita.png` |
| Mini-Dora | Tốt | `blue/pawn_minidora.png` | `orange/pawn_minidora.png` |

- **Phe Xanh / Cam**: có thể dùng **cùng một ảnh** 2 phe, hoặc tô viền khác màu để bé phân biệt đội.  
- Thư mục drop: `web/pieces/_import/` (xem README trong đó).

## Cách làm nhanh (máy nhà)

### 1) Chuẩn bị 12 file (hoặc 6 file dùng chung 2 phe)

Đặt vào:

```
web/pieces/_import/blue/king_doraemon.png
web/pieces/_import/blue/queen_xuka.png
... (đủ 6)
web/pieces/_import/orange/king_doraemon.png
... (đủ 6)
```

Nếu chỉ có 1 bộ 6 ảnh: copy sang cả `blue/` và `orange/` trong `_import`.

### 2) Chạy script import

```bash
cd CoVuaTV
python3 tools/import_character_pack.py
```

Script sẽ:

- Resize/căn giữa → 256×256 PNG  
- Copy vào `web/pieces/blue|orange/` và `android-webview/.../assets/www/pieces/`  
- Giữ tên file game đang dùng (không phải sửa code)

### 3) Build APK WebView

Actions → **Build Android APK (WebView)** → cài lại TV  
(hoặc nhờ Grok build sau khi bạn đã drop file).

## Gợi ý nguồn ảnh hợp lệ

1. **Tự vẽ / thuê vẽ** gần phong cách kinh điển (vẫn là art gốc).  
2. **Asset có license** cho phép dùng trong app gia đình (nếu mua được).  
3. **Không** nhờ AI/agent tải ảnh official từ internet.

## Làm việc với Grok / Claude

Sau khi bạn **tự chép** ảnh vào `web/pieces/_import/`, nhắn:

> “Import pack nhân vật trong `_import` và build APK”

Không gửi link “tải Doraemon official” — sẽ bị từ chối vì bản quyền.
