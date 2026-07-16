/* Sound manager — WebAudio. XHR de chay duoc ca file:// trong Android WebView. */
(function (global) {
  const NAMES = ["click", "move", "capture", "check", "promote", "win", "bonk", "bgm"];
  let ctx = null;
  let buffers = {};
  let bgmNode = null;
  let inGame = false;
  let unlocked = false;

  const store = {
    get(k, dv) {
      try {
        const v = localStorage.getItem(k);
        return v === null ? dv : v === "1";
      } catch (e) {
        return dv;
      }
    },
    set(k, v) {
      try {
        localStorage.setItem(k, v ? "1" : "0");
      } catch (e) {}
    },
  };
  let sfxOn = store.get("dct_sfx", true);
  let bgmOn = store.get("dct_bgm", true);

  // Goi trong cu chi dau tien cua nguoi dung (keydown / pointerdown)
  function unlock() {
    if (unlocked) return;
    unlocked = true;
    const AC = global.AudioContext || global.webkitAudioContext;
    if (!AC) return;
    try {
      ctx = new AC();
    } catch (e) {
      ctx = null;
      return;
    }
    if (ctx.state === "suspended") ctx.resume().catch(() => {});
    NAMES.forEach(load);
  }

  function load(name) {
    try {
      const xhr = new XMLHttpRequest();
      xhr.open("GET", "audio/" + name + ".wav", true);
      xhr.responseType = "arraybuffer";
      xhr.onload = () => {
        // status 0 = file:// trong WebView
        if (xhr.status !== 200 && xhr.status !== 0) return;
        if (!xhr.response) return;
        ctx.decodeAudioData(
          xhr.response,
          (buf) => {
            buffers[name] = buf;
            if (name === "bgm") refreshBgm();
          },
          () => {}
        );
      };
      xhr.onerror = () => {};
      xhr.send();
    } catch (e) {}
  }

  function play(name, vol) {
    if (!sfxOn || !ctx || !buffers[name]) return;
    if (ctx.state === "suspended") ctx.resume().catch(() => {});
    try {
      const src = ctx.createBufferSource();
      src.buffer = buffers[name];
      const g = ctx.createGain();
      g.gain.value = vol == null ? 0.9 : vol;
      src.connect(g).connect(ctx.destination);
      src.start();
    } catch (e) {}
  }

  function refreshBgm() {
    const want = inGame && bgmOn;
    if (want && !bgmNode && ctx && buffers.bgm) {
      try {
        const src = ctx.createBufferSource();
        src.buffer = buffers.bgm;
        src.loop = true;
        const g = ctx.createGain();
        g.gain.value = 0.16;
        src.connect(g).connect(ctx.destination);
        src.start();
        bgmNode = src;
      } catch (e) {}
    } else if (!want && bgmNode) {
      try {
        bgmNode.stop();
      } catch (e) {}
      bgmNode = null;
    }
  }

  global.Sound = {
    unlock,
    play,
    setInGame(v) {
      inGame = v;
      refreshBgm();
    },
    getSfx: () => sfxOn,
    getBgm: () => bgmOn,
    setSfx(v) {
      sfxOn = v;
      store.set("dct_sfx", v);
    },
    setBgm(v) {
      bgmOn = v;
      store.set("dct_bgm", v);
      refreshBgm();
    },
    master: () => sfxOn || bgmOn,
    setMaster(v) {
      this.setSfx(v);
      this.setBgm(v);
    },
  };
})(window);
