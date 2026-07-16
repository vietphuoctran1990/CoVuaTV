/*
 * Kiểm thử end-to-end bản web/TV bằng Playwright (Chromium).
 * Chạy: cd tests/web && npm ci && npx playwright install chromium && node run.js
 * Biến môi trường tùy chọn:
 *   CHROMIUM_PATH=/đường/dẫn/chrome  — dùng Chromium có sẵn thay vì bản Playwright tải.
 */
const { chromium } = require("playwright");
const path = require("path");

const INDEX = "file://" + path.resolve(__dirname, "../../web/index.html");

let pass = 0,
  fail = 0;
const ok = (name, cond) => {
  console.log((cond ? "PASS" : "FAIL") + " — " + name);
  cond ? pass++ : (fail++, (process.exitCode = 1));
};

(async () => {
  const launchOpts = {
    args: [
      "--allow-file-access-from-files",
      "--autoplay-policy=no-user-gesture-required",
      "--mute-audio",
    ],
  };
  if (process.env.CHROMIUM_PATH) launchOpts.executablePath = process.env.CHROMIUM_PATH;

  const browser = await chromium.launch(launchOpts);
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });
  const errors = [];
  page.on("pageerror", (e) => errors.push("pageerror: " + e.message));
  page.on("console", (m) => {
    if (m.type() === "error") errors.push("console: " + m.text());
  });

  const T = (ms) => page.waitForTimeout(ms);
  const clickText = async (sel, text) => {
    await page.locator(sel, { hasText: text }).first().click();
    await T(180);
  };
  const domRankTop = () =>
    page.evaluate(() => document.querySelectorAll("#board .sq")[0].querySelector(".coord-r")?.textContent);
  const boardClick = async (f, r) => {
    await page.evaluate(
      ({ f, r }) => {
        const topRank = document.querySelectorAll("#board .sq")[0].querySelector(".coord-r")?.textContent;
        const flipped = topRank === "1";
        const vr = flipped ? r : 7 - r;
        const vf = flipped ? 7 - f : f;
        document.querySelectorAll("#board .sq")[vr * 8 + vf].click();
      },
      { f, r }
    );
    await T(220);
  };

  await page.goto(INDEX);
  await page.evaluate(() => localStorage.clear());
  await page.reload();
  await T(400);

  // --- Menu & thống kê ---
  ok("menu hiển thị", await page.locator("#screen-menu").isVisible());
  ok("menu 6 mục", (await page.locator(".menu-item").count()) === 6);
  ok("có dòng thống kê", (await page.locator("#menu-stats").textContent()).length > 0);

  // --- Cài đặt: theme (#8) + auto-flip (#7) ---
  await clickText(".menu-item", "Cài đặt");
  ok("modal cài đặt mở", await page.locator("#settings").isVisible());
  await clickText("#settings-list .pause-item", "Bàn cờ");
  ok("theme đổi sang wood", (await page.evaluate(() => document.body.getAttribute("data-theme"))) === "wood");
  await clickText("#settings-list .pause-item", "tự xoay bàn");
  ok("auto-flip bật", (await page.evaluate(() => localStorage.getItem("dct_autoflip"))) === "1");
  await clickText("#settings-list .pause-item", "Đóng");
  ok("cài đặt đóng", !(await page.locator("#settings").isVisible()));

  // --- Ván 2 người + engine cơ bản + auto-flip ---
  await clickText(".menu-item", "2 người");
  ok("vào game 2 người", await page.locator("#screen-game").isVisible());
  ok("bàn cờ 64 ô", (await page.locator(".sq").count()) === 64);
  ok("32 quân", (await page.locator(".piece-img").count()) === 32);
  ok("có tọa độ (16)", (await page.locator(".coord").count()) === 16);
  ok("khởi đầu hướng Xanh (top rank 8)", (await domRankTop()) === "8");
  await boardClick(4, 1);
  ok("chọn e2 hiện 2 nước", (await page.locator(".sq.legal").count()) === 2);
  await boardClick(4, 3);
  await T(300);
  ok("auto-flip: lật hướng Cam (top rank 1)", (await domRankTop()) === "1");
  ok("highlight nước vừa đi", (await page.locator(".sq.last").count()) === 2);
  ok("lượt Cam", (await page.locator("#turn-badge.orange").count()) === 1);

  // --- Pause (#2 giọng nói toggle) ---
  await page.keyboard.press("Escape");
  await T(180);
  ok("pause 8 mục", (await page.locator("#pause-list .pause-item").count()) === 8);
  ok(
    "pause có Giọng đọc",
    (await page.locator("#pause-list .pause-item").allTextContents()).some((t) => t.includes("Giọng đọc"))
  );
  await page.keyboard.press("Escape");
  await T(180);

  // --- Undo (lật lại) ---
  await page.keyboard.press("u");
  await T(250);
  ok("undo: lượt Xanh", (await page.locator("#turn-badge.blue").count()) === 1);
  ok("undo: bàn về hướng Xanh (top rank 8)", (await domRankTop()) === "8");

  // --- Gợi ý vẽ mũi tên (#5) ---
  await page.keyboard.press("h");
  await T(250);
  ok("gợi ý chọn 1 quân", (await page.locator(".sq.sel").count()) === 1);
  ok("gợi ý vẽ mũi tên", (await page.locator("#arrow-layer polygon").count()) === 1);
  ok("mũi tên có line", (await page.locator("#arrow-layer line").count()) === 1);
  await page.keyboard.press("Escape");
  await T(150);

  // --- Lưu ván ---
  await boardClick(3, 1);
  await boardClick(3, 3);
  await T(300);
  await page.keyboard.press("Escape");
  await T(150);
  await clickText("#pause-list .pause-item", "Về menu");
  ok("menu có Chơi tiếp (7 mục)", (await page.locator(".menu-item").count()) === 7);

  // --- Chơi với máy: chọn phe Cam (#3) ---
  await clickText(".menu-item", "Chơi với máy");
  ok("modal độ khó mở", await page.locator("#diff").isVisible());
  ok("mặc định Xanh", (await page.locator("#diff-side").textContent()).includes("Xanh"));
  await page.keyboard.press("ArrowRight");
  await T(120);
  ok("đổi sang Cam", (await page.locator("#diff-side").textContent()).includes("Cam"));
  await page.keyboard.press("Enter");
  await T(1500);
  ok("bé Cam: máy đi trước → lượt Cam", (await page.locator("#turn-badge.orange").count()) === 1);
  ok("bàn lật cho Cam (top rank 1)", (await domRankTop()) === "1");
  ok("HUD ghi (bé)", (await page.locator("#turn-badge").textContent()).includes("bé"));
  ok("32 quân sau nước máy", (await page.locator(".piece-img").count()) === 32);

  // --- Chiếu hết (Fool's mate) + thống kê (#4) ---
  await page.goto(INDEX);
  await page.evaluate(() => {
    localStorage.clear();
    localStorage.setItem("dct_autoflip", "0");
  });
  await page.reload();
  await T(300);
  await clickText(".menu-item", "2 người");
  await boardClick(5, 1);
  await boardClick(5, 2); // f3
  await boardClick(4, 6);
  await boardClick(4, 4); // e5
  await boardClick(6, 1);
  await boardClick(6, 3); // g4
  await boardClick(3, 7);
  await boardClick(7, 3); // Qh4#
  await T(500);
  ok("modal kết thúc hiện", await page.locator("#end-modal").isVisible());
  ok("Phe Cam thắng", (await page.locator("#end-msg").textContent()).includes("Cam"));
  ok("thống kê pvp = 1", (await page.evaluate(() => JSON.parse(localStorage.getItem("dct_stats")).pvpGames)) === 1);
  ok("confetti bắn", (await page.locator(".confetti-piece").count()) > 0);

  // --- Chơi lại ---
  await page.keyboard.press("Enter");
  await T(300);
  ok("chơi lại: 32 quân", (await page.locator(".piece-img").count()) === 32);
  ok("chơi lại: lượt Xanh", (await page.locator("#turn-badge.blue").count()) === 1);

  ok("không có lỗi JS", errors.length === 0);
  if (errors.length) console.log(errors.join("\n"));

  console.log(`\n${pass} pass, ${fail} fail`);
  await browser.close();
  if (fail) process.exit(1);
})().catch((e) => {
  console.error("CRASH:", e);
  process.exit(1);
});
