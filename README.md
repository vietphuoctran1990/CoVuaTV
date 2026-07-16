# Cờ Vua Doraemon TV

Game cờ vua gia đình (bố mẹ + bé 7 tuổi) cho **PC / TV browser / Android TV**.  
Quân cờ hình tượng Doraemon, Xuka, Chaien, Xeko, Nobita, Mini-Dora (art cách điệu).

## Chơi ngay (ổn định — khuyến nghị)

```
Choi-Game.bat  →  1
```

hoặc mở **`web/index.html`**

| Phím | Chức năng |
|------|-----------|
| ↑ ↓ ← → | Di chuyển (giữ để đi nhanh) |
| Enter / OK | Chọn / đi |
| Esc / Back | Bỏ chọn · menu tạm dừng (gợi ý, hoàn tác, âm thanh, chơi lại) |
| H / U | Gợi ý / hoàn tác (phím tắt bàn phím) |

Cũng hỗ trợ **click/chạm**. PWA + fullscreen: `Choi-Game.bat` → **2**.  
Chi tiết: **[docs/WEB_TV.md](docs/WEB_TV.md)**

## Map quân cờ

| Quân | Nhân vật | Phe |
|------|----------|-----|
| Vua | Doraemon | Xanh / Cam |
| Hậu | Xuka | Xanh / Cam |
| Xe | Chaien | Xanh / Cam |
| Tượng | Xeko | Xanh / Cam |
| Mã | Nobita | Xanh / Cam |
| Tốt | Mini-Dora | Xanh / Cam |

## Build APK Android TV (không cần SDK máy cty)

Workflow GitHub: **Build Android APK (WebView)** — bọc `web/` trong WebView + Leanback TV.

1. Push repo (máy nhà nếu cty chặn GitHub)  
2. Actions → **Build Android APK (WebView)** → Run  
3. Tải artifact `doraemon-chess-tv-apk`  
4. Sideload Xiaomi TV  

```bash
adb connect <IP_TV>:5555
adb install -r app-debug.apk
```

Chi tiết: **[docs/WEB_TV.md](docs/WEB_TV.md)** · **[docs/GITHUB_BUILD.md](docs/GITHUB_BUILD.md)**

Tóm tắt:

1. Push repo lên GitHub (hoặc zip → máy khác → push)
2. Actions → **Build Android APK** → **Run workflow**
3. Tải artifact `doraemon-chess-tv-apk` → `DoraemonChessTV.apk`
4. Cài lên Xiaomi TV (USB / ADB, bật Unknown sources)

```bash
adb connect <IP_TV>:5555
adb install -r DoraemonChessTV.apk
```

### Export tay trên PC (tuỳ chọn)

Cần Godot 4.7 + Android SDK + export templates. Dùng preset `Android` trong `export_presets.cfg`.

## Tính năng MVP

- [x] Luật cờ: đi quân, ăn, nhập thành, en passant, phong cấp, chiếu / hết / hòa (kèm luật 50 nước, hòa thiếu quân)
- [x] 2 người cùng TV + chơi với máy (**3 mức độ: Dễ / Vừa / Khó**)
- [x] Remote: chọn 2 bước, menu tạm dừng (Back/Esc) với gợi ý, hoàn tác, âm thanh
- [x] HUD tiếng Việt, map nhân vật, toast “ăn quân / chiếu”, highlight nước vừa đi, tọa độ a–h/1–8
- [x] Animation quân trượt, hiệu ứng ăn quân, confetti toàn màn hình khi thắng
- [x] Menu, cài đặt, giới thiệu nhân vật
- [x] Sprite chibi 6 nhân vật × 2 phe (`assets/pieces/blue|orange`)
- [x] SFX + BGM trên cả bản web/TV (`web/audio/*.wav`) — bật/tắt trong menu & tạm dừng
- [x] Tự lưu ván dở (localStorage) — menu hiện “Chơi tiếp ván dở”
- [x] Tutorial 5 bước (menu **Học chơi**)

## Cấu trúc

> ⚠️ **Bản đang chạy trên TV/PC là bản web** (`web/`), được đóng gói vào APK qua
> `android-webview/`. Thư mục Godot bên dưới (`autoload/ core/ ui/ scenes/`) là
> **bản gốc cũ (legacy)**, không còn là bản phát hành chính — giữ lại để tham khảo.

```
web/                Bản chính: HTML/CSS/JS chạy trên TV, PC, điện thoại
  ├─ js/chess.js    Engine cờ (luật, sinh nước, AI helper)
  ├─ js/sound.js    Âm thanh (WebAudio) + giọng đọc (Web Speech)
  └─ js/app.js      Giao diện, điều khiển remote/bàn phím/chạm
android-webview/    Vỏ WebView + Leanback TV để build APK
tests/web/          Kiểm thử end-to-end (Playwright) — CI tự chạy

autoload/ core/ ui/ scenes/   (legacy Godot — không dùng để phát hành)
docs/               art_bible, controls
```

## Ghi chú bản quyền

Dùng **nội bộ gia đình**. Không dùng asset/nhạc chính thức. Nếu phát hành công khai: redesign + đổi tên thương mại. Xem `docs/art_bible.md`.

## Kiểm thử

Bản web (khuyến nghị):

```bash
cd tests/web && npm ci && npx playwright install chromium && npm test
```

Bản Godot legacy (khi có Godot CLI):

```bash
godot --headless --path . --script tests/smoke_test.gd
```
