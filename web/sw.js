// sw.js — keeps the page working on a weak connection or none. Always the newest version when there's a connection, so
// testers never get stuck on an old one; what was last seen when there isn't. Voice clips are the exception: their names
// come from their words, so one that's been played once is never downloaded again, which saves mobile data.
const CACHE = 'penko-cuentas-1';

self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => event.waitUntil(self.clients.claim()));

const keep = async (request, response) => {
  if (response.ok) await (await caches.open(CACHE)).put(request, response.clone());
  return response;
};

self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);
  if (request.method !== 'GET' || url.origin !== location.origin) return;
  if (url.pathname.includes('/assets/voice/')) {
    // Fetched whole, without the part-of-a-file request audio players make, because only whole files can be kept
    const whole = new Request(url.href);
    event.respondWith(caches.match(whole).then((hit) => hit ?? fetch(whole).then((r) => keep(whole, r))));
    return;
  }
  event.respondWith(
    fetch(request)
      .then((r) => keep(request, r))
      .catch(async () => (await caches.match(request, { ignoreSearch: true })) ?? (request.mode === 'navigate' ? caches.match('./') : Response.error())),
  );
});
