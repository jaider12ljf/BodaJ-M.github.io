/* Service worker del álbum: permite instalarlo como app y abrirlo aunque la señal sea débil.
   Solo guarda la "cáscara" de la app; las fotos y los datos siempre vienen de Supabase. */
const CACHE = 'album-jm-v1';
const SHELL = ['./', './index.html', './config.js', './manifest.webmanifest', './icono-192.png', './icono-512.png',
  '../img/sello.webp', '../img/sello-sm.webp', '../img/sobre-textura.jpg'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', e => {
  e.waitUntil(caches.keys()
    .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
    .then(() => self.clients.claim()));
});

self.addEventListener('fetch', e => {
  const url = new URL(e.request.url);
  if(e.request.method !== 'GET' || url.origin !== location.origin) return;
  /* Red primero (para recibir siempre la última versión); si no hay señal, la copia guardada */
  e.respondWith(
    fetch(e.request)
      .then(res => {
        if(res.ok){ const copy = res.clone(); caches.open(CACHE).then(c => c.put(e.request, copy)); }
        return res;
      })
      .catch(() => caches.match(e.request))
  );
});
