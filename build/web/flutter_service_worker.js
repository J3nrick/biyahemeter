'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "a3b9a6b07d406c7a966e059ef44d6e46",
"assets/AssetManifest.bin.json": "78dcc1660330fa578c8fe59f6c1be546",
"assets/assets/images/logo.png": "d455d6aae1a8d0bfaab4df7468b19081",
"assets/assets/images/logo_dark_hd.png": "649662177b95c6a6eb8021b282f7fad1",
"assets/assets/images/logo_light_hd.png": "7352836f6d767d1ca9d0ac6b6e5609aa",
"assets/FontManifest.json": "c75f7af11fb9919e042ad2ee704db319",
"assets/fonts/MaterialIcons-Regular.otf": "00bcc9ed37f33605e8534b30655c250a",
"assets/NOTICES": "642c08980648b7a0b0f8b5ad14db0cb2",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "e389af1c4ae501cb0f1c561978678332",
"assets/packages/flutter_local_notifications_web/web/notifications_service_worker.js": "087634de8a8c1c49d00bcd212bf7feb4",
"assets/packages/flutter_map/lib/assets/flutter_map_logo.png": "208d63cc917af9713fc9572bd5c09362",
"assets/packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Brands-Regular-400.otf": "706b13a761d261d759c0a8d557ccfdcb",
"assets/packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Free-Regular-400.otf": "46be639d952abe98effde36da35e7701",
"assets/packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Free-Solid-900.otf": "4c9af3c794ee063a264dc907eaed85a7",
"assets/packages/wakelock_plus/assets/no_sleep.js": "74499cf34f37daae14b51e3a23cd9f7a",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"canvaskit/webparagraph/canvaskit.js": "5e5e4fb27c4333aa2924e9dcd2f66333",
"canvaskit/webparagraph/canvaskit.js.symbols": "4ad59e119a5de2977a4f7538062f47ef",
"canvaskit/webparagraph/canvaskit.wasm": "8cecf3b9c2e8270502de9138a21d4e8f",
"canvaskit/wimp.js": "6d8714f96a4bdb92e43e85467ef7451c",
"canvaskit/wimp.js.symbols": "c6d1920b3b6714201ef8c901ec8b8e38",
"canvaskit/wimp.wasm": "9173d3df97ed517649085f35f64592bf",
"favicon.png": "838df50ddef1d42cdb7873d99b3bda89",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"flutter_bootstrap.js": "746e904462bdfe0d5e0d2b1f67b7bfe1",
"icons/Icon-192.png": "6f6f86adc93d9f5e7f2d1106f954c3c7",
"icons/Icon-512.png": "838df50ddef1d42cdb7873d99b3bda89",
"icons/Icon-maskable-192.png": "6f6f86adc93d9f5e7f2d1106f954c3c7",
"icons/Icon-maskable-512.png": "838df50ddef1d42cdb7873d99b3bda89",
"index.html": "7bbf7e6ec2e9ef392f21744f59ec0bf2",
"/": "7bbf7e6ec2e9ef392f21744f59ec0bf2",
"logo.png": "d455d6aae1a8d0bfaab4df7468b19081",
"logo_dark_hd.png": "649662177b95c6a6eb8021b282f7fad1",
"logo_light_hd.png": "7352836f6d767d1ca9d0ac6b6e5609aa",
"main.dart.js": "7de0ae148a3b23ac3515a9fab8125c33",
"manifest.json": "310bdbe353b66d9e753796dd27ae0ba0",
"splash/img/dark-1x.png": "ef8d4b0494de6f0caf59973c28c08129",
"splash/img/dark-2x.png": "5d5eff61e11ae1b78a0e9c8d219b3deb",
"splash/img/dark-3x.png": "c8af339c90baadac8663a2ebe40981dc",
"splash/img/dark-4x.png": "90746ef94031450b110ef11235db152c",
"splash/img/light-1x.png": "ef8d4b0494de6f0caf59973c28c08129",
"splash/img/light-2x.png": "5d5eff61e11ae1b78a0e9c8d219b3deb",
"splash/img/light-3x.png": "c8af339c90baadac8663a2ebe40981dc",
"splash/img/light-4x.png": "90746ef94031450b110ef11235db152c",
"version.json": "5ce66596ca3b3f42dc177430f7d79a42"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
