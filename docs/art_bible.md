# Art Bible — Cờ Vua Doraemon TV

## Mục tiêu

Bé 7 tuổi nhìn từ sofa **2–3m** vẫn nhận ra: Doraemon, Xuka, Chaien, Xeko, Nobita, Mini-Dora.

## Map

| Type | Tên hiển thị | Đặc trưng vẽ |
|------|--------------|--------------|
| KING | Doraemon | Mèo robot xanh, túi bụng trắng, chuông |
| QUEEN | Xuka | Tóc ngắn, nơ hồng, váy |
| ROOK | Chaien | To, áo cam, chống nạnh |
| BISHOP | Xeko | Gầy, tóc chữ M, áo vàng |
| KNIGHT | Nobita | Kính tròn, prop bay nhỏ (take-copter stylized) |
| PAWN | Mini-Dora | Doraemon nhí, đơn giản |

## Hai phe

- **Phe Xanh** (logic trắng): viền xanh dương `#0277BD`, fill `#4FC3F7`
- **Phe Cam** (logic đen): viền `#BF360C`, fill `#FF8A65`  
Cùng pose, khác màu outfit.

## Quy tắc

1. Chibi, đầu to, viền ≥ 4px @1080p.
2. Badge chữ V/H/X/T/M/● góc trên trái.
3. Không trace frame phim; không logo chính thức.
4. Kích thước sprite khuyến nghị: **256×256** PNG, transparent.
5. Đặt file: `assets/pieces/blue/king_doraemon.png` …

## Pipeline

Placeholder (hiện tại, vẽ bằng code) → sketch → final PNG → gán texture trong `board_view` (thay `_draw_piece`).
