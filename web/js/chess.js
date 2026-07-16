/** Chess engine — pure JS */
(function (global) {
  const EMPTY = 0, P = 1, N = 2, B = 3, R = 4, Q = 5, K = 6;
  const W = 0, BL = 1;
  const make = (t, s) => t | (s << 3);
  const typ = (p) => p & 7;
  const side = (p) => (p >> 3) & 1;
  const empty = (p) => !p;
  const sq = (f, r) => r * 8 + f;
  const file = (s) => s % 8;
  const rank = (s) => (s / 8) | 0;

  const NAMES_VI = {
    1: "Mini-Dora",
    2: "Nobita",
    3: "Xeko",
    4: "Chaien",
    5: "Xuka",
    6: "Doraemon",
  };
  const ROLE_VI = { 1: "Tốt", 2: "Mã", 3: "Tượng", 4: "Xe", 5: "Hậu", 6: "Vua" };
  const HINT_VI = {
    1: "Đi tới, ăn chéo. Lượt đầu có thể 2 ô.",
    2: "Nhảy chữ L — bay qua quân khác được!",
    3: "Đi chéo bao xa tùy thích.",
    4: "Đi ngang hoặc dọc thật mạnh.",
    5: "Đi mọi hướng — mạnh nhất!",
    6: "Đi 1 ô mọi hướng. Phải bảo vệ!",
  };
  const FILES = {
    1: "pawn_minidora.png",
    2: "knight_nobita.png",
    3: "bishop_xeko.png",
    4: "rook_chaien.png",
    5: "queen_xuka.png",
    6: "king_doraemon.png",
  };

  function pieceImg(p) {
    if (empty(p)) return null;
    const folder = side(p) === W ? "blue" : "orange";
    return `pieces/${folder}/${FILES[typ(p)]}`;
  }

  function startBoard() {
    const b = Array(64).fill(0);
    const back = [R, N, B, Q, K, B, N, R];
    for (let f = 0; f < 8; f++) {
      b[sq(f, 0)] = make(back[f], W);
      b[sq(f, 1)] = make(P, W);
      b[sq(f, 6)] = make(P, BL);
      b[sq(f, 7)] = make(back[f], BL);
    }
    return { sq: b, turn: W, castle: 15, ep: -1, half: 0, full: 1 };
  }

  function clone(st) {
    return {
      sq: st.sq.slice(),
      turn: st.turn,
      castle: st.castle,
      ep: st.ep,
      half: st.half,
      full: st.full,
    };
  }

  function findKing(st, s) {
    const k = make(K, s);
    return st.sq.findIndex((p) => p === k);
  }

  function attacked(st, target, by) {
    const tf = file(target),
      tr = rank(target);
    const kD = [
      [1, 2],
      [2, 1],
      [2, -1],
      [1, -2],
      [-1, -2],
      [-2, -1],
      [-2, 1],
      [-1, 2],
    ];
    for (const [df, dr] of kD) {
      const f = tf + df,
        r = tr + dr;
      if (f < 0 || f > 7 || r < 0 || r > 7) continue;
      const p = st.sq[sq(f, r)];
      if (!empty(p) && side(p) === by && typ(p) === N) return true;
    }
    for (let df = -1; df <= 1; df++)
      for (let dr = -1; dr <= 1; dr++) {
        if (!df && !dr) continue;
        const f = tf + df,
          r = tr + dr;
        if (f < 0 || f > 7 || r < 0 || r > 7) continue;
        const p = st.sq[sq(f, r)];
        if (!empty(p) && side(p) === by && typ(p) === K) return true;
      }
    const pdir = by === W ? 1 : -1;
    for (const df of [-1, 1]) {
      const f = tf + df,
        r = tr - pdir;
      if (f < 0 || f > 7 || r < 0 || r > 7) continue;
      const p = st.sq[sq(f, r)];
      if (!empty(p) && side(p) === by && typ(p) === P) return true;
    }
    const slide = (dirs, types) => {
      for (const [df, dr] of dirs) {
        let f = tf + df,
          r = tr + dr;
        while (f >= 0 && f < 8 && r >= 0 && r < 8) {
          const p = st.sq[sq(f, r)];
          if (!empty(p)) {
            if (side(p) === by && types.includes(typ(p))) return true;
            break;
          }
          f += df;
          r += dr;
        }
      }
      return false;
    };
    if (slide(
      [
        [1, 1],
        [1, -1],
        [-1, 1],
        [-1, -1],
      ],
      [B, Q]
    ))
      return true;
    if (slide(
      [
        [1, 0],
        [-1, 0],
        [0, 1],
        [0, -1],
      ],
      [R, Q]
    ))
      return true;
    return false;
  }

  function inCheck(st, s) {
    const k = findKing(st, s);
    return k < 0 || attacked(st, k, 1 - s);
  }

  function addMove(list, from, to, promo = 0, ep = false, castle = false) {
    list.push({ from, to, promo, ep, castle });
  }

  function genPseudo(st, from) {
    const p = st.sq[from];
    if (empty(p)) return [];
    const s = side(p),
      t = typ(p),
      f0 = file(from),
      r0 = rank(from),
      out = [];
    const enemy = (x) => !empty(x) && side(x) !== s;
    const pushSlide = (dirs) => {
      for (const [df, dr] of dirs) {
        let f = f0 + df,
          r = r0 + dr;
        while (f >= 0 && f < 8 && r >= 0 && r < 8) {
          const to = sq(f, r),
            tp = st.sq[to];
          if (empty(tp)) addMove(out, from, to);
          else {
            if (enemy(tp)) addMove(out, from, to);
            break;
          }
          f += df;
          r += dr;
        }
      }
    };
    if (t === P) {
      const dir = s === W ? 1 : -1,
        start = s === W ? 1 : 6,
        pr = s === W ? 7 : 0;
      const r1 = r0 + dir;
      if (r1 >= 0 && r1 < 8 && empty(st.sq[sq(f0, r1)])) {
        if (r1 === pr) for (const prt of [Q, R, B, N]) addMove(out, from, sq(f0, r1), prt);
        else addMove(out, from, sq(f0, r1));
        if (r0 === start && empty(st.sq[sq(f0, r0 + 2 * dir)])) addMove(out, from, sq(f0, r0 + 2 * dir));
      }
      for (const df of [-1, 1]) {
        const f = f0 + df,
          r = r0 + dir;
        if (f < 0 || f > 7 || r < 0 || r > 7) continue;
        const to = sq(f, r);
        if (enemy(st.sq[to])) {
          if (r === pr) for (const prt of [Q, R, B, N]) addMove(out, from, to, prt);
          else addMove(out, from, to);
        } else if (to === st.ep) addMove(out, from, to, 0, true);
      }
    } else if (t === N) {
      for (const [df, dr] of [
        [1, 2],
        [2, 1],
        [2, -1],
        [1, -2],
        [-1, -2],
        [-2, -1],
        [-2, 1],
        [-1, 2],
      ]) {
        const f = f0 + df,
          r = r0 + dr;
        if (f < 0 || f > 7 || r < 0 || r > 7) continue;
        const to = sq(f, r);
        if (empty(st.sq[to]) || enemy(st.sq[to])) addMove(out, from, to);
      }
    } else if (t === B)
      pushSlide([
        [1, 1],
        [1, -1],
        [-1, 1],
        [-1, -1],
      ]);
    else if (t === R)
      pushSlide([
        [1, 0],
        [-1, 0],
        [0, 1],
        [0, -1],
      ]);
    else if (t === Q)
      pushSlide([
        [1, 1],
        [1, -1],
        [-1, 1],
        [-1, -1],
        [1, 0],
        [-1, 0],
        [0, 1],
        [0, -1],
      ]);
    else if (t === K) {
      for (let df = -1; df <= 1; df++)
        for (let dr = -1; dr <= 1; dr++) {
          if (!df && !dr) continue;
          const f = f0 + df,
            r = r0 + dr;
          if (f < 0 || f > 7 || r < 0 || r > 7) continue;
          const to = sq(f, r);
          if (empty(st.sq[to]) || enemy(st.sq[to])) addMove(out, from, to);
        }
      if (!inCheck(st, s)) {
        const rankC = s === W ? 0 : 7;
        if (r0 === rankC && f0 === 4) {
          const ks = s === W ? 1 : 4,
            qs = s === W ? 2 : 8;
          if (
            st.castle & ks &&
            empty(st.sq[sq(5, rankC)]) &&
            empty(st.sq[sq(6, rankC)]) &&
            !attacked(st, sq(5, rankC), 1 - s) &&
            !attacked(st, sq(6, rankC), 1 - s)
          )
            addMove(out, from, sq(6, rankC), 0, false, true);
          if (
            st.castle & qs &&
            empty(st.sq[sq(1, rankC)]) &&
            empty(st.sq[sq(2, rankC)]) &&
            empty(st.sq[sq(3, rankC)]) &&
            !attacked(st, sq(3, rankC), 1 - s) &&
            !attacked(st, sq(2, rankC), 1 - s)
          )
            addMove(out, from, sq(2, rankC), 0, false, true);
        }
      }
    }
    return out;
  }

  function apply(st, m) {
    const n = clone(st);
    const p = n.sq[m.from];
    const s = side(p),
      t = typ(p);
    n.sq[m.from] = 0;
    if (m.ep) n.sq[sq(file(m.to), rank(m.from))] = 0;
    if (m.castle) {
      const r = rank(m.from);
      if (file(m.to) === 6) {
        n.sq[sq(7, r)] = 0;
        n.sq[sq(5, r)] = make(R, s);
      } else {
        n.sq[sq(0, r)] = 0;
        n.sq[sq(3, r)] = make(R, s);
      }
    }
    n.sq[m.to] = m.promo ? make(m.promo, s) : p;
    n.ep = -1;
    if (t === P && Math.abs(rank(m.to) - rank(m.from)) === 2)
      n.ep = sq(file(m.from), ((rank(m.from) + rank(m.to)) / 2) | 0);
    if (t === K) n.castle &= s === W ? ~3 : ~12;
    if (t === R) {
      if (m.from === 0) n.castle &= ~2;
      if (m.from === 7) n.castle &= ~1;
      if (m.from === 56) n.castle &= ~8;
      if (m.from === 63) n.castle &= ~4;
    }
    if (m.to === 0) n.castle &= ~2;
    if (m.to === 7) n.castle &= ~1;
    if (m.to === 56) n.castle &= ~8;
    if (m.to === 63) n.castle &= ~4;
    n.turn = 1 - n.turn;
    if (n.turn === W) n.full++;
    return n;
  }

  function legalFrom(st, from) {
    const p = st.sq[from];
    if (empty(p) || side(p) !== st.turn) return [];
    return genPseudo(st, from).filter((m) => !inCheck(apply(st, m), st.turn));
  }

  function allLegal(st) {
    const out = [];
    for (let i = 0; i < 64; i++) out.push(...legalFrom(st, i));
    return out;
  }

  global.Chess = {
    EMPTY,
    P,
    N,
    B,
    R,
    Q,
    K,
    W,
    BL,
    make,
    typ,
    side,
    empty,
    sq,
    file,
    rank,
    NAMES_VI,
    ROLE_VI,
    HINT_VI,
    pieceImg,
    startBoard,
    clone,
    findKing,
    inCheck,
    legalFrom,
    allLegal,
    apply,
  };
})(window);
