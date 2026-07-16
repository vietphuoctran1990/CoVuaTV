# Kiểm thử bản web/TV

Bộ test end-to-end điều khiển bàn phím/remote (mô phỏng TV 1920×1080) bằng Playwright.

## Chạy tại máy

```bash
cd tests/web
npm ci
npx playwright install chromium
npm test
```

Nếu đã có Chromium sẵn (không muốn tải bản Playwright):

```bash
CHROMIUM_PATH=/đường/dẫn/tới/chrome npm test
```

## Bao phủ

- Menu, thống kê, Cài đặt (đổi theme, bật tự xoay bàn)
- Ván 2 người: chọn quân, nước hợp lệ, highlight nước đi, tự xoay bàn theo lượt
- Hoàn tác (lật bàn về đúng hướng)
- Gợi ý vẽ mũi tên (SVG)
- Menu tạm dừng (đủ mục, có Giọng đọc)
- Lưu/khôi phục ván dở
- Chơi với máy: chọn phe, máy đi trước khi bé cầm Cam
- Chiếu hết (Fool's mate) → modal thắng, thống kê, confetti, Chơi lại

CI chạy tự động qua `.github/workflows/web-test.yml` mỗi khi `web/**` thay đổi.
