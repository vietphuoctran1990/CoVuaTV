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


## Ảnh nhân vật “đúng kinh điển”

Repo **không** kèm hình official Doraemon (bản quyền).  
Muốn dùng ảnh bạn có quyền: xem **[docs/CUSTOM_CHARACTERS.md](docs/CUSTOM_CHARACTERS.md)**  
→ bỏ PNG vào `web/pieces/_import/` → `python3 tools/import_character_pack.py` → build APK WebView.

## Map quân cờ

| Quân | Nhân vật | Phe |
|------|----------|-----|
| Vua | Doraemon | Xanh / Cam |
| Hậu | Xuka | Xanh / Cam |
| Xe | Chaien | Xanh / Cam |
| Tượng | Xeko | Xanh / Cam |
| Mã | Nobita | Xanh / Cam |
| Tốt | Mini-Dora | Xanh / Cam |

## Build APK Android TV (Xiaomi / Google TV)

**Dùng workflow WebView** (không dùng bản Godot export cho TV):

1. Actions → **Build Android APK (WebView)** → **Run workflow**
2. Tải artifact `doraemon-chess-tv-apk` → file `DoraemonChessTV.apk`
3. TV: bật **Cài app không rõ nguồn** (Unknown sources)
4. Cài bằng USB File Manager **hoặc** ADB:

```bash
adb connect <IP_TV>:5555
adb install -r DoraemonChessTV.apk
```

### TV báo “không tương thích” / cài không được

Đã gặp trên **Xiaomi S Mini LED 55" 4K** khi cài nhầm **APK Godot** (thiếu `LEANBACK_LAUNCHER`, chỉ `arm64`).

| Làm | Chi tiết |
|-----|----------|
| 1 | Chỉ cài APK từ workflow **Build Android APK (WebView)** |
| 2 | Gỡ bản cũ trên TV (Settings → Apps) rồi cài lại |
| 3 | Nếu ADB: `adb uninstall com.family.doraemonchesstv` rồi `adb install DoraemonChessTV.apk` |
| 4 | Không dùng artifact của workflow **Build Android APK** (Godot legacy) |

APK WebView: pure Java + Leanback + mọi kích thước màn (4K/xlarge), minSdk 21.

Chi tiết: **[docs/WEB_TV.md](docs/WEB_TV.md)** · **[docs/GITHUB_BUILD.md](docs/GITHUB_BUILD.md)**

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
