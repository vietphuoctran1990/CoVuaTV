/* Service worker — offline cache for PWA */
const CACHE = "doraemon-chess-v1";
const ASSETS = [
  "./",
  "./index.html",
  "./css/style.css",
  "./js/chess.js",
  "./js/app.js",
  "./manifest.webmanifest",
  "./icons/icon-192.png",
  "./icons/icon-512.png",
  "./icons/apple-touch-icon.png",
  "./pieces/blue/king_doraemon.png",
  "./pieces/blue/queen_xuka.png",
  "./pieces/blue/rook_chaien.png",
  "./pieces/blue/bishop_xeko.png",
  "./pieces/blue/knight_nobita.png",
  "./pieces/blue/pawn_minidora.png",
  "./pieces/orange/king_doraemon.png",
  "./pieces/orange/queen_xuka.png",
  "./pieces/orange/rook_chaien.png",
  "./pieces/orange/bishop_xeko.png",
  "./pieces/orange/knight_nobita.png",
  "./pieces/orange/pawn_minidora.png",
];

self.addEventListener("install", (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(ASSETS)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (e) => {
  if (e.request.method !== "GET") return;
  e.respondWith(
    caches.match(e.request).then((cached) => {
      const fetched = fetch(e.request)
        .then((res) => {
          if (res && res.ok) {
            const clone = res.clone();
            caches.open(CACHE).then((c) => c.put(e.request, clone));
          }
          return res;
        })
        .catch(() => cached);
      return cached || fetched;
    })
  );
});
