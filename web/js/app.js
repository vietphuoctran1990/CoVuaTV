/* UI app — Doraemon Chess TV */
(function () {
  const C = window.Chess;
  const S = window.Sound;
  const $ = (id) => document.getElementById(id);

  const screens = {
    menu: $("screen-menu"),
    game: $("screen-game"),
    tut: $("screen-tut"),
    chars: $("screen-chars"),
  };

  const SAVE_KEY = "dct_save";
  const VAL = { 1: 100, 2: 300, 3: 300, 4: 500, 5: 900, 6: 0 };
  const AI_NAMES = { 1: "Máy · Dễ", 2: "Máy · Vừa", 3: "Máy · Khó" };
  const PIECE_FILES = {
    1: "pawn_minidora.png",
    2: "knight_nobita.png",
    3: "bishop_xeko.png",
    4: "rook_chaien.png",
    5: "queen_xuka.png",
    6: "king_doraemon.png",
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
  let aiLevel = 1;
  let aiTimer = 0;
  let lastMove = null;
  let promoMoves = null;
  let promoI = 0;
  let deferredInstall = null;
  let cells = []; // 64 o co, index theo so hieu o
  let pauseI = 0;
  let diffI = 0;
  let endI = 0;
  let menuItems = [];
  let navT = 0; // throttle giu phim mui ten

  const TUT = [
    "Chào mừng! Dùng <b>mũi tên</b> di chuyển, <b>Enter/OK</b> chọn. Cũng có thể <b>chạm/click</b> ô cờ.",
    "Hai phe: <b>Xanh</b> (đi trước) và <b>Cam</b>. Bảo vệ <b>Doraemon (Vua)</b> của mình!",
    "<b>Doraemon</b>=Vua · <b>Xuka</b>=Hậu · <b>Chaien</b>=Xe · <b>Xeko</b>=Tượng · <b>Nobita</b>=Mã · <b>Mini-Dora</b>=Tốt.",
    "Chọn quân → chọn ô xanh (đi) hoặc cam (ăn). Nhấn <b>Back/Esc</b> để mở menu: gợi ý, hoàn tác.",
    "Ăn quân có hiệu ứng sao! Chiếu Doraemon sẽ nhấp nháy. Thắng khi chiếu hết. Chúc vui!",
  ];

  const CHARS = [6, 5, 4, 3, 2, 1].map((t) => ({
    t,
    name: C.NAMES_VI[t],
    role: C.ROLE_VI[t],
    hint: C.HINT_VI[t],
    img: `pieces/blue/${PIECE_FILES[t]}`,
  }));

  const DIFF = [
    { t: "Dễ — máy đi thoải mái, bé dễ thắng", lv: 1 },
    { t: "Vừa — máy biết ăn quân, tránh mất quân", lv: 2 },
    { t: "Khó — máy tính trước một nước", lv: 3 },
  ];

  /* ---------- tien ich ---------- */

  function show(id) {
    Object.values(screens).forEach((s) => (s.hidden = true));
    screens[id].hidden = false;
    mode = id;
    S.setInGame(id === "game");
  }

  function showModal(id) {
    const el = $(id);
    el.hidden = false;
    el.removeAttribute("hidden");
  }
  function hideModal(id) {
    const el = $(id);
    el.hidden = true;
    el.setAttribute("hidden", "");
  }
  function modalOpen(id) {
    return !$(id).hidden;
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

  function fileOf(t) {
    return PIECE_FILES[t];
  }

  /* ---------- luu / khoi phuc van co ---------- */

  function saveGame() {
    // Van chua di nuoc nao thi khong dang luu
    if (!hist.length) {
      clearSave();
      return;
    }
    try {
      localStorage.setItem(
        SAVE_KEY,
        JSON.stringify({
          st,
          hist: hist.slice(-100),
          captured,
          vsAI,
          aiLevel,
          lastMove,
        })
      );
    } catch (e) {}
  }

  function loadSave() {
    try {
      const raw = localStorage.getItem(SAVE_KEY);
      if (!raw) return null;
      const d = JSON.parse(raw);
      if (!d || !d.st || !Array.isArray(d.st.sq) || d.st.sq.length !== 64) return null;
      return d;
    } catch (e) {
      return null;
    }
  }

  function clearSave() {
    try {
      localStorage.removeItem(SAVE_KEY);
    } catch (e) {}
  }

  /* ---------- hieu ung ---------- */

  function sparkAt(clientX, clientY, color) {
    const layer = $("fx-layer");
    for (let i = 0; i < 18; i++) {
      const s = document.createElement("span");
      s.className = "spark";
      const ang = Math.random() * Math.PI * 2;
      const dist = 40 + Math.random() * 90;
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

  function confettiBurst(count) {
    const layer = $("fx-layer");
    for (let i = 0; i < count; i++) {
      const s = document.createElement("span");
      s.className = "confetti-piece";
      s.style.left = Math.random() * 100 + "vw";
      s.style.background = `hsl(${Math.random() * 360},90%,60%)`;
      s.style.animationDelay = Math.random() * 0.8 + "s";
      s.style.animationDuration = 1.8 + Math.random() * 1.2 + "s";
      layer.appendChild(s);
      setTimeout(() => s.remove(), 4000);
    }
  }

  // Hieu ung quan bi an: ban sao thu nho + mo dan tai cho
  function captureFx(sqIdx, victim) {
    const rect = cells[sqIdx].getBoundingClientRect();
    const img = document.createElement("img");
    img.src = C.pieceImg(victim);
    img.className = "fx-cap";
    img.style.left = rect.left + rect.width * 0.06 + "px";
    img.style.top = rect.top + rect.height * 0.06 + "px";
    img.style.width = rect.width * 0.88 + "px";
    img.style.height = rect.height * 0.88 + "px";
    $("fx-layer").appendChild(img);
    setTimeout(() => img.remove(), 500);
    sparkAt(rect.left + rect.width / 2, rect.top + rect.height / 2, "#ffd54f");
  }

  // FLIP: truot quan tu o cu sang o moi (sau khi da sync DOM)
  function animatePiece(from, to) {
    const img = cells[to] && cells[to].querySelector(".piece-img");
    if (!img) return;
    const a = cells[from].getBoundingClientRect();
    const b = cells[to].getBoundingClientRect();
    const dx = a.left - b.left;
    const dy = a.top - b.top;
    if (!dx && !dy) return;
    img.style.transition = "none";
    img.style.transform = `translate(${dx}px, ${dy}px)`;
    img.getBoundingClientRect(); // ep reflow
    img.style.transition = "transform .18s ease-out";
    img.style.transform = "";
    img.addEventListener(
      "transitionend",
      () => {
        img.style.transition = "";
      },
      { once: true }
    );
  }

  /* ---------- menu chinh ---------- */

  function buildMenu() {
    const items = [];
    if (loadSave()) {
      items.push({ t: "Chơi tiếp ván dở", ico: "pieces/blue/king_doraemon.png", act: resumeGame });
    }
    items.push(
      { t: "Chơi 2 người (bố mẹ + bé)", ico: "pieces/blue/king_doraemon.png", act: () => startGame(false) },
      { t: "Chơi với máy", ico: "pieces/orange/rook_chaien.png", act: openDiff },
      { t: "Học chơi (5 bước)", ico: "pieces/blue/knight_nobita.png", act: showTut },
      { t: "Giới thiệu nhân vật", ico: "pieces/blue/queen_xuka.png", act: showChars },
      {
        t: "Âm thanh: " + (S.master() ? "Bật" : "Tắt"),
        ico: "pieces/orange/bishop_xeko.png",
        act: () => {
          S.setMaster(!S.master());
          S.play("click", 0.6);
          renderMenu();
        },
      },
      { t: "Toàn màn hình", ico: "pieces/blue/pawn_minidora.png", act: toggleFs }
    );
    return items;
  }

  function renderMenu() {
    clearTimeout(aiTimer);
    hideModal("diff");
    menuItems = buildMenu();
    if (menuI >= menuItems.length) menuI = 0;
    show("menu");
    const list = $("menu-list");
    list.innerHTML = menuItems
      .map(
        (m, i) =>
          `<button type="button" class="menu-item ${i === menuI ? "active" : ""}" data-i="${i}">
            <img class="ico" src="${m.ico}" alt="" />
            <span>${i === menuI ? "▶ " : ""}${m.t}</span>
          </button>`
      )
      .join("");
    list.querySelectorAll(".menu-item").forEach((btn) => {
      btn.onclick = () => {
        menuI = +btn.dataset.i;
        menuItems[menuI].act();
      };
    });
  }

  /* ---------- chon do kho ---------- */

  function openDiff() {
    diffI = Math.max(0, aiLevel - 1);
    renderDiff();
    showModal("diff");
  }

  function renderDiff() {
    const box = $("diff-list");
    box.innerHTML = DIFF.map(
      (d, i) =>
        `<button type="button" class="pause-item ${i === diffI ? "active" : ""}" data-i="${i}">
          ${i === diffI ? "▶ " : ""}${d.t}
        </button>`
    ).join("");
    box.querySelectorAll(".pause-item").forEach((b) => {
      b.onclick = () => {
        diffI = +b.dataset.i;
        startGame(true, DIFF[diffI].lv);
      };
    });
  }

  /* ---------- vong doi van co ---------- */

  function startGame(ai, level) {
    clearTimeout(aiTimer);
    vsAI = ai;
    if (level) aiLevel = level;
    st = C.startBoard();
    hist = [];
    captured = { w: [], b: [] };
    cursor = C.sq(4, 1);
    selected = -1;
    legalMap.clear();
    lastMove = null;
    promoMoves = null;
    hideModal("end-modal");
    hideModal("promo");
    hideModal("pause");
    hideModal("diff");
    clearSave();
    $("mode-badge").textContent = ai ? AI_NAMES[aiLevel] : "2 người";
    show("game");
    buildLegend();
    buildBoard();
    renderAll();
    toast(ai ? "Bé cầm Phe Xanh — đi trước nhé!" : "Hai người — Phe Xanh đi trước!");
  }

  function resumeGame() {
    const d = loadSave();
    if (!d) {
      renderMenu();
      return;
    }
    clearTimeout(aiTimer);
    st = d.st;
    hist = d.hist || [];
    captured = d.captured || { w: [], b: [] };
    vsAI = !!d.vsAI;
    aiLevel = d.aiLevel || 1;
    lastMove = d.lastMove || null;
    cursor = lastMove ? lastMove.to : C.sq(4, 1);
    selected = -1;
    legalMap.clear();
    promoMoves = null;
    hideModal("end-modal");
    hideModal("promo");
    hideModal("pause");
    hideModal("diff");
    $("mode-badge").textContent = vsAI ? AI_NAMES[aiLevel] : "2 người";
    show("game");
    buildLegend();
    buildBoard();
    renderAll();
    toast("Chơi tiếp ván dở!");
    if (vsAI && st.turn === C.BL && C.allLegal(st).length) aiTimer = setTimeout(aiMove, 600);
  }

  function goMenu() {
    clearTimeout(aiTimer);
    renderMenu();
  }

  /* ---------- dung ban co ---------- */

  function buildLegend() {
    $("legend").innerHTML = [6, 5, 4, 3, 2, 1]
      .map(
        (t) =>
          `<li><img src="pieces/blue/${fileOf(t)}" alt=""/><span><b>${C.NAMES_VI[t]}</b> — ${C.ROLE_VI[t]}</span></li>`
      )
      .join("");
  }

  function buildBoard() {
    const board = $("board");
    board.innerHTML = "";
    cells = new Array(64);
    for (let r = 7; r >= 0; r--) {
      for (let f = 0; f < 8; f++) {
        const s = C.sq(f, r);
        const d = document.createElement("div");
        d.className = "sq " + ((f + r) % 2 === 0 ? "light" : "dark");
        if (r === 0) {
          const c = document.createElement("span");
          c.className = "coord coord-f";
          c.textContent = "abcdefgh"[f];
          d.appendChild(c);
        }
        if (f === 0) {
          const c = document.createElement("span");
          c.className = "coord coord-r";
          c.textContent = String(r + 1);
          d.appendChild(c);
        }
        d.onclick = () => onCellActivate(s);
        cells[s] = d;
        board.appendChild(d);
      }
    }
  }

  // Dong bo anh quan co voi trang thai (khong dung lai toan bo DOM)
  function syncPieces() {
    for (let s = 0; s < 64; s++) {
      const d = cells[s];
      const p = st.sq[s];
      let img = d.querySelector(".piece-img");
      if (C.empty(p)) {
        if (img) img.remove();
        continue;
      }
      const src = C.pieceImg(p);
      if (!img) {
        img = document.createElement("img");
        img.className = "piece-img";
        img.draggable = false;
        d.appendChild(img);
      }
      if (img.getAttribute("src") !== src) img.setAttribute("src", src);
      img.alt = C.NAMES_VI[C.typ(p)];
    }
  }

  function updateClasses() {
    const checkSq = C.inCheck(st, st.turn) ? C.findKing(st, st.turn) : -1;
    for (let s = 0; s < 64; s++) {
      const d = cells[s];
      d.classList.toggle("cursor", s === cursor);
      d.classList.toggle("sel", s === selected);
      const leg = legalMap.has(s);
      d.classList.toggle("legal", leg && !legalMap.get(s));
      d.classList.toggle("cap", leg && !!legalMap.get(s));
      d.classList.toggle("check", s === checkSq);
      d.classList.toggle("last", !!lastMove && (s === lastMove.from || s === lastMove.to));
    }
  }

  function updateHud() {
    const turn = $("turn-badge");
    const blue = st.turn === C.W;
    turn.textContent = "Lượt: " + (blue ? "Phe Xanh" : "Phe Cam");
    turn.className = "badge-turn " + (blue ? "blue" : "orange");
    $("cap-w").innerHTML = captured.w.map((t) => `<img src="pieces/orange/${fileOf(t)}" alt=""/>`).join("");
    $("cap-b").innerHTML = captured.b.map((t) => `<img src="pieces/blue/${fileOf(t)}" alt=""/>`).join("");
  }

  function renderAll() {
    syncPieces();
    updateClasses();
    updateHud();
  }

  /* ---------- thao tac choi ---------- */

  function moveCursor(df, dr) {
    const f = Math.min(7, Math.max(0, C.file(cursor) + df));
    const r = Math.min(7, Math.max(0, C.rank(cursor) + dr));
    const ns = C.sq(f, r);
    if (ns === cursor) return;
    cursor = ns;
    updateClasses();
    S.play("click", 0.15);
  }

  function onCellActivate(s) {
    cursor = s;
    if (selected < 0) trySelect();
    else tryDest();
    updateClasses();
  }

  function trySelect() {
    const p = st.sq[cursor];
    if (C.empty(p) || C.side(p) !== st.turn) {
      toast("Chọn quân của lượt hiện tại");
      S.play("bonk", 0.5);
      return;
    }
    selected = cursor;
    legalMap.clear();
    for (const m of C.legalFrom(st, selected)) {
      const cap = m.ep || !C.empty(st.sq[m.to]);
      legalMap.set(m.to, cap);
    }
    const t = C.typ(p);
    S.play("click", 0.5);
    toast(`${C.NAMES_VI[t]} (${C.ROLE_VI[t]}) — ${C.HINT_VI[t]}`);
  }

  function tryDest() {
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
      S.play("bonk", 0.5);
      return;
    }
    if (moves.some((m) => m.promo)) {
      promoMoves = moves;
      promoI = 0;
      openPromo();
      return;
    }
    doMove(moves[0]);
  }

  function openPromo() {
    const box = $("promo-choices");
    const order = [C.Q, C.R, C.B, C.N];
    const moverSide = C.side(st.sq[promoMoves[0].from]);
    const folder = moverSide === C.W ? "blue" : "orange";
    box.innerHTML = order
      .map(
        (t, i) =>
          `<button type="button" class="promo-btn ${i === promoI ? "active" : ""}" data-i="${i}">
            <img src="pieces/${folder}/${fileOf(t)}" alt=""/><span>${C.NAMES_VI[t]}</span>
          </button>`
      )
      .join("");
    box.querySelectorAll(".promo-btn").forEach((b) => {
      b.onclick = () => {
        promoI = +b.dataset.i;
        confirmPromo();
      };
    });
    showModal("promo");
  }

  function confirmPromo() {
    const order = [C.Q, C.R, C.B, C.N];
    const t = order[promoI];
    const m = promoMoves.find((x) => x.promo === t) || promoMoves[0];
    hideModal("promo");
    promoMoves = null;
    doMove(m);
  }

  function doMove(m) {
    const mover = st.sq[m.from];
    const epSq = C.sq(C.file(m.to), C.rank(m.from));
    const victim = m.ep ? st.sq[epSq] : st.sq[m.to];
    hist.push({
      st: C.clone(st),
      captured: { w: captured.w.slice(), b: captured.b.slice() },
      lastMove,
    });

    if (!C.empty(victim)) {
      const arr = C.side(mover) === C.W ? captured.w : captured.b;
      arr.push(C.typ(victim));
      captureFx(m.ep ? epSq : m.to, victim);
      banner("Ăn quân!");
      toast(`${C.NAMES_VI[C.typ(mover)]} ăn ${C.NAMES_VI[C.typ(victim)]}!`);
      S.play("capture");
    } else if (m.promo) {
      S.play("promote");
    } else {
      S.play("move", 0.7);
    }

    st = C.apply(st, m);
    lastMove = { from: m.from, to: m.to };
    selected = -1;
    legalMap.clear();

    renderAll();
    animatePiece(m.from, m.to);
    if (m.castle) {
      const r = C.rank(m.from);
      if (C.file(m.to) === 6) animatePiece(C.sq(7, r), C.sq(5, r));
      else animatePiece(C.sq(0, r), C.sq(3, r));
    }
    if (m.promo) {
      const d = cells[m.to];
      d.classList.remove("pop");
      void d.offsetWidth;
      d.classList.add("pop");
    }

    const moves = C.allLegal(st);
    if (!moves.length) {
      if (C.inCheck(st, st.turn)) endGame("mate");
      else endGame("draw", "Hết nước đi — hòa!");
      return;
    }
    if (C.insufficientMaterial(st)) {
      endGame("draw", "Hai bên không đủ quân chiếu hết — hòa!");
      return;
    }
    if (st.half >= 100) {
      endGame("draw", "50 nước không ăn quân — hòa!");
      return;
    }
    if (C.inCheck(st, st.turn)) {
      banner("Chiếu!");
      toast("Chiếu Doraemon rồi!");
      S.play("check");
      const k = C.findKing(st, st.turn);
      if (k >= 0 && cells[k]) {
        const rect = cells[k].getBoundingClientRect();
        sparkAt(rect.left + rect.width / 2, rect.top + rect.height / 2, "#ff5252");
      }
    }

    saveGame();
    if (vsAI && st.turn === C.BL) aiTimer = setTimeout(aiMove, 450);
  }

  /* ---------- AI ---------- */

  function gainOf(state, m) {
    let g = 0;
    const victim = m.ep ? state.sq[C.sq(C.file(m.to), C.rank(m.from))] : state.sq[m.to];
    if (!C.empty(victim)) g += VAL[C.typ(victim)];
    if (m.promo) g += VAL[m.promo] - VAL[C.P];
    return g;
  }

  function pickBestMove(state, level) {
    const moves = C.allLegal(state);
    if (!moves.length) return null;
    if (level === 1) {
      const caps = moves.filter((m) => gainOf(state, m) > 0);
      if (caps.length && Math.random() < 0.6) return caps[(Math.random() * caps.length) | 0];
      return moves[(Math.random() * moves.length) | 0];
    }
    let best = null;
    let bestSc = -Infinity;
    for (const m of moves) {
      const n = C.apply(state, m);
      const replies = C.allLegal(n);
      let sc;
      if (!replies.length) {
        // chieu het = thang; het nuoc (hoa) = trung binh
        sc = C.inCheck(n, n.turn) ? 1e6 : 0;
      } else {
        const moverVal = VAL[m.promo || C.typ(state.sq[m.from])];
        sc = gainOf(state, m) + (C.inCheck(n, n.turn) ? 30 : 0);
        if (level === 2) {
          // phat neu o den bi tan cong (de mat quan)
          if (C.attacked(n, m.to, n.turn)) sc -= moverVal;
        } else {
          // level 3: tru nuoc dap tra tot nhat cua doi thu
          let worst = 0;
          for (const r of replies) worst = Math.max(worst, gainOf(n, r));
          sc -= worst * 0.9;
        }
      }
      sc += Math.random() * 10;
      if (sc > bestSc) {
        bestSc = sc;
        best = m;
      }
    }
    return best;
  }

  function aiMove() {
    if (mode !== "game" || modalOpen("end-modal") || modalOpen("pause")) return;
    const m = pickBestMove(st, aiLevel);
    if (m) doMove(m);
  }

  function hint() {
    const m = pickBestMove(st, 2);
    if (!m) {
      toast("Không còn nước gợi ý");
      return;
    }
    cursor = m.from;
    selected = -1;
    legalMap.clear();
    trySelect();
    cursor = m.to;
    updateClasses();
    toast("Dorami gợi ý: " + C.NAMES_VI[C.typ(st.sq[m.from])] + " → ô đang sáng!");
  }

  function undo() {
    clearTimeout(aiTimer);
    if (!hist.length) {
      toast("Không hoàn tác được");
      S.play("bonk", 0.5);
      return;
    }
    let h = hist.pop();
    // Voi may: lui ca nuoc cua may lan nuoc cua nguoi de ve dung luot be
    if (vsAI && h.st.turn === C.BL && hist.length) h = hist.pop();
    st = h.st;
    captured = h.captured;
    lastMove = h.lastMove || null;
    selected = -1;
    legalMap.clear();
    hideModal("end-modal");
    renderAll();
    saveGame();
    S.play("click", 0.6);
    toast("Đã hoàn tác");
    if (vsAI && st.turn === C.BL && C.allLegal(st).length) aiTimer = setTimeout(aiMove, 600);
  }

  /* ---------- ket thuc van ---------- */

  function endGame(kind, msg) {
    clearTimeout(aiTimer);
    clearSave();
    const mate = kind === "mate";
    const blueWins = mate && st.turn === C.BL; // ben den luot bi chieu het
    $("end-title").textContent = mate ? "Chiến thắng!" : "Hòa cờ!";
    $("end-msg").textContent = mate
      ? `${blueWins ? "Phe Xanh" : "Phe Cam"} thắng — Doraemon đội chiến thắng!`
      : msg || "Không còn nước đi — hòa!";
    $("end-img").src = `pieces/${!mate || blueWins ? "blue" : "orange"}/king_doraemon.png`;
    endI = 0;
    syncEndButtons();
    showModal("end-modal");
    S.setInGame(false); // dung nhac nen cho fanfare
    S.play(mate ? "win" : "promote");
    confettiBurst(mate ? 90 : 30);
    banner(mate ? "Thắng!" : "Hòa!");
  }

  function syncEndButtons() {
    $("btn-again").classList.toggle("active", endI === 0);
    $("btn-end-ok").classList.toggle("active", endI === 1);
  }

  /* ---------- menu tam dung ---------- */

  function pauseItems() {
    return [
      { t: "Tiếp tục", act: closePause },
      {
        t: "Gợi ý",
        act: () => {
          closePause();
          hint();
        },
      },
      {
        t: "Hoàn tác",
        act: () => {
          closePause();
          undo();
        },
      },
      {
        t: "Hiệu ứng âm thanh: " + (S.getSfx() ? "Bật" : "Tắt"),
        act: () => {
          S.setSfx(!S.getSfx());
          S.play("click", 0.6);
          renderPause();
        },
      },
      {
        t: "Nhạc nền: " + (S.getBgm() ? "Bật" : "Tắt"),
        act: () => {
          S.setBgm(!S.getBgm());
          renderPause();
        },
      },
      {
        t: "Chơi lại từ đầu",
        act: () => startGame(vsAI),
      },
      {
        t: hist.length ? "Về menu (ván được lưu)" : "Về menu",
        act: () => {
          hideModal("pause");
          saveGame();
          goMenu();
        },
      },
    ];
  }

  function openPause() {
    clearTimeout(aiTimer);
    pauseI = 0;
    renderPause();
    showModal("pause");
    S.play("click", 0.5);
  }

  function closePause() {
    hideModal("pause");
    if (mode === "game" && vsAI && st.turn === C.BL && !modalOpen("end-modal") && C.allLegal(st).length) {
      aiTimer = setTimeout(aiMove, 450);
    }
  }

  function renderPause() {
    const items = pauseItems();
    if (pauseI >= items.length) pauseI = 0;
    const box = $("pause-list");
    box.innerHTML = items
      .map(
        (it, i) =>
          `<button type="button" class="pause-item ${i === pauseI ? "active" : ""}" data-i="${i}">
            ${i === pauseI ? "▶ " : ""}${it.t}
          </button>`
      )
      .join("");
    box.querySelectorAll(".pause-item").forEach((b) => {
      b.onclick = () => {
        pauseI = +b.dataset.i;
        pauseItems()[pauseI].act();
      };
    });
  }

  /* ---------- man hinh phu ---------- */

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

  /* ---------- ban phim / remote ---------- */

  window.addEventListener("keydown", (e) => {
    S.unlock();
    const k = e.key;
    const isArrow = k === "ArrowUp" || k === "ArrowDown" || k === "ArrowLeft" || k === "ArrowRight";

    // Cho phep giu phim mui ten (D-pad) lap lai, co throttle
    if (e.repeat) {
      if (!isArrow) return;
      const now = performance.now();
      if (now - navT < 110) {
        e.preventDefault();
        return;
      }
    }
    if (isArrow) navT = performance.now();

    if (mode === "menu") {
      if (modalOpen("diff")) {
        if (k === "ArrowUp") {
          diffI = (diffI + DIFF.length - 1) % DIFF.length;
          renderDiff();
          S.play("click", 0.4);
          e.preventDefault();
        } else if (k === "ArrowDown") {
          diffI = (diffI + 1) % DIFF.length;
          renderDiff();
          S.play("click", 0.4);
          e.preventDefault();
        } else if (k === "Enter" || k === " ") {
          startGame(true, DIFF[diffI].lv);
          e.preventDefault();
        } else if (k === "Escape") {
          hideModal("diff");
          e.preventDefault();
        }
        return;
      }
      if (k === "ArrowUp") {
        menuI = (menuI + menuItems.length - 1) % menuItems.length;
        renderMenu();
        S.play("click", 0.4);
        e.preventDefault();
      } else if (k === "ArrowDown") {
        menuI = (menuI + 1) % menuItems.length;
        renderMenu();
        S.play("click", 0.4);
        e.preventDefault();
      } else if (k === "Enter" || k === " ") {
        menuItems[menuI].act();
        e.preventDefault();
      }
      return;
    }

    if (mode === "tut") {
      if (k === "ArrowRight" || k === "Enter") {
        tutI++;
        S.play("click", 0.4);
        if (tutI >= TUT.length) renderMenu();
        else renderTut();
        e.preventDefault();
      } else if (k === "ArrowLeft") {
        tutI = Math.max(0, tutI - 1);
        renderTut();
        S.play("click", 0.4);
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
        S.play("click", 0.4);
        e.preventDefault();
      } else if (k === "ArrowRight") {
        charI = (charI + 1) % CHARS.length;
        renderChars();
        S.play("click", 0.4);
        e.preventDefault();
      } else if (k === "Enter" || k === "Escape") {
        renderMenu();
        e.preventDefault();
      }
      return;
    }

    if (mode !== "game") return;

    if (modalOpen("promo")) {
      if (k === "ArrowLeft") {
        promoI = (promoI + 3) % 4;
        openPromo();
        S.play("click", 0.4);
        e.preventDefault();
      } else if (k === "ArrowRight") {
        promoI = (promoI + 1) % 4;
        openPromo();
        S.play("click", 0.4);
        e.preventDefault();
      } else if (k === "Enter" || k === " ") {
        confirmPromo();
        e.preventDefault();
      } else if (k === "Escape") {
        hideModal("promo");
        promoMoves = null;
        e.preventDefault();
      }
      return;
    }

    if (modalOpen("end-modal")) {
      if (k === "ArrowLeft" || k === "ArrowRight") {
        endI = 1 - endI;
        syncEndButtons();
        S.play("click", 0.4);
        e.preventDefault();
      } else if (k === "Enter" || k === " ") {
        if (endI === 0) startGame(vsAI);
        else renderMenu();
        e.preventDefault();
      } else if (k === "Escape") {
        renderMenu();
        e.preventDefault();
      }
      return;
    }

    if (modalOpen("pause")) {
      const items = pauseItems();
      if (k === "ArrowUp") {
        pauseI = (pauseI + items.length - 1) % items.length;
        renderPause();
        S.play("click", 0.4);
        e.preventDefault();
      } else if (k === "ArrowDown") {
        pauseI = (pauseI + 1) % items.length;
        renderPause();
        S.play("click", 0.4);
        e.preventDefault();
      } else if (k === "Enter" || k === " ") {
        items[pauseI].act();
        e.preventDefault();
      } else if (k === "Escape") {
        closePause();
        e.preventDefault();
      }
      return;
    }

    if (k === "ArrowLeft") {
      moveCursor(-1, 0);
      e.preventDefault();
    } else if (k === "ArrowRight") {
      moveCursor(1, 0);
      e.preventDefault();
    } else if (k === "ArrowUp") {
      moveCursor(0, 1);
      e.preventDefault();
    } else if (k === "ArrowDown") {
      moveCursor(0, -1);
      e.preventDefault();
    } else if (k === "Enter" || k === " ") {
      if (selected < 0) trySelect();
      else tryDest();
      updateClasses();
      e.preventDefault();
    } else if (k === "Escape") {
      if (selected >= 0) {
        selected = -1;
        legalMap.clear();
        toast("Bỏ chọn");
        updateClasses();
      } else {
        openPause();
      }
      e.preventDefault();
    } else if (k === "h" || k === "H") {
      hint();
      e.preventDefault();
    } else if (k === "u" || k === "U") {
      undo();
      e.preventDefault();
    }
  });

  /* ---------- nut cham / chuot ---------- */

  $("btn-menu").onclick = () => {
    if (mode === "game") openPause();
    else renderMenu();
  };
  $("btn-hint").onclick = () => hint();
  $("btn-undo").onclick = () => undo();
  $("btn-end-ok").onclick = () => renderMenu();
  $("btn-again").onclick = () => startGame(vsAI);
  $("btn-fs").onclick = () => toggleFs();

  document.addEventListener("pointerdown", () => S.unlock(), { once: true, capture: true });

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
