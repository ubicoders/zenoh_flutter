## 0.2.1

### Features
- `ZenohConfig` takes `connectEndpoints`, `listenEndpoints` and `multicastScouting`. `toJson()` always emits `mode`, and emits the zenoh keys `connect/endpoints`, `listen/endpoints` and `scouting/multicast/enabled` only when the matching option is set, so anything left unset keeps the zenoh default. Duplicate endpoints are dropped and order is kept.
- `ZenohConfig.locator` is deprecated in favour of `connectEndpoints`. When it is given, it becomes the first connect endpoint.
- `ZenohSample.encoding` (`String?`): the sample's zenoh encoding as returned by zenoh-c `z_encoding_to_string`, for example `text/plain`, `application/json` or `zenoh/bytes`, possibly with a `;schema` suffix. The native client fills it in; it is null when the encoding cannot be read.
- iOS support. `ios/zenoh_dart.podspec` vendors `ios/Frameworks/zenohc.xcframework`, a dynamic framework built from the zenoh-c Rust `cdylib` (`bash .claude/skills/zenoh-build-ios/build_zenoh_ios.sh <version>` in the app repository, activated with `bash .claude/skills/zenoh-activate-libs/copy_zenoh_libs.sh <version> ios`). Minimum iOS version 13.0. On iOS, the library loader and the subscriber polling isolate open `zenohc.framework/zenohc` and fall back to `DynamicLibrary.process()`.

### Fixes
- Fixed a native heap corruption crash when a subscriber was undeclared while samples were flowing. Teardown now runs in this order: drop the subscriber, which disconnects its FIFO channel; wait for the polling isolate to leave `z_fifo_handler_sample_recv` (up to 2 s); then drop the FIFO handler. If the isolate does not exit in time, the handler is leaked and a message is printed, to avoid a use-after-free.
- `undeclareSubscriber` and `close` are idempotent. A second `undeclareSubscriber`, or one after `close`, does nothing. Every `close` call returns the same future, and `close` undeclares any remaining subscribers before closing the session. `isClosed` becomes true as soon as `close` is called.
- `declarePublisher` and the publish methods throw `StateError` on a closed client. `subscribe` throws `StateError` if `close` runs while it is starting the polling isolate.
- `z_owned_subscriber_t`, `z_owned_publisher_t` and `z_owned_config_t` are allocated with 256 spare bytes. The ffigen bindings were generated from the zenoh-c 1.6.2 headers, but the zenoh-c 1.8.0 Android library (`native/android/1.8.0/`) uses larger structs on 64-bit targets (56 vs 48, 120 vs 112 and 2008 vs 1984 bytes). Allocating the 1.6.2 size let zenoh-c write past the end of the allocation. Regenerating the bindings from the 1.8.0 headers is still to do; see `doc/platform_support.md`.

## 0.2.0

### Breaking Changes
- **Type System Update**: `ZenohPublisher` and `ZenohSubscriber` now use nullable pointers (`Pointer<T>?`) to support both native FFI and web platforms
- **Platform Abstraction**: Direct usage of internal types may require updates to accommodate the new platform-agnostic architecture

### Features
- **WASM/Web Platform Support**: Added comprehensive web platform compatibility
  - Created `ZenohClientInterface` for platform-agnostic API design
  - Implemented platform-specific facades: `ZenohClientNative` (FFI) and `ZenohClientWeb` (JS interop stub)
  - Automatic platform selection via conditional imports (`dart.library.js_interop`)
  - Added `webHandle` field to types for future JavaScript integration
- **Documentation**: Added comprehensive guides for web platform implementation (`doc/web_platform_support.md`)
- **Architecture**: Zero-cost abstraction with compile-time platform selection

### Improvements
- Fixed zenoh-ts library URL reference to use correct distribution file (`index.js`)
- Enhanced type safety with nullable pointer pattern
- Improved cross-platform code organization and maintainability

### Migration Guide
If you're using `ZenohPublisher` or `ZenohSubscriber` directly:
```dart
// Before
final handle = publisher.pointer.address;

// After
final handle = publisher.handle; // Uses getter that handles null safety
```

## 0.1.0-dev.0

### Platform Architecture
- **WASM/Web compatibility**: Refactored for multi-platform support
  - Created `ZenohClientInterface` for platform-agnostic API
  - Separated native implementation into `ZenohClientNative` (FFI-based)
  - Added `ZenohClientWeb` stub for future zenoh-ts integration
  - Automatic platform selection via conditional imports
  - Updated types to support both native pointers and web handles

### Features
- Initial project scaffold with platform-aware FFI bindings.
- Added high-level subscriber support with Dart callbacks and stream delivery.
- Expanded example app to exercise publisher/subscriber loopback messaging.
- Documented end-to-end publish/subscribe flow in README.
- Added convenience helpers for string payloads (`ZenohClient.publishString`,
  `ZenohSample.payloadAsString`).

### Known Limitations
- Web platform requires zenoh-ts library (not yet fully integrated)
- Android/iOS binaries not included (build scripts provided)
