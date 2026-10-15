# zenoh_dart

Dart and Flutter FFI bindings for [Eclipse Zenoh](https://zenoh.io), prepared by M-PIA. This package exposes Zenoh's core APIs to Flutter apps across Android, iOS, macOS, Windows, Linux, and Web (experimental).

## Project goals

- Ship prebuilt Zenoh native libraries for each supported platform and architecture.
- Offer idiomatic Dart wrappers for sessions, publishers, subscribers, and queries.
- Provide ready-to-run examples for ROS 2 bridge scenarios.
- Publish the package on pub.dev under the M-PIA banner.

## Getting started

1. Install the Dart and Flutter SDKs (`>= 3.4.0` / `>= 3.24.0`).
2. Add the dependency once the package is published:

   ```bash
   flutter pub add zenoh_dart
   ```

   In the zenoh_flutter repository the app uses it as a path dependency (`path: packages/zenoh_dart`).

3. Open a session and use Zenoh resources:

   ```dart
   final client = await ZenohClient.connect(
     ZenohConfig(
       mode: ZenohMode.client,
       connectEndpoints: ['tcp/127.0.0.1:7447'],
     ),
   );

   final publisher = await client.declarePublisher('demo/example');
   final subscriber = await client.subscribe('demo/example');

   final sub = subscriber.stream.listen((sample) {
     // sample.encoding is the zenoh encoding string (e.g. 'text/plain'), or null.
     debugPrint('received ${sample.keyExpr} [${sample.encoding}]: '
         '${sample.payloadAsString()}');
   });

   await client.publishString(publisher, 'Hello Zenoh!');

   await sub.cancel();
   await client.undeclareSubscriber(subscriber);
   await client.undeclarePublisher(publisher);
   await client.close();
   ```

## Configuration

`ZenohConfig` is turned into zenoh's JSON configuration and passed to `zc_config_from_str`. `mode` is always written; the other keys are written only when you set them, so anything left unset keeps the zenoh default.

| Field | zenoh key | Example |
|---|---|---|
| `mode` (default `ZenohMode.peer`) | `mode` | `ZenohMode.client` |
| `connectEndpoints` | `connect/endpoints` | `['tcp/10.0.2.2:7447']` |
| `listenEndpoints` | `listen/endpoints` | `['tcp/0.0.0.0:7447', 'ws/0.0.0.0:8000']` |
| `multicastScouting` (`bool?`) | `scouting/multicast/enabled` | `false` |
| `locator` (deprecated) | added as the first connect endpoint | `'tcp/localhost:7447'` |

Duplicate endpoints are dropped. For example:

```dart
final config = ZenohConfig(
  mode: ZenohMode.router,
  listenEndpoints: ['tcp/0.0.0.0:7447', 'udp/0.0.0.0:7447'],
  multicastScouting: false,
);
// config.toJson() ==
// {'mode': 'router',
//  'listen': {'endpoints': ['tcp/0.0.0.0:7447', 'udp/0.0.0.0:7447']},
//  'scouting': {'multicast': {'enabled': false}}}
```

## Samples and lifecycle

- `ZenohSample` has `keyExpr`, `payload` (`Uint8List`), `encoding` and `payloadAsString()`. `encoding` is the string from zenoh-c `z_encoding_to_string`, such as `text/plain`, `application/json` or `zenoh/bytes`, possibly with a `;schema` suffix. It is null when the encoding cannot be read. `publishString` and `publishBytes` do not set an encoding.
- Each subscriber has a background isolate that receives samples from a zenoh FIFO channel and feeds `subscriber.stream`.
- `undeclareSubscriber` and `close` are idempotent. `close` undeclares any remaining subscribers, then closes the session; await it before you drop the client.
- `undeclarePublisher` frees the publisher, so call it once per publisher.
- Publishing an empty payload throws `ArgumentError`. Declaring a publisher, subscribing or publishing on a closed client throws `StateError`.

## Native binaries

### Android and iOS

Android and iOS libraries are built from source with the scripts at the root of the zenoh_flutter repository. Each version gets its own folder under `native/`:

- Android, see [docs/BUILD_ANDROID.md](../../docs/BUILD_ANDROID.md): `bash .claude/skills/zenoh-build-android/build_zenoh_android.sh <version>` (or the manual `cargo ndk` steps) writes `native/android/<version>/<abi>/libzenohc.so`. `bash .claude/skills/zenoh-activate-libs/copy_zenoh_libs.sh <version>` copies it into the app as `android/app/src/main/jniLibs/<abi>/libzenoh.so`, the name the loader opens.
- iOS, see [docs/BUILD_IOS.md](../../docs/BUILD_IOS.md): `bash .claude/skills/zenoh-build-ios/build_zenoh_ios.sh <version>` (macOS with Xcode) writes `native/ios/<version>/zenohc.xcframework`. `bash .claude/skills/zenoh-activate-libs/copy_zenoh_libs.sh <version> ios` copies it to `ios/Frameworks/zenohc.xcframework`, which `ios/zenoh_dart.podspec` vendors into the app.

### Desktop

Run the fetch script from this package's directory:

```bash
dart run tool/fetch_zenoh_binaries.dart
```

It downloads the zenoh-c 1.6.2 standalone archives listed in `tool/zenoh_binaries.json` from the [Zenoh C releases](https://github.com/eclipse-zenoh/zenoh-c/releases) and verifies their SHA-256 checksums. It does not extract them, and it skips the Android and iOS entries, which have no URL. Extract each archive and copy the library to the file the loader looks for: `native/linux/<arch>/libzenoh.so`, `native/macos/<arch>/libzenoh.dylib` or `native/windows/x64/zenoh.dll` (on Windows the loader also looks in the `msvc/` and `gnu/` subfolders). See [native/README.md](native/README.md).

### Platform status

- **Android**: zenoh-c 1.6.2 and 1.8.0 for `arm64-v8a`, `armeabi-v7a` and `x86_64` in `native/android/`. The build script and the manual steps also build `x86`.
- **iOS**: device (`arm64`) and simulator (`arm64`, `x86_64`) slices in one XCFramework, built on macOS. No iOS build is checked in yet.
- **macOS** (`x86_64`, `aarch64`), **Linux** (`x86_64`, `aarch64`, `armv7`) and **Windows** (`x64`, MSVC and GNU): zenoh-c 1.6.2 standalone archives.
- **Web**: stub only. `ZenohClientWeb` throws `UnimplementedError` until zenoh-ts is integrated. See `doc/web_platform_support.md`.

## Generating bindings

`ffigen.yaml` reads `native/include/zenoh.h`. That file only includes `../windows/x64/msvc/include/zenoh.h`, the zenoh-c 1.6.2 headers from the Windows MSVC archive. Regenerate the bindings with:

```bash
dart run ffigen
```

The command writes `lib/src/bindings/zenoh_generated.dart`. `ffigen.yaml` sets `llvm-path` to a Windows LLVM under `build/llvm/`, so change it to match your machine.

The bindings in the repository come from the 1.6.2 headers, but the app ships zenoh-c 1.8.0 on Android. `doc/platform_support.md` explains the workaround and how to regenerate.

## Platform support

See `doc/platform_support.md` for detailed build requirements and instructions.

## Licensing

This project adopts the Apache License 2.0 with an explicit NOTICE file referencing M-PIA. See `LICENSE` and `NOTICE` for details.
