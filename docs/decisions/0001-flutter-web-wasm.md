# 0001. Flutter web, with WebAssembly and a JavaScript fallback

## Decision

The app targets Flutter web. `flutter build web --wasm` is the release command. Flutter 3.50 emits both `main.dart.wasm` and `main.dart.js`. The bootstrap keeps the WebAssembly build for Blink browsers that pass the WasmGC checks, and serves the JavaScript build to every other engine. We do not drop the JavaScript output.

## Why

The catalogue, layout, and interaction are all client-side. WebAssembly is the preferred runtime on browsers that support WasmGC. A JavaScript build remains necessary because that support is not universal, and because a static host must be able to serve either file.

## What was verified

On 19 November 2026, `flutter build web --wasm` completed with Flutter 3.50.0 and wrote both outputs under `build/web`. The Lucide font used for stage icons was tree-shaken into the build. The compiler warned that transitive icon data still names the Material and Cupertino families. Those widgets are not used by this app. The warning is recorded in `docs/deployment.md`.

Chrome 157 loaded the release build from a local server that sent `.wasm` as `application/wasm`. The default bootstrap requested `main.dart.wasm`, `main.dart.mjs`, and `skwasm.wasm`, and the page painted the six candidate roots, the stage header, the alternative group, the toolbar, and the minimap. At a width below 600px the Outline control was in the top bar. A forced JavaScript load (`wasmAllowList` with Blink set to false) requested `main.dart.js` and CanvasKit instead, and painted the same catalogue. It did not request `main.dart.wasm`.

Flutter 3.50's bootstrap only enables that WebAssembly build for Blink (`blink: true`, `gecko: false`, `webkit: false`). Firefox and Safari therefore receive `main.dart.js` unless a host changes `wasmAllowList`. Firefox is not installed on this machine, and Safari was not inspected, so those two remain a manual check in `docs/manual-checks.md`. `flutter drive` could not start because no WebDriver is listening on port 4444.

## Hosting consequence

The host must serve `.wasm` as `application/wasm`. Cross-origin isolation headers are not required for this single-threaded build.
