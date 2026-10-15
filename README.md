# zenoh_flutter

A Flutter app that subscribes to a Zenoh router over TCP/UDP/WS using the local `zenoh_dart` FFI package (`packages/zenoh_dart`).

## Native Zenoh libraries

The app bundles prebuilt `zenoh-c` binaries. They are built per version and stored under `packages/zenoh_dart/native/<platform>/<version>/`, then one version is activated for the app with the helper script at the project root:

```bash
./copy_zenoh_libs.sh <version>          # Android (default)
./copy_zenoh_libs.sh <version> ios      # iOS
./copy_zenoh_libs.sh <version> all      # both
```

Platform-specific build instructions:

- [docs/BUILD_ANDROID.md](docs/BUILD_ANDROID.md) – build `libzenohc.so` with `cargo ndk` (Linux or macOS) and copy it into `android/app/src/main/jniLibs/`.
- [docs/BUILD_IOS.md](docs/BUILD_IOS.md) – build `zenohc.xcframework` with `./build_zenoh_ios.sh <version>` (macOS + Xcode only) and vendor it through `packages/zenoh_dart/ios/zenoh_dart.podspec`.

## Running

```bash
flutter pub get
flutter run -d <device>
```

A Zenoh router must be reachable from the device. It runs standalone, outside this repo, listening on `tcp/7447`, `udp/7447` and `ws/8000`. The app defaults to `10.0.2.2:7447` on the Android emulator and `127.0.0.1:7447` elsewhere; change the host in the UI to the router's LAN address for a physical phone.
