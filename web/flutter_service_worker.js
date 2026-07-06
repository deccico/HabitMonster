// Network-first service worker: offline support without deploy staleness.
//
// Online, every request goes to the network (so, combined with the no-cache
// hosting headers, deploys are picked up immediately — same behavior as no
// worker at all); successful responses are mirrored into the cache as they
// pass through. Offline, the cache serves the last-seen version of the app.
//
// Ships at the URL Flutter's old cache-first worker (and the v0.0.6
// self-destruct worker) used, so existing registrations update to this one.
// Builds run with --pwa-strategy=none, which writes an EMPTY file at this
// path; the release script copies this file over it after every build.

const CACHE_NAME = 'tm-offline-v1';

// The app shell must be pre-cached at install: on a first visit the page's
// own requests happen before this worker controls the page, so runtime
// caching alone would leave offline broken until a second online visit.
// The placeholder below is replaced by scripts/release.sh with the actual
// list of files in build/web (fallback list keeps a non-injected build,
// e.g. local dev, mostly working).
const PRECACHE = /*__PRECACHE__*/ [
  './',
  'main.dart.js',
  'flutter_bootstrap.js',
  'assets/assets/audio/evolve.wav',
  'assets/assets/audio/alarm.wav',
];

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE_NAME);
    // Best-effort: a failed precache must not block installation.
    await Promise.allSettled(PRECACHE.map((url) => cache.add(url)));
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    // Drop caches left behind by the original Flutter worker.
    const keys = await caches.keys();
    await Promise.all(
      keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key)),
    );
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;
  // version.json is polled with unique ?ts= queries (would bloat the cache),
  // and serving a stale copy offline could pop a pointless update prompt.
  // Let it hit the network and fail offline — the app ignores that failure.
  if (url.pathname.endsWith('/version.json')) return;

  event.respondWith((async () => {
    try {
      const response = await fetch(request);
      if (response.ok) {
        const cache = await caches.open(CACHE_NAME);
        cache.put(request, response.clone());
      }
      return response;
    } catch (error) {
      const cached = await caches.match(request, { ignoreSearch: true });
      if (cached) return cached;
      if (request.mode === 'navigate') {
        // Navigations are cached under whatever URL was visited (usually
        // the root), so try both shell keys.
        const shell =
          (await caches.match('./', { ignoreSearch: true })) ||
          (await caches.match('index.html', { ignoreSearch: true }));
        if (shell) return shell;
      }
      throw error;
    }
  })());
});
