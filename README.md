# Thesis Topic Explorer

A client-side workspace for reading, comparing, and tracing evidence across MPhil thesis directions. The catalogue is local JSON. The app does not score topics or invent citations.

## Run

```bash
flutter pub get
flutter run -d chrome
```

## Test and build

```bash
flutter test
flutter build web --wasm
```

`flutter test` covers validation, layout, bloc transitions, search, comparison labels, and a widget pass over the seeded catalogue. Browser checks that need a person are listed in [docs/manual-checks.md](docs/manual-checks.md). The WebAssembly build also emits a JavaScript fallback. Hosting notes are in [docs/deployment.md](docs/deployment.md).

An integration test lives in `integration_test/explorer_test.dart`. `flutter test` cannot target a browser for this package, so drive it. Chrome needs a WebDriver listening on port 4444 (`chromedriver --port=4444`):

```bash
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/explorer_test.dart -d chrome --wasm --no-start-paused
```

## Read next

- [docs/architecture.md](docs/architecture.md)
- [docs/content-authoring-guide.md](docs/content-authoring-guide.md)
- [docs/research-evidence-policy.md](docs/research-evidence-policy.md)
- [docs/decisions/](docs/decisions/)
