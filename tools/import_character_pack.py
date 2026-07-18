#!/usr/bin/env python3
"""Import character PNGs from web/pieces/_import into game paths.

Usage:
  python3 tools/import_character_pack.py
  python3 tools/import_character_pack.py --src /path/to/pack

Expects:
  <src>/blue/*.png and <src>/orange/*.png
  with names: king_doraemon, queen_xuka, rook_chaien,
              bishop_xeko, knight_nobita, pawn_minidora
"""
from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path

NAMES = [
    "king_doraemon.png",
    "queen_xuka.png",
    "rook_chaien.png",
    "bishop_xeko.png",
    "knight_nobita.png",
    "pawn_minidora.png",
]
TEAMS = ("blue", "orange")

ROOT = Path(__file__).resolve().parents[1]


def fit_square_png(src: Path, dest: Path, size: int = 256) -> None:
    try:
        from PIL import Image
    except ImportError:
        # Fallback: raw copy if Pillow missing
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest)
        print(f"  copy (no Pillow): {dest.relative_to(ROOT)}")
        return

    im = Image.open(src).convert("RGBA")
    # Trim near-empty margins if mostly transparent
    bbox = im.getbbox()
    if bbox:
        im = im.crop(bbox)
    # Fit inside size x size
    im.thumbnail((size, size), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ox = (size - im.width) // 2
    oy = (size - im.height) // 2
    canvas.paste(im, (ox, oy), im)
    dest.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(dest, "PNG", optimize=True)
    print(f"  ok {dest.relative_to(ROOT)} ({src.stat().st_size} → {dest.stat().st_size} B)")


def collect(src_root: Path) -> list[tuple[str, str, Path]]:
    found: list[tuple[str, str, Path]] = []
    missing: list[str] = []
    for team in TEAMS:
        for name in NAMES:
            p = src_root / team / name
            if p.is_file():
                found.append((team, name, p))
            else:
                missing.append(f"{team}/{name}")
    # Allow single set: if orange missing but blue exists, reuse blue
    if missing:
        reused = []
        still = []
        for m in missing:
            team, name = m.split("/", 1)
            if team == "orange":
                alt = src_root / "blue" / name
                if alt.is_file():
                    found.append(("orange", name, alt))
                    reused.append(m)
                    continue
            still.append(m)
        if reused:
            print("Reuse blue → orange for:", ", ".join(reused))
        missing = still
    if missing:
        print("THIẾU file:")
        for m in missing:
            print("  -", m)
        print(f"\nĐặt PNG vào: {src_root}")
        print("Xem docs/CUSTOM_CHARACTERS.md")
        sys.exit(1)
    return found


def main() -> None:
    ap = argparse.ArgumentParser(description="Import character pack into CoVuaTV")
    ap.add_argument(
        "--src",
        type=Path,
        default=ROOT / "web" / "pieces" / "_import",
        help="Folder with blue/ and orange/ PNGs",
    )
    ap.add_argument("--size", type=int, default=256)
    args = ap.parse_args()
    src_root: Path = args.src

    if not src_root.is_dir():
        print(f"Không thấy thư mục: {src_root}")
        print("Tạo web/pieces/_import/blue và .../orange rồi bỏ PNG vào.")
        sys.exit(1)

    items = collect(src_root)
    targets = [
        ROOT / "web" / "pieces",
        ROOT / "android-webview" / "app" / "src" / "main" / "assets" / "www" / "pieces",
        ROOT / "assets" / "pieces",
    ]

    print(f"Import {len(items)} file từ {src_root}")
    for team, name, src in items:
        for base in targets:
            dest = base / team / name
            fit_square_png(src, dest, size=args.size)

    # Bump service worker cache hint
    sw = ROOT / "web" / "sw.js"
    if sw.is_file():
        text = sw.read_text(encoding="utf-8")
        if "doraemon-chess-v3" in text:
            sw.write_text(text.replace("doraemon-chess-v3-tv", "doraemon-chess-v4-custom"), encoding="utf-8")
            (ROOT / "android-webview/app/src/main/assets/www/sw.js").write_text(
                sw.read_text(encoding="utf-8"), encoding="utf-8"
            )
            print("Updated SW cache name → v4-custom")

    print("\nXong. Build APK: Actions → Build Android APK (WebView)")
    print("Hoặc commit + push main.")


if __name__ == "__main__":
    main()
