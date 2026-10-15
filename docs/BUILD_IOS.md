# Building Zenoh C for iOS (Versioned)

This mirrors the Android flow in [BUILD_ANDROID.md](BUILD_ANDROID.md): build a specific `zenoh-c` version from source, store the result under `packages/zenoh_dart/native/ios/<VERSION>/`, then activate one version for the app with `copy_zenoh_libs.sh`.

**Requires macOS with Xcode.** Apple's toolchain (`xcodebuild`, `lipo`, `install_name_tool`, `codesign`) cannot run on Linux, so this step must be done on a Mac. The Android build can still be done on Linux.

## What gets produced

Android ships bare `libzenoh.so` files in `jniLibs`. iOS does not allow bare `.dylib` files in an app, so the Rust `cdylib` is wrapped in a dynamic framework bundle and both slices (device + simulator) are packaged in an XCFramework:

```
packages/zenoh_dart/native/ios/<VERSION>/zenohc.xcframework/
  ios-arm64/zenohc.framework/                 # iPhone / iPad
  ios-arm64_x86_64-simulator/zenohc.framework/ # Simulator (Apple Silicon + Intel)
```

With `SKIP_X86_64_SIM=1` the simulator slice is `ios-arm64-simulator` (Apple Silicon only).

The active version is copied to `packages/zenoh_dart/ios/Frameworks/zenohc.xcframework`, which `packages/zenoh_dart/ios/zenoh_dart.podspec` vendors into the Runner app. CocoaPods embeds and code-signs it automatically.

## 1. Prerequisites
- **Xcode** with command line tools (`xcode-select --install`), and accept the license once (`sudo xcodebuild -license accept`).
- **Rust & Cargo**: (`curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`)
- **CocoaPods**: `sudo gem install cocoapods` (Flutter uses it to link the plugin).

## 2. Prepare the Rust Environment
```bash
rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios
```
(`x86_64-apple-ios` is only needed for the simulator on Intel Macs.) The build script adds these targets for you. It runs `rustup` inside the `zenoh-c` checkout, so the targets go into the Rust toolchain that zenoh-c pins in its `rust-toolchain.toml`. If you build by hand, run the command inside `zenoh_c_build` after the checkout, as in the manual equivalent below.

## 3. Build a Specific Version (e.g. 1.6.2 or 1.8.0)
From the project root:
```bash
bash .claude/skills/zenoh-build-ios/build_zenoh_ios.sh 1.6.2
```

`bash .claude/skills/zenoh-build-ios/build_zenoh_ios.sh` forwards to `.claude/skills/zenoh-build-ios/build_zenoh_ios.sh`, the script of the `zenoh-build-ios` Claude Code skill. It stops with an error on anything other than macOS, or when one of `cargo`, `rustup`, `xcrun`, `xcodebuild`, `lipo`, `install_name_tool`, `codesign` or `plutil` is missing. Then it:
1. Clones `zenoh-c` into `zenoh_c_build/` (git-ignored, shared with the Android build) if it is not there yet, then checks out the `1.6.2` tag.
2. Runs `cargo build --release --target <t>` for `aarch64-apple-ios`, `aarch64-apple-ios-sim` and `x86_64-apple-ios`, with `IPHONEOS_DEPLOYMENT_TARGET=13.0` to match `ios/Runner.xcodeproj`, and with `-headerpad_max_install_names` added to `RUSTFLAGS`.
3. Merges the two simulator dylibs with `lipo`.
4. Wraps each dylib as `zenohc.framework` (sets the install name to `@rpath/zenohc.framework/zenohc`, writes an `Info.plist`, copies the `zenoh-c` headers, ad-hoc signs).
5. Runs `xcodebuild -create-xcframework` and writes `packages/zenoh_dart/native/ios/1.6.2/zenohc.xcframework`.

Useful overrides:
```bash
SKIP_X86_64_SIM=1 bash .claude/skills/zenoh-build-ios/build_zenoh_ios.sh 1.8.0     # Apple Silicon simulator only, faster
IOS_MIN_VERSION=13.0 bash .claude/skills/zenoh-build-ios/build_zenoh_ios.sh 1.8.0  # deployment target
ZENOH_C_SRC=/path/to/zenoh-c bash .claude/skills/zenoh-build-ios/build_zenoh_ios.sh 1.8.0
FRAMEWORK_ID=org.eclipse.zenoh.zenohc bash .claude/skills/zenoh-build-ios/build_zenoh_ios.sh 1.8.0  # CFBundleIdentifier of the framework (this is the default)
```

### Manual equivalent
If you prefer to do it by hand, the core commands are:
```bash
cd zenoh_c_build && git fetch --tags && git checkout 1.6.2
rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios
export IPHONEOS_DEPLOYMENT_TARGET=13.0
export RUSTFLAGS="-C link-arg=-Wl,-headerpad_max_install_names"   # room for install_name_tool
cargo build --release --target aarch64-apple-ios
cargo build --release --target aarch64-apple-ios-sim
cargo build --release --target x86_64-apple-ios
lipo -create target/aarch64-apple-ios-sim/release/libzenohc.dylib \
             target/x86_64-apple-ios/release/libzenohc.dylib -output libzenohc-sim.dylib
# ...wrap each dylib in a zenohc.framework with an Info.plist, then:
xcodebuild -create-xcframework \
  -framework device/zenohc.framework \
  -framework simulator/zenohc.framework \
  -output ../packages/zenoh_dart/native/ios/1.6.2/zenohc.xcframework
```
The framework wrapping is the fiddly part (install name, `Info.plist`, re-signing), which is why the script exists.

## 4. Link the Active Version to the iOS Plugin
```bash
bash .claude/skills/zenoh-activate-libs/copy_zenoh_libs.sh 1.6.2 ios
bash .claude/skills/zenoh-activate-libs/copy_zenoh_libs.sh 1.6.2 all   # Android jniLibs + iOS framework in one go
```
This copies the XCFramework to `packages/zenoh_dart/ios/Frameworks/zenohc.xcframework`. Then refresh CocoaPods so the new binary is picked up:
```bash
cd ios && pod install && cd ..
flutter build ios      # or: flutter run -d <iphone>
```
`ios/Podfile` is not checked in. On a fresh checkout, skip `pod install`: the first `flutter build ios` or `flutter run` creates the Podfile and runs `pod install` itself. Run `pod install` (or `flutter clean`) yourself after switching to another version.

## How the library is loaded at runtime
- `packages/zenoh_dart/lib/src/bindings/native_library.dart` opens `zenohc.framework/zenohc` on iOS (falling back to `DynamicLibrary.process()`), because the framework is linked by the `zenoh_dart` pod and is already loaded by dyld at launch.
- The background polling isolate in `zenoh_client_native.dart` does the same.
- No `-force_load` tricks are needed because the framework is dynamic: every `pub extern "C"` symbol exported by `zenoh-c` stays available to `dlsym`.

## iOS-specific networking notes
- **Local network permission**: iOS 14+ blocks connections to LAN addresses (for example `tcp/192.168.1.10:7447`) until the user allows "Local Network" access. `ios/Runner/Info.plist` includes `NSLocalNetworkUsageDescription`, so the system prompt appears on first connect. If the prompt is denied, connections silently fail.
- **Multicast scouting**: UDP multicast on iOS requires the `com.apple.developer.networking.multicast` entitlement, which Apple grants on request only. Without it, use client mode, or peer mode with the router's address under **Advanced** > **Connect to (optional)**, so scouting is not needed. The **Multicast scouting** switch in peer and router mode can then be turned off. See [MULTICAST.md](MULTICAST.md) for the request procedure.
- **App Transport Security** only applies to HTTP(S); raw TCP/UDP Zenoh links are unaffected.

## Troubleshooting
- `error: linking with cc failed` mentioning `-isysroot`: Xcode is not selected. Run `sudo xcode-select -s /Applications/Xcode.app`.
- `install_name_tool: ... larger updated load commands do not fit`: the build script appends `-C link-arg=-Wl,-headerpad_max_install_names` to `RUSTFLAGS` (your own `RUSTFLAGS` are kept). A `CARGO_ENCODED_RUSTFLAGS` in the environment takes precedence over `RUSTFLAGS` and drops the flag; unset it and rebuild.
- `dlopen ... zenohc.framework/zenohc: image not found` at runtime: the framework was not embedded. Confirm `packages/zenoh_dart/ios/Frameworks/zenohc.xcframework` exists and re-run `pod install`.
- Simulator build fails on an Intel Mac with `SKIP_X86_64_SIM=1`: rebuild without that flag so the `x86_64` slice is included.
