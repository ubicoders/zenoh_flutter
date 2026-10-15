# Building Zenoh C for Android (Versioned)

To rebuild the `zenoh-c` native libraries for Android from source, run the build script, or follow the manual steps below. Both paths compile the libraries and place them into the version-controlled structure, `packages/zenoh_dart/native/android/<VERSION>/<abi>/libzenohc.so`.

Works on Linux or macOS.

## 1. Prerequisites
Ensure you have the following installed on your machine:
- **Rust & Cargo**: (`curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`)
- **cargo-ndk**: `cargo install cargo-ndk`. Run this outside `zenoh_c_build/`: cargo-ndk needs a newer Rust than some zenoh-c releases pin in their `rust-toolchain.toml`.
- **Android NDK** r25 or newer (r28 or newer recommended): the Native Development Kit, typically found in `~/Android/Sdk/ndk/<version>/`
- **git**

## 2. Scripted Build
From the project root:
```bash
bash .claude/skills/zenoh-build-android/build_zenoh_android.sh 1.8.0
```

`bash .claude/skills/zenoh-build-android/build_zenoh_android.sh` forwards to `.claude/skills/zenoh-build-android/build_zenoh_android.sh`, which is the script of the `zenoh-build-android` Claude Code skill. The script:
1. Checks for `git`, `cargo`, `rustup`, `cargo-ndk` and an NDK (r25 or newer) before it changes anything.
2. Clones `zenoh-c` into `zenoh_c_build/` (git-ignored, shared with the iOS build) if it is not there yet, then checks out the `1.8.0` tag.
3. Runs `rustup target add` for the Android targets inside the checkout. This adds them to the Rust toolchain that zenoh-c pins in its `rust-toolchain.toml`.
4. Runs `cargo ndk -t arm64-v8a -t armeabi-v7a -t x86_64 -t x86 --platform 24 build --release`.
5. Copies each `libzenohc.so` to `packages/zenoh_dart/native/android/1.8.0/<abi>/`.

Useful overrides:
```bash
bash .claude/skills/zenoh-build-android/build_zenoh_android.sh --dry-run 1.8.0                          # print the commands, change nothing (same as DRY_RUN=1)
ANDROID_NDK_HOME=$HOME/Android/Sdk/ndk/28.2.13676358 bash .claude/skills/zenoh-build-android/build_zenoh_android.sh 1.8.0
ANDROID_ABIS="arm64-v8a x86_64" bash .claude/skills/zenoh-build-android/build_zenoh_android.sh 1.8.0    # default: arm64-v8a armeabi-v7a x86_64 x86
ANDROID_PLATFORM=24 bash .claude/skills/zenoh-build-android/build_zenoh_android.sh 1.8.0                # API level for cargo ndk (default 24); keep it <= the app's minSdk
ZENOH_C_SRC=/path/to/zenoh-c bash .claude/skills/zenoh-build-android/build_zenoh_android.sh 1.8.0       # use another clone
```
Without `ANDROID_NDK_HOME`, the script picks the newest stable NDK it finds in `$ANDROID_HOME/ndk`, `$ANDROID_SDK_ROOT/ndk`, `~/Android/Sdk/ndk` or `~/Library/Android/sdk/ndk`.

Then activate the version as in step 6.

## Manual Build
The steps below do the same as the script, by hand.

## 3. Get the Source and Prepare the Rust Environment
Clone the official `zenoh-c` repository into a temporary folder (this folder is git-ignored):
```bash
git clone https://github.com/eclipse-zenoh/zenoh-c.git zenoh_c_build
cd zenoh_c_build
```

Checkout the exact version tag you want to build (for example, `1.6.2` or `1.8.0`):
```bash
git fetch --tags
git checkout 1.6.2
```

Still inside `zenoh_c_build`, add the necessary Android architecture targets. zenoh-c pins its Rust version in `rust-toolchain.toml`, so the targets have to be added from inside the checkout:
```bash
rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android
```

## 4. Build a Specific Version
Export your NDK home variable and compile for all architectures:
```bash
export ANDROID_NDK_HOME=$HOME/Android/Sdk/ndk/28.2.13676358
cargo ndk -t arm64-v8a -t armeabi-v7a -t x86_64 -t x86 --platform 24 build --release
```

## 5. Deploy the Libraries to the Version Folder
Once the build concludes, copy the `.so` files out of the `target/` directory and directly into the versioned local package folder:

```bash
cd ..
VERSION="1.6.2" # Change this to the version you just built!

mkdir -p packages/zenoh_dart/native/android/$VERSION/arm64-v8a
mkdir -p packages/zenoh_dart/native/android/$VERSION/armeabi-v7a
mkdir -p packages/zenoh_dart/native/android/$VERSION/x86_64
mkdir -p packages/zenoh_dart/native/android/$VERSION/x86

cp zenoh_c_build/target/aarch64-linux-android/release/libzenohc.so packages/zenoh_dart/native/android/$VERSION/arm64-v8a/
cp zenoh_c_build/target/armv7-linux-androideabi/release/libzenohc.so packages/zenoh_dart/native/android/$VERSION/armeabi-v7a/
cp zenoh_c_build/target/x86_64-linux-android/release/libzenohc.so packages/zenoh_dart/native/android/$VERSION/x86_64/
cp zenoh_c_build/target/i686-linux-android/release/libzenohc.so packages/zenoh_dart/native/android/$VERSION/x86/
```

## 6. Link the Active Version to Android jniLibs
To select which built version gets bundled into your Android app, run the `zenoh-activate-libs` skill script from the project root:

```bash
bash .claude/skills/zenoh-activate-libs/copy_zenoh_libs.sh 1.6.2          # "android" is the default platform
bash .claude/skills/zenoh-activate-libs/copy_zenoh_libs.sh 1.6.2 android  # same thing, explicit
```
This script copies the libraries from `packages/zenoh_dart/native/android/$VERSION/` into `android/app/src/main/jniLibs/<abi>/libzenoh.so`, making them active for your next Flutter build. It handles `arm64-v8a`, `armeabi-v7a`, `x86` and `x86_64`, and prints a warning for any ABI missing from that version.

## How the library is loaded at runtime
`zenoh_dart` opens `libzenoh.so` on Android: in `packages/zenoh_dart/lib/src/bindings/native_library.dart`, and again in each subscriber's polling isolate in `zenoh_client_native.dart`. Gradle packages everything under `android/app/src/main/jniLibs/<abi>/` into the APK, so the rename from `libzenohc.so` to `libzenoh.so` done by the copy script is required.

## Versions in the repository
- `packages/zenoh_dart/native/android/` holds 1.6.2 and 1.8.0 for `arm64-v8a`, `armeabi-v7a` and `x86_64` (no `x86`). `android/app/src/main/jniLibs/` holds the 1.8.0 files.
- The Dart FFI bindings were generated from the zenoh-c 1.6.2 headers. To run safely on 1.8.0, `zenoh_dart` over-allocates three opaque structs. Read [platform_support.md](../packages/zenoh_dart/doc/platform_support.md#bindings-and-zenoh-c-versions) before you switch versions or regenerate the bindings.
