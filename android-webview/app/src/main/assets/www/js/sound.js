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

  /* ---------- Giong noi (Web Speech) ---------- */
  let voiceOn = store.get("dct_voice", true);
  let viVoice = null;
  let voiceReady = false;

  function pickVoice() {
    if (!global.speechSynthesis) return;
    const list = global.speechSynthesis.getVoices() || [];
    viVoice =
      list.find((v) => /vi[-_]/i.test(v.lang)) ||
      list.find((v) => /^vi/i.test(v.lang)) ||
      null;
    voiceReady = true;
  }
  if (global.speechSynthesis) {
    pickVoice();
    global.speechSynthesis.onvoiceschanged = pickVoice;
  }

  function speak(text) {
    if (!voiceOn || !text || !global.speechSynthesis || !global.SpeechSynthesisUtterance) return;
    if (!voiceReady) pickVoice();
    try {
      global.speechSynthesis.cancel();
      const u = new global.SpeechSynthesisUtterance(text);
      u.lang = "vi-VN";
      if (viVoice) u.voice = viVoice;
      u.rate = 0.95;
      u.pitch = 1.05;
      global.speechSynthesis.speak(u);
    } catch (e) {}
  }

  global.Sound = {
    unlock,
    play,
    speak,
    getVoice: () => voiceOn,
    setVoice(v) {
      voiceOn = v;
      store.set("dct_voice", v);
      if (!v && global.speechSynthesis) global.speechSynthesis.cancel();
    },
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
