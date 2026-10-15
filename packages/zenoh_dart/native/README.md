# Native binary layout

Android and iOS builds are stored per zenoh-c version. Desktop binaries are stored per architecture, from the zenoh-c 1.6.2 release archives.

```
native/
  android/
    <version>/                         # e.g. 1.6.2, 1.8.0
      arm64-v8a/libzenohc.so
      armeabi-v7a/libzenohc.so
      x86_64/libzenohc.so
      x86/libzenohc.so                 # only when built (not in the repo today)
  ios/
    <version>/zenohc.xcframework       # built on macOS; not in the repo today
  include/
    zenoh.h                            # ffigen entry point; includes ../windows/x64/msvc/include/zenoh.h
  linux/
    <arch>/                            # x86_64, aarch64, armv7
      zenoh-c-1.6.2-<target>-standalone.zip
      include/, lib/libzenohc.so       # extracted archive
      libzenoh.so                      # file the loader opens (present for x86_64 only)
  macos/
    <arch>/                            # x86_64, aarch64
      zenoh-c-1.6.2-<target>-standalone.zip
      include/, lib/libzenohc.dylib    # extracted archive; the loader wants libzenoh.dylib
  windows/
    x64/
      zenoh-c-1.6.2-x86_64-pc-windows-msvc-standalone.zip
      zenoh-c-1.6.2-x86_64-pc-windows-gnu-standalone.zip
      msvc/                            # extracted MSVC archive (bin/, include/, lib/)
        zenoh.dll                      # file the loader opens
```

## Android and iOS

Both are built from source by scripts at the repository root. Run them from the root:

| Step | Android | iOS (macOS with Xcode only) |
|---|---|---|
| Build a version | `bash .claude/skills/zenoh-build-android/build_zenoh_android.sh <version>` | `bash .claude/skills/zenoh-build-ios/build_zenoh_ios.sh <version>` |
| Output | `native/android/<version>/<abi>/libzenohc.so` | `native/ios/<version>/zenohc.xcframework` |
| Activate | `bash .claude/skills/zenoh-activate-libs/copy_zenoh_libs.sh <version>` | `bash .claude/skills/zenoh-activate-libs/copy_zenoh_libs.sh <version> ios` |
| Active copy | `android/app/src/main/jniLibs/<abi>/libzenoh.so` (app) | `packages/zenoh_dart/ios/Frameworks/zenohc.xcframework` |

`bash .claude/skills/zenoh-activate-libs/copy_zenoh_libs.sh <version> all` activates both. The Android copy is renamed to `libzenoh.so` because that is the name the loader opens. On iOS, `ios/zenoh_dart.podspec` vendors the active XCFramework. Nothing under `native/android/` or `native/ios/` is loaded directly.

See [docs/BUILD_ANDROID.md](../../../docs/BUILD_ANDROID.md) and [docs/BUILD_IOS.md](../../../docs/BUILD_IOS.md).

## Desktop

`tool/zenoh_binaries.json` lists one release archive per desktop target, with its URL, output path and SHA-256. To download them, run this from the package directory:

```
dart run tool/fetch_zenoh_binaries.dart
```

The script only downloads and verifies. Extract each archive next to it, then copy the library to the name the loader looks for in `native/<platform>/<arch>/`: `libzenoh.so` (Linux), `libzenoh.dylib` (macOS) or `zenoh.dll` (Windows; the loader also checks `msvc/` and `gnu/`). The Android and iOS entries in `tool/zenoh_binaries.json` have no URL (`TODO`), so the script skips them.

To compile desktop libraries from source instead, use the scripts in `tool/`: `build_macos_zenoh.sh`, `build_linux_zenoh.sh` and `build_windows_zenoh.ps1`. They build the CMake target `zenoh-ffi` from `ZENOH_SOURCE` (default `../zenoh`) and write `native/macos/libzenoh.dylib`, `native/linux/host/libzenoh.so` and `native/windows/x64/zenoh.dll`. The macOS and Linux outputs are not in an `<arch>` folder, so move them into one before the loader can find them.
