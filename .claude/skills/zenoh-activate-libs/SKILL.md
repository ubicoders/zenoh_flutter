---
name: zenoh-activate-libs
description: Activate one built zenoh-c version for the Flutter app by copying it from packages/zenoh_dart/native/<platform>/<version>/ into the place the app bundles from (android/app/src/main/jniLibs for Android, packages/zenoh_dart/ios/Frameworks/zenohc.xcframework for iOS). Use this whenever the user wants to switch, select, activate or deploy a zenoh version, update jniLibs, refresh libzenoh.so in the app, or vendor a new zenohc.xcframework, even if they don't name the script. Build first with zenoh-build-android or zenoh-build-ios.
---

# Activate a built zenoh-c version

`copy_zenoh_libs.sh` in this folder copies a version that was already built by
`zenoh-build-android` or `zenoh-build-ios` into the location the app actually
bundles. It never builds anything.

## Run

From anywhere (the script resolves the repository root itself):

```bash
bash .claude/skills/zenoh-activate-libs/copy_zenoh_libs.sh <version>          # Android (default)
bash .claude/skills/zenoh-activate-libs/copy_zenoh_libs.sh <version> ios      # iOS
bash .claude/skills/zenoh-activate-libs/copy_zenoh_libs.sh <version> all      # both
```

With no arguments it lists the versions available under
`packages/zenoh_dart/native/android/` and `native/ios/`.

## What it does

| Platform | Source | Destination |
|---|---|---|
| android | `packages/zenoh_dart/native/android/<version>/<abi>/libzenohc.so` | `android/app/src/main/jniLibs/<abi>/libzenoh.so` |
| ios | `packages/zenoh_dart/native/ios/<version>/zenohc.xcframework` | `packages/zenoh_dart/ios/Frameworks/zenohc.xcframework` |

- Android ABIs handled: `arm64-v8a`, `armeabi-v7a`, `x86`, `x86_64`. A missing
  ABI prints a warning and is skipped. The rename to `libzenoh.so` is required
  because `zenoh_dart` opens that name at runtime.
- iOS replaces the vendored XCFramework in place. The podspec in
  `packages/zenoh_dart/ios/` vendors that path, so run `cd ios && pod install`
  (or `flutter clean`) afterwards so CocoaPods picks up the new binary.

## After activating

```bash
flutter run -d emulator-5554        # Android
flutter build ios --no-codesign     # iOS, on macOS
```

Both destinations are tracked in git, so a new activation shows up as a diff of
binary files. Commit it together with the versioned build it came from.

## Failure modes

- `Android version X not found`: nothing built for that version. Run the
  `zenoh-build-android` skill first.
- `iOS version X not found`: same, run `zenoh-build-ios` on macOS.
- The app still loads the old library on Android: `flutter clean`, since
  Gradle caches `jniLibs`.
- Native crash after switching to a newer zenoh-c: the Dart bindings were
  generated from 1.6.2 headers and only three structs are padded for 1.8.0.
  See `packages/zenoh_dart/doc/platform_support.md`.

Related: `docs/BUILD_ANDROID.md`, `docs/BUILD_IOS.md`.
