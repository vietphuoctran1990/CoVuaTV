# Cờ Vua Doraemon — Web / PWA / APK TV

## 1. Chơi trên máy (đã ổn định)

- **Nhanh:** mở `web/index.html` hoặc `Choi-Game.bat` → **1**
- **PWA / offline tốt hơn:** `Choi-Game.bat` → **2** (server `http://127.0.0.1:8765`)
  - Chrome: menu ⋮ → **Cài đặt Cờ Vua Doraemon…** (nếu hiện)
  - **F11** hoặc nút **Toàn màn hình** trong game

### Tính năng UI

- Sprite chibi Doraemon / Xuka / Chaien / Xeko / Nobita / Mini-Dora (2 phe)
- Tiếng Việt, chữ lớn
- Hiệu ứng ăn quân (spark), chiếu (banner + nhấp nháy vua), thắng (confetti)
- Remote-like: mũi tên + Enter, H gợi ý, U hoàn tác
- Click/chạm ô cờ

## 2. PWA

File:

- `web/manifest.webmanifest` — `display: fullscreen`, landscape
- `web/sw.js` — cache offline
- `web/icons/*`

**Lưu ý:** Service Worker / “Cài app” cần **http://localhost** hoặc **https**, không chạy tốt với `file://`.

## 3. APK Android TV (Xiaomi)

Project: `android-webview/` — WebView load `assets/www` (bản copy của `web/`).

### Build bằng GitHub Actions (không cần SDK máy cty)

1. Push repo lên GitHub (máy nhà nếu cty chặn)
2. **Actions** → **Build Android APK (WebView)** → **Run workflow**
3. Tải artifact **`doraemon-chess-tv-apk`**
4. Cài TV: Unknown sources → USB / `adb install -r app-debug.apk`

Package id: `com.family.doraemonchesstv`  
Có `LEANBACK_LAUNCHER` cho Android TV.

### Cập nhật web trong APK

CI **tự copy** `web/` → `android-webview/app/src/main/assets/www/` mỗi lần build.  
Chỉ cần sửa trong `web/`, không sửa tay assets.

## 4. Điều khiển TV

| Remote | Hành vi |
|--------|---------|
| D-pad | Di chuyển ô / menu |
| OK | Chọn |
| Back | Esc (JS) — hủy / menu |
