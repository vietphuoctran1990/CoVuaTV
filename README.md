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
| ↑ ↓ ← → | Di chuyển |
| Enter | Chọn / đi |
| Esc | Hủy / menu (×2) |
| H / U | Gợi ý / hoàn tác |

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

- [x] Luật cờ: đi quân, ăn, nhập thành, en passant, phong cấp, chiếu / hết / hòa
- [x] 2 người cùng TV + chơi với máy (AI dễ)
- [x] Remote: chọn 2 bước, gợi ý, hoàn tác
- [x] HUD tiếng Việt, map nhân vật, toast “ăn quân / chiếu”
- [x] Menu, cài đặt, giới thiệu nhân vật
- [x] Sprite chibi 6 nhân vật × 2 phe (`assets/pieces/blue|orange`)
- [x] SFX + BGM (`assets/audio/*.wav`) — bật/tắt trong Cài đặt
- [x] Tutorial 5 bước (menu **Học chơi**)

## Cấu trúc

```
autoload/     GameBus, Settings, AudioMgr
core/         board, move_gen, game_state, ai, piece_catalog
ui/           main_menu, board_view, game_root
scenes/       main_menu.tscn, game.tscn
docs/         art_bible, controls
```

## Ghi chú bản quyền

Dùng **nội bộ gia đình**. Không dùng asset/nhạc chính thức. Nếu phát hành công khai: redesign + đổi tên thương mại. Xem `docs/art_bible.md`.

## Kiểm thử nhanh logic (khi có Godot CLI)

```bash
godot --headless --path . --script tests/smoke_test.gd
```
