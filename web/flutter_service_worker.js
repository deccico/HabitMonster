// Self-destructing service worker.
//
// The app used to ship Flutter's generated service worker, whose cache-first
// strategy kept users one deploy behind. Builds now use --pwa-strategy=none,
// but browsers that registered the old worker would keep serving stale files
// from its cache forever. Publishing this file at the same URL replaces the
// old worker on its next update check: it unregisters itself, wipes every
// cache, and reloads open tabs so they fetch the live version.
self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    await self.registration.unregister();
    const keys = await caches.keys();
    await Promise.all(keys.map((key) => caches.delete(key)));
    const clients = await self.clients.matchAll({ type: 'window' });
    await Promise.all(clients.map((client) => client.navigate(client.url)));
  })());
});
