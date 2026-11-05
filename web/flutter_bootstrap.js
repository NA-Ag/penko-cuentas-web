{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  // Characters in no bundled font are simply missing, rather than fetched from Google
  config: { fontFallbackBaseUrl: 'no-font-downloads/' },
});

// Once the app is on screen: the loading picture goes, and the page's files are kept so a bad connection, or none, still
// opens it next time (sw.js)
window.addEventListener('flutter-first-frame', () => {
  document.getElementById('splash')?.remove();
  if (!('serviceWorker' in navigator)) return;
  navigator.serviceWorker.register('sw.js').then(() => navigator.serviceWorker.ready).then(async () => {
    const cache = await caches.open('penko-cuentas-1');
    const files = performance.getEntriesByType('resource').map((r) => r.name).filter((u) => u.startsWith(location.origin));
    for (const url of [location.href, ...files]) await cache.add(url).catch(() => {});
  }).catch(() => {});
});
