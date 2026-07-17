# Build APK bằng GitHub Actions (không cần Android SDK trên máy)

Máy công ty chặn GitHub? Chuẩn bị project ở đây → mang về nhà / máy khác → push → tải APK.

## Quy trình khi cty chặn GitHub

```
[Máy cty]  zip project  →  USB / cloud cá nhân
                              ↓
[Máy nhà]  unzip → git init → push GitHub
                              ↓
[GitHub Actions]  build APK  →  artifact
                              ↓
[Máy nhà]  tải APK  →  USB  →  [Xiaomi TV] cài
```

### 1. Đóng gói trên máy cty (không cần git remote)

PowerShell:

```powershell
cd C:\Users\phuoctv01\Projects
Compress-Archive -Path doraemon-chess-tv -DestinationPath doraemon-chess-tv-src.zip -Force
```

**Không** cần copy thư mục `.godot` (nặng, CI sẽ import lại). Nếu zip cả `.godot` cũng được, chỉ to hơn.

### 2. Trên máy có GitHub

```bash
unzip doraemon-chess-tv-src.zip
cd doraemon-chess-tv
git init
git add .
git commit -m "Initial: Doraemon Chess TV"
# Tạo repo trống trên github.com rồi:
git branch -M main
git remote add origin https://github.com/<USER>/<REPO>.git
git push -u origin main
```

### 3. Chạy build APK (dùng WebView cho TV)

1. Vào repo GitHub → tab **Actions**
2. Chọn workflow **Build Android APK (WebView)** ← khuyến nghị Xiaomi TV
3. **Run workflow**
4. Đợi job xanh (~3–8 phút)
5. **Artifacts** → **doraemon-chess-tv-apk** → `DoraemonChessTV.apk`

> Workflow **Build Android APK** (Godot) là legacy — một số TV báo *không tương thích*.

Workflow WebView chạy khi push `web/` hoặc `android-webview/`.

### 4. Cài lên Xiaomi TV

1. TV: **Cài đặt → Quyền riêng tư / Bảo mật → Cài app không rõ nguồn** (bật)
2. Chép APK vào USB → File Manager trên TV → cài  
   **hoặc** ADB:

```bash
adb connect <IP_TV>:5555
adb install -r DoraemonChessTV.apk
```

## File liên quan trong repo

| File | Vai trò |
|------|---------|
| `.github/workflows/build-android-webview.yml` | **CI chính:** APK WebView + Leanback TV |
| `.github/workflows/build-android.yml` | Legacy: smoke test + export Godot APK |
| `android-webview/` | Manifest TV, WebView wrapper |
| `export_presets.cfg` | Preset Godot (multi-ABI, TV) — legacy |
| `tests/smoke_test.gd` | Kiểm tra logic cờ Godot |

## Ghi chú

- APK WebView ký release trong CI → **sideload gia đình**, không publish Play Store.
- Package id: `com.family.doraemonchesstv`
- WebView: pure Java (mọi ABI). Godot legacy: `armeabi-v7a` + `arm64-v8a`.
- Manifest bắt buộc có `LEANBACK_LAUNCHER` + `touchscreen` optional (CI verify).
- Không cần Android SDK / Godot trên máy local.

## Nếu job fail

1. Xem log step **Export APK** — thiếu template / SDK path.
2. Đảm bảo `export_presets.cfg` vẫn có `name="Android"`.
3. Khớp version Godot input với project (mặc định 4.7.1).
4. Chạy lại **Run workflow** (mạng GitHub thỉnh thoảng lỗi tải template).

## Build release (sau này)

Cần keystore riêng + secrets GitHub (`RELEASE_KEYSTORE_BASE64`, pass, alias). Không bắt buộc cho chơi nhà.
