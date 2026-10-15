---
name: zenoh-build-ios
description: Build the zenoh-c native library for iOS as zenohc.xcframework (device and simulator slices, each a dynamic zenohc.framework) and store it in this repo's versioned folders under packages/zenoh_dart/native/ios/. Use this whenever the user wants to build zenoh for iOS, make or update the zenoh xcframework, rebuild zenohc.framework, bump the zenoh-c version for iOS, or fix a missing zenohc framework in the iOS app, even if they don't name the script. Requires macOS with Xcode. Not for Android (use zenoh-build-android).
---

# Build zenoh-c for iOS

**macOS with Xcode only.** The script needs `xcodebuild`, `lipo`, `install_name_tool`, `codesign` and `plutil`, and anywhere else it exits immediately with `Error: iOS builds require macOS with Xcode`. On Linux, don't hunt for workarounds. Tell the user that this step has to run on a Mac; the Android build does work on Linux.

`build_zenoh_ios.sh` in this folder works in five steps:

1. Clone zenoh-c into `zenoh_c_build/` (git-ignored, shared with the Android build) and check out a tag.
2. Build the Rust cdylib for `aarch64-apple-ios`, `aarch64-apple-ios-sim` and `x86_64-apple-ios`.
3. Merge the two simulator dylibs with `lipo`.
4. Wrap each slice as `zenohc.framework`: install name `@rpath/zenohc.framework/zenohc`, an Info.plist, the headers and an ad-hoc signature.
5. Package both slices with `xcodebuild -create-xcframework`.

`docs/BUILD_IOS.md` has the background and the manual equivalent.

## Prerequisites

- Xcode plus its command line tools: `xcode-select --install`, `sudo xcode-select -s /Applications/Xcode.app`, `sudo xcodebuild -license accept`.
- Rust via rustup (https://rustup.rs). Each zenoh-c release pins its compiler in `rust-toolchain.toml`. The script adds the iOS targets from inside the checkout, so they land in that toolchain.
- CocoaPods (`sudo gem install cocoapods` or `brew install cocoapods`), which Flutter uses to link the plugin.

## Run it

From the repo root:

```bash
bash .claude/skills/zenoh-build-ios/build_zenoh_ios.sh 1.8.0     # or: bash .claude/skills/zenoh-build-ios/build_zenoh_ios.sh 1.8.0
```

If the user did not name a version, show what exists (`ls packages/zenoh_dart/native/ios/`) and the upstream tags (`git -C zenoh_c_build tag --sort=-v:refname | head`). Confirm the tag before building. Tags have no `v` prefix. Each target is a full zenoh compile that takes several minutes, so start the build as a background command and wait for it.

| Variable | Default | Meaning |
|---|---|---|
| `SKIP_X86_64_SIM` | `0` | `1` skips the Intel simulator slice. Faster, but the simulator build then only runs on Apple Silicon Macs |
| `IOS_MIN_VERSION` | `13.0` | Deployment target. Matches `ios/Runner.xcodeproj` and the podspec's `platform :ios, '13.0'` |
| `ZENOH_C_SRC` | `<repo>/zenoh_c_build` | zenoh-c checkout |
| `FRAMEWORK_ID` | `org.eclipse.zenoh.zenohc` | `CFBundleIdentifier` in the framework's Info.plist |

## Output, activation and how the app loads it

```
packages/zenoh_dart/native/ios/<VERSION>/zenohc.xcframework/
  Info.plist
  ios-arm64/zenohc.framework/                    # iPhone / iPad
  ios-arm64_x86_64-simulator/zenohc.framework/   # simulator (ios-arm64-simulator with SKIP_X86_64_SIM=1)
```

Activate the version, then refresh CocoaPods:

```bash
bash .claude/skills/zenoh-activate-libs/copy_zenoh_libs.sh 1.8.0 ios      # -> packages/zenoh_dart/ios/Frameworks/zenohc.xcframework
cd ios && pod install && cd ..
```

`packages/zenoh_dart/ios/zenoh_dart.podspec` vendors `Frameworks/zenohc.xcframework`, and CocoaPods embeds and re-signs it in the Runner app. At runtime, `packages/zenoh_dart/lib/src/bindings/native_library.dart` opens `zenohc.framework/zenohc` and falls back to `DynamicLibrary.process()`. Keep the framework and its binary named `zenohc` (install name `@rpath/zenohc.framework/zenohc`), or that lookup fails.

## Verify

```bash
XC=packages/zenoh_dart/native/ios/1.8.0/zenohc.xcframework
find "$XC" -maxdepth 2                                       # Info.plist, ios-arm64/, ios-arm64_x86_64-simulator/
otool -D "$XC/ios-arm64/zenohc.framework/zenohc"             # @rpath/zenohc.framework/zenohc
lipo -info "$XC"/ios-*-simulator/zenohc.framework/zenohc     # x86_64 arm64 (just arm64 with SKIP_X86_64_SIM=1)
flutter build ios --no-codesign                              # after copy_zenoh_libs.sh and pod install
```

## Common failures

- **Xcode not selected** (`linking with cc failed` mentioning `-isysroot`, or `xcrun: error`): run `sudo xcode-select -s /Applications/Xcode.app`.
- **`install_name_tool: ... larger updated load commands do not fit`**: the dylib has no spare header padding. The script appends `-C link-arg=-Wl,-headerpad_max_install_names` to `RUSTFLAGS`, but a `CARGO_ENCODED_RUSTFLAGS` in the environment overrides that. Unset it and rebuild.
- **Missing rustup target** (`can't find crate for core` or `target may not be installed`): run `rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios` inside `zenoh_c_build/`, where `rust-toolchain.toml` selects the pinned toolchain. Targets added from any other directory go to the wrong toolchain.
- **Intel vs Apple Silicon simulator** (linker errors about the simulator architecture, or missing `x86_64` symbols): Intel Macs, and Xcode under Rosetta, need the x86_64 slice, so rebuild without `SKIP_X86_64_SIM=1`. Apple Silicon simulators use the `aarch64-apple-ios-sim` slice, never the device slice.
- **Code signing on embed**: the framework ships ad-hoc signed and is re-signed in the `[CP] Embed Pods Frameworks` phase, so device builds need a development team set on the Runner target. If the error is `resource fork, Finder information, or similar detritus not allowed`, run `xattr -cr packages/zenoh_dart/ios/Frameworks/zenohc.xcframework` and rebuild.
- **`dlopen ... zenohc.framework/zenohc ... image not found` at runtime**: the framework was not embedded. Check that `packages/zenoh_dart/ios/Frameworks/zenohc.xcframework` exists, re-run `pod install`, and try `flutter clean`.

## Notes

- The Dart FFI bindings were generated from the zenoh-c 1.6.2 headers. `zenoh_client_native.dart` pads some opaque struct allocations (`_opaqueSlackBytes`) so that 1.8.0 fits. A newer zenoh-c may need regenerated bindings (`packages/zenoh_dart/ffigen.yaml`); the zenoh-build-android skill explains the check.
- iOS blocks multicast scouting without the `com.apple.developer.networking.multicast` entitlement, and asks for Local Network permission. See `docs/MULTICAST.md`, plus `docs/BUILD_IOS.md` for the full build background.
