# Deployment

`flutter build web --wasm` writes `build/web`. That output contains both `main.dart.wasm` and `main.dart.js`. Flutter 3.50's bootstrap uses WebAssembly on Blink browsers that support WasmGC, and the JavaScript build on Firefox, Safari, and any other engine. Shipping only one of the two files will fail on browsers that need the other.

The build was produced with Flutter 3.50.0. It completed, and the Lucide icon font used by the stage markers was included. The compiler also warned that some transitive icon data still names the Material and Cupertino font families. This app does not draw Material widgets. If a control ever shows an empty icon, turn `uses-material-design` on so that font is bundled, and rebuild.

## Hosting

The site is static. GitHub Pages, Cloudflare Pages, or any host that can serve the `build/web` directory is enough. There is no server and no API key.

- Serve `.wasm` as `application/wasm`. Some hosts default to `application/octet-stream`, and the WebAssembly compile then fails while the JavaScript fallback may still start.
- Cache `flutter_bootstrap.js` briefly. The hashed canvaskit and wasm files can be cached for a long time.
- Cross-origin isolation (`Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp`) is only required if multi-threaded rendering is turned on. This build does not enable it. Do not add those headers unless you have also checked that the font and canvaskit files are allowed through them.

## Browser check

Chrome 157 was checked on 19 November 2026. The default load used `main.dart.wasm`. Forcing the JavaScript build, by disabling Blink in `wasmAllowList`, used `main.dart.js` and painted the same tree. The details are in `docs/decisions/0001-flutter-web-wasm.md`.

Firefox and Safari still need a person. The bootstrap sends them the JavaScript build by default. Open the built site, confirm the Kente root is visible, and note which file the network panel requested.
