/* UI app — Doraemon Chess TV */
(function () {
  const C = window.Chess;
  const $ = (id) => document.getElementById(id);

  const screens = {
    menu: $("screen-menu"),
    game: $("screen-game"),
    tut: $("screen-tut"),
    chars: $("screen-chars"),
  };

  let mode = "menu";
  let menuI = 0;
  let tutI = 0;
  let charI = 0;
  let st = C.startBoard();
  let hist = [];
  let captured = { w: [], b: [] };
  let cursor = C.sq(4, 1);
  let selected = -1;
  let legalMap = new Map();
  let vsAI = false;
  let escArm = false;
  let promoMoves = null;
  let promoI = 0;
  let checkSq = -1;
  let deferredInstall = null;

  const MENU = [
    { t: "Chơi 2 người (bố mẹ + bé)", ico: "pieces/blue/king_doraemon.png", act: () => startGame(false) },
    { t: "Chơi với máy (dễ)", ico: "pieces/orange/rook_chaien.png", act: () => startGame(true) },
    { t: "Học chơi (5 bước)", ico: "pieces/blue/knight_nobita.png", act: () => showTut() },
    { t: "Giới thiệu nhân vật", ico: "pieces/blue/queen_xuka.png", act: () => showChars() },
    { t: "Toàn màn hình", ico: "pieces/blue/pawn_minidora.png", act: () => toggleFs() },
  ];

  const TUT = [
    "Chào mừng! Dùng <b>mũi tên</b> di chuyển, <b>Enter</b> chọn. Cũng có thể <b>chạm/click</b> ô cờ.",
    "Hai phe: <b>Xanh</b> (đi trước) và <b>Cam</b>. Bảo vệ <b>Doraemon (Vua)</b> của mình!",
    "<b>Doraemon</b>=Vua · <b>Xuka</b>=Hậu · <b>Chaien</b>=Xe · <b>Xeko</b>=Tượng · <b>Nobita</b>=Mã · <b>Mini-Dora</b>=Tốt.",
    "Chọn quân → chọn ô xanh (đi) hoặc cam (ăn). <b>H</b> gợi ý, <b>U</b> hoàn tác.",
    "Ăn quân có hiệu ứng sao! Chiếu Doraemon sẽ nhấp nháy. Thắng khi chiếu hết. Chúc vui!",
  ];

  const CHARS = [6, 5, 4, 3, 2, 1].map((t) => ({
    t,
    name: C.NAMES_VI[t],
    role: C.ROLE_VI[t],
    hint: C.HINT_VI[t],
    img: `pieces/blue/${
      { 6: "king_doraemon", 5: "queen_xuka", 4: "rook_chaien", 3: "bishop_xeko", 2: "knight_nobita", 1: "pawn_minidora" }[t]
    }.png`,
  }));

  function show(id) {
    Object.values(screens).forEach((s) => (s.hidden = true));
    screens[id].hidden = false;
    mode = id;
  }

  function toast(msg) {
    const el = $("toast");
    el.hidden = false;
    el.textContent = msg;
    clearTimeout(toast._t);
    toast._t = setTimeout(() => {
      el.hidden = true;
    }, 2000);
  }

  function sparkAt(clientX, clientY, color) {
    const layer = $("fx-layer");
    for (let i = 0; i < 18; i++) {
      const s = document.createElement("span");
      s.className = "spark";
      const ang = Math.random() * Math.PI * 2;
      const dist = 40 + Math.random() * 80;
      s.style.left = clientX + "px";
      s.style.top = clientY + "px";
      s.style.background = color || (Math.random() > 0.5 ? "#ffd54f" : "#4fc3f7");
      s.style.setProperty("--dx", Math.cos(ang) * dist + "px");
      s.style.setProperty("--dy", Math.sin(ang) * dist + "px");
      layer.appendChild(s);
      setTimeout(() => s.remove(), 700);
    }
  }

  function banner(text) {
    const layer = $("fx-layer");
    const b = document.createElement("div");
    b.className = "banner-fx";
    b.textContent = text;
    layer.appendChild(b);
    setTimeout(() => b.remove(), 900);
  }

  function renderMenu() {
    show("menu");
    const list = $("menu-list");
    list.innerHTML = MENU.map(
      (m, i) =>
        `<button type="button" class="menu-item ${i === menuI ? "active" : ""}" data-i="${i}">
          <img class="ico" src="${m.ico}" alt="" />
          <span>${i === menuI ? "▶ " : ""}${m.t}</span>
        </button>`
    ).join("");
    list.querySelectorAll(".menu-item").forEach((btn) => {
      btn.onclick = () => {
        menuI = +btn.dataset.i;
        MENU[menuI].act();
      };
    });
  }

  function startGame(ai) {
    vsAI = ai;
    st = C.startBoard();
    hist = [];
    captured = { w: [], b: [] };
    cursor = C.sq(4, 1);
    selected = -1;
    legalMap.clear();
    checkSq = -1;
    promoMoves = null;
    escArm = false;
    // An modal thang/hoa + phong cap (setAttribute de chac chan)
    const endM = $("end-modal");
    const promoM = $("promo");
    if (endM) {
      endM.hidden = true;
      endM.setAttribute("hidden", "");
    }
    if (promoM) {
      promoM.hidden = true;
      promoM.setAttribute("hidden", "");
    }
    $("mode-badge").textContent = ai ? "Chơi với máy" : "2 người";
    show("game");
    buildLegend();
    renderBoard();
    toast(ai ? "Chơi với máy — bé cầm Phe Xanh!" : "Hai người — Phe Xanh đi trước!");
  }

  function buildLegend() {
    $("legend").innerHTML = [6, 5, 4, 3, 2, 1]
      .map(
        (t) =>
          `<li><img src="pieces/blue/${
            { 6: "king_doraemon", 5: "queen_xuka", 4: "rook_chaien", 3: "bishop_xeko", 2: "knight_nobita", 1: "pawn_minidora" }[t]
          }.png" alt=""/><span><b>${C.NAMES_VI[t]}</b> — ${C.ROLE_VI[t]}</span></li>`
      )
      .join("");
  }

  function renderBoard(popSq) {
    const board = $("board");
    board.innerHTML = "";
    checkSq = -1;
    if (C.inCheck(st, st.turn)) checkSq = C.findKing(st, st.turn);

    for (let r = 7; r >= 0; r--) {
      for (let f = 0; f < 8; f++) {
        const s = C.sq(f, r);
        const p = st.sq[s];
        const d = document.createElement("div");
        d.className = "sq " + ((f + r) % 2 === 0 ? "light" : "dark");
        if (s === cursor) d.classList.add("cursor");
        if (s === selected) d.classList.add("sel");
        if (legalMap.has(s)) d.classList.add(legalMap.get(s) ? "cap" : "legal");
        if (s === checkSq) d.classList.add("check");
        if (popSq === s) d.classList.add("pop");
        if (!C.empty(p)) {
          const img = document.createElement("img");
          img.className = "piece-img";
          img.src = C.pieceImg(p);
          img.alt = C.NAMES_VI[C.typ(p)];
          img.draggable = false;
          d.appendChild(img);
        }
        d.onclick = () => {
          cursor = s;
          if (selected < 0) trySelect();
          else tryDest(d);
          renderBoard(s);
        };
        board.appendChild(d);
      }
    }

    const turn = $("turn-badge");
    const blue = st.turn === C.W;
    turn.textContent = "Lượt: " + (blue ? "Phe Xanh" : "Phe Cam");
    turn.className = "badge-turn " + (blue ? "blue" : "orange");

    $("cap-w").innerHTML = captured.w.map((t) => `<img src="pieces/orange/${fileOf(t)}" alt=""/>`).join("");
    $("cap-b").innerHTML = captured.b.map((t) => `<img src="pieces/blue/${fileOf(t)}" alt=""/>`).join("");
  }

  function fileOf(t) {
    return {
      1: "pawn_minidora.png",
      2: "knight_nobita.png",
      3: "bishop_xeko.png",
      4: "rook_chaien.png",
      5: "queen_xuka.png",
      6: "king_doraemon.png",
    }[t];
  }

  function trySelect() {
    const p = st.sq[cursor];
    if (C.empty(p) || C.side(p) !== st.turn) {
      toast("Chọn quân của lượt hiện tại");
      return;
    }
    selected = cursor;
    legalMap.clear();
    for (const m of C.legalFrom(st, selected)) {
      const cap = m.ep || !C.empty(st.sq[m.to]);
      legalMap.set(m.to, cap);
    }
    const t = C.typ(p);
    toast(`${C.NAMES_VI[t]} (${C.ROLE_VI[t]}) — ${C.HINT_VI[t]}`);
  }

  function tryDest(cellEl) {
    if (cursor === selected) {
      selected = -1;
      legalMap.clear();
      return;
    }
    const moves = C.legalFrom(st, selected).filter((m) => m.to === cursor);
    if (!moves.length) {
      const p = st.sq[cursor];
      if (!C.empty(p) && C.side(p) === st.turn) {
        trySelect();
        return;
      }
      toast("Ô này không đi được");
      return;
    }
    if (moves.some((m) => m.promo)) {
      promoMoves = moves;
      promoI = 0;
      openPromo();
      return;
    }
    doMove(moves[0], cellEl);
  }

  function openPromo() {
    const box = $("promo-choices");
    const order = [C.Q, C.R, C.B, C.N];
    box.innerHTML = order
      .map((t, i) => {
        const m = promoMoves.find((x) => x.promo === t) || promoMoves[0];
        return `<button type="button" class="promo-btn ${i === promoI ? "active" : ""}" data-i="${i}">
          <img src="pieces/blue/${fileOf(t)}" alt=""/><span>${C.NAMES_VI[t]}</span>
        </button>`;
      })
      .join("");
    box.querySelectorAll(".promo-btn").forEach((b) => {
      b.onclick = () => {
        promoI = +b.dataset.i;
        confirmPromo();
      };
    });
    const promoEl = $("promo");
    promoEl.hidden = false;
    promoEl.removeAttribute("hidden");
  }

  function confirmPromo() {
    const order = [C.Q, C.R, C.B, C.N];
    const t = order[promoI];
    const m = promoMoves.find((x) => x.promo === t) || promoMoves[0];
    const promoEl = $("promo");
    promoEl.hidden = true;
    promoEl.setAttribute("hidden", "");
    promoMoves = null;
    doMove(m);
  }

  function doMove(m, cellEl) {
    const mover = st.sq[m.from];
    const victim = m.ep ? st.sq[C.sq(C.file(m.to), C.rank(m.from))] : st.sq[m.to];
    hist.push({ st: C.clone(st), captured: { w: captured.w.slice(), b: captured.b.slice() } });

    if (!C.empty(victim)) {
      const arr = C.side(mover) === C.W ? captured.w : captured.b;
      arr.push(C.typ(victim));
      // FX
      const rect = cellEl ? cellEl.getBoundingClientRect() : $("board").getBoundingClientRect();
      sparkAt(rect.left + rect.width / 2, rect.top + rect.height / 2, "#ffd54f");
      banner("Ăn quân!");
      toast(`${C.NAMES_VI[C.typ(mover)]} ăn ${C.NAMES_VI[C.typ(victim)]}!`);
    } else {
      toast("Đã đi!");
    }

    st = C.apply(st, m);
    selected = -1;
    legalMap.clear();

    const moves = C.allLegal(st);
    if (!moves.length) {
      if (C.inCheck(st, st.turn)) {
        endGame(true);
      } else {
        endGame(false, true);
      }
    } else if (C.inCheck(st, st.turn)) {
      banner("Chiếu!");
      toast("Chiếu Doraemon rồi!");
      const rect = $("board").getBoundingClientRect();
      sparkAt(rect.left + rect.width / 2, rect.top + 40, "#ff5252");
    }

    renderBoard(m.to);
    if (vsAI && st.turn === C.BL && $("end-modal").hidden && C.allLegal(st).length) {
      setTimeout(aiMove, 380);
    }
  }

  function aiMove() {
    if (!$("end-modal").hidden) return;
    const moves = C.allLegal(st);
    if (!moves.length) return;
    const caps = moves.filter((m) => m.ep || !C.empty(st.sq[m.to]));
    const pool = caps.length ? caps : moves;
    // slight prefer checks
    let best = pool[Math.floor(Math.random() * pool.length)];
    for (const m of pool.slice(0, 8)) {
      const n = C.apply(st, m);
      if (C.inCheck(n, n.turn)) {
        best = m;
        break;
      }
    }
    doMove(best);
  }

  function endGame(mate, stale) {
    const winner = mate ? (st.turn === C.W ? "Phe Cam" : "Phe Xanh") : null;
    $("end-title").textContent = mate ? "Chiến thắng!" : "Hòa cờ!";
    $("end-msg").textContent = mate
      ? `${winner} thắng — Doraemon đội chiến thắng!`
      : "Không còn nước đi — hòa!";
    const endM = $("end-modal");
    endM.hidden = false;
    endM.removeAttribute("hidden");

    // confetti
    const conf = $("confetti");
    conf.innerHTML = "";
    for (let i = 0; i < 40; i++) {
      const s = document.createElement("span");
      s.style.left = Math.random() * 100 + "%";
      s.style.background = `hsl(${Math.random() * 360},90%,60%)`;
      s.style.animationDelay = Math.random() * 0.4 + "s";
      conf.appendChild(s);
    }
    banner(mate ? "Thắng!" : "Hòa!");
  }

  function undo() {
    if (!hist.length) {
      toast("Không hoàn tác được");
      return;
    }
    const h = hist.pop();
    st = h.st;
    captured = h.captured;
    selected = -1;
    legalMap.clear();
    const endM = $("end-modal");
    endM.hidden = true;
    endM.setAttribute("hidden", "");
    toast("Đã hoàn tác");
    renderBoard();
  }

  function hint() {
    const all = C.allLegal(st);
    if (!all.length) {
      toast("Không còn nước gợi ý");
      return;
    }
    // prefer capture
    const caps = all.filter((m) => m.ep || !C.empty(st.sq[m.to]));
    const m = (caps[0] || all[0]);
    cursor = m.from;
    selected = -1;
    legalMap.clear();
    trySelect();
    cursor = m.to;
    toast("Dorami gợi ý: " + C.NAMES_VI[C.typ(st.sq[m.from])] + " → ô đó!");
    renderBoard();
  }

  function showTut() {
    show("tut");
    tutI = 0;
    renderTut();
  }
  function renderTut() {
    $("tut-card").innerHTML = `<p>${TUT[tutI]}</p><p style="opacity:.7">${tutI + 1} / ${TUT.length}</p>`;
  }

  function showChars() {
    show("chars");
    charI = 0;
    renderChars();
  }
  function renderChars() {
    const c = CHARS[charI];
    $("char-card").innerHTML = `
      <img src="${c.img}" alt=""/>
      <div>
        <h2 style="margin:0;color:#fff59d;font-size:1.6rem">${c.name} — ${c.role}</h2>
        <p>${c.hint}</p>
        <p style="opacity:.7">${charI + 1} / ${CHARS.length}</p>
      </div>`;
  }

  function toggleFs() {
    const d = document;
    if (!d.fullscreenElement) {
      (d.documentElement.requestFullscreen || d.documentElement.webkitRequestFullscreen || (() => {})).call(
        d.documentElement
      );
      toast("Toàn màn hình");
    } else {
      (d.exitFullscreen || d.webkitExitFullscreen || (() => {})).call(d);
      toast("Thoát toàn màn hình");
    }
  }

  // Input
  window.addEventListener("keydown", (e) => {
    if (e.repeat) return;
    const k = e.key;

    if (mode === "menu") {
      if (k === "ArrowUp") {
        menuI = (menuI + MENU.length - 1) % MENU.length;
        renderMenu();
        e.preventDefault();
      } else if (k === "ArrowDown") {
        menuI = (menuI + 1) % MENU.length;
        renderMenu();
        e.preventDefault();
      } else if (k === "Enter" || k === " ") {
        MENU[menuI].act();
        e.preventDefault();
      }
      return;
    }

    if (mode === "tut") {
      if (k === "ArrowRight" || k === "Enter") {
        tutI++;
        if (tutI >= TUT.length) renderMenu();
        else renderTut();
        e.preventDefault();
      } else if (k === "ArrowLeft") {
        tutI = Math.max(0, tutI - 1);
        renderTut();
        e.preventDefault();
      } else if (k === "Escape") {
        renderMenu();
        e.preventDefault();
      }
      return;
    }

    if (mode === "chars") {
      if (k === "ArrowLeft") {
        charI = (charI + CHARS.length - 1) % CHARS.length;
        renderChars();
        e.preventDefault();
      } else if (k === "ArrowRight") {
        charI = (charI + 1) % CHARS.length;
        renderChars();
        e.preventDefault();
      } else if (k === "Enter" || k === "Escape") {
        renderMenu();
        e.preventDefault();
      }
      return;
    }

    if (mode !== "game") return;
    if (!$("promo").hidden) {
      if (k === "ArrowLeft") {
        promoI = (promoI + 3) % 4;
        openPromo();
        e.preventDefault();
      } else if (k === "ArrowRight") {
        promoI = (promoI + 1) % 4;
        openPromo();
        e.preventDefault();
      } else if (k === "Enter" || k === " ") {
        confirmPromo();
        e.preventDefault();
      } else if (k === "Escape") {
        const promoEl = $("promo");
        promoEl.hidden = true;
        promoEl.setAttribute("hidden", "");
        promoMoves = null;
        e.preventDefault();
      }
      return;
    }
    if (!$("end-modal").hidden) {
      if (k === "Enter" || k === "Escape") {
        renderMenu();
        e.preventDefault();
      }
      return;
    }

    let f = C.file(cursor),
      r = C.rank(cursor);
    if (k === "ArrowLeft") {
      f = Math.max(0, f - 1);
      cursor = C.sq(f, r);
      renderBoard();
      e.preventDefault();
    } else if (k === "ArrowRight") {
      f = Math.min(7, f + 1);
      cursor = C.sq(f, r);
      renderBoard();
      e.preventDefault();
    } else if (k === "ArrowUp") {
      r = Math.min(7, r + 1);
      cursor = C.sq(f, r);
      renderBoard();
      e.preventDefault();
    } else if (k === "ArrowDown") {
      r = Math.max(0, r - 1);
      cursor = C.sq(f, r);
      renderBoard();
      e.preventDefault();
    } else if (k === "Enter" || k === " ") {
      if (selected < 0) trySelect();
      else {
        const cell = $("board").children[(7 - C.rank(cursor)) * 8 + C.file(cursor)];
        tryDest(cell);
      }
      renderBoard(cursor);
      e.preventDefault();
    } else if (k === "Escape") {
      if (selected >= 0) {
        selected = -1;
        legalMap.clear();
        toast("Bỏ chọn");
      } else if (!escArm) {
        escArm = true;
        toast("Esc lần nữa để về menu");
        setTimeout(() => (escArm = false), 2000);
      } else {
        renderMenu();
        escArm = false;
      }
      renderBoard();
      e.preventDefault();
    } else if (k === "h" || k === "H") {
      hint();
      e.preventDefault();
    } else if (k === "u" || k === "U") {
      undo();
      e.preventDefault();
    }
  });

  $("btn-menu").onclick = () => renderMenu();
  $("btn-hint").onclick = () => hint();
  $("btn-undo").onclick = () => undo();
  $("btn-end-ok").onclick = () => renderMenu();
  $("btn-fs").onclick = () => toggleFs();

  // PWA install
  window.addEventListener("beforeinstallprompt", (e) => {
    e.preventDefault();
    deferredInstall = e;
    $("btn-install").hidden = false;
  });
  $("btn-install").onclick = async () => {
    if (!deferredInstall) return;
    deferredInstall.prompt();
    await deferredInstall.userChoice;
    deferredInstall = null;
    $("btn-install").hidden = true;
  };

  renderMenu();
})();
