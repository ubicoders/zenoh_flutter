# Building Zenoh C for Android (Versioned)

If you need to rebuild the `zenoh-c` native libraries from scratch for Android, follow these precise steps to manually compile them and place them into the version-controlled structure.

Works on Linux or macOS.

## 1. Prerequisites
Ensure you have the following installed on your machine:
- **Rust & Cargo**: (`curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`)
- **Android NDK**: The Native Development Kit (typically found in `~/Android/Sdk/ndk/`)

## 2. Prepare the Rust Environment
Add the necessary Android architecture targets to your Rust toolchain:
```bash
rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android
cargo install cargo-ndk
```

## 3. Build a Specific Version (e.g. 1.6.2 or 1.8.0)
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

Export your NDK home variable and compile for all architectures:
```bash
export ANDROID_NDK_HOME=$HOME/Android/Sdk/ndk/28.2.13676358
cargo ndk -t arm64-v8a -t armeabi-v7a -t x86_64 -t x86 build --release
```

## 4. Deploy the Libraries to the Version Folder
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

## 5. Link the Active Version to Android jniLibs
To select which built version gets bundled into your Android app, run the helper script provided at the project root:

```bash
./copy_zenoh_libs.sh 1.6.2          # "android" is the default platform
./copy_zenoh_libs.sh 1.6.2 android  # same thing, explicit
```
This script copies the libraries from `packages/zenoh_dart/native/android/$VERSION/` into `android/app/src/main/jniLibs/<abi>/libzenoh.so`, making them active for your next Flutter build.

## How the library is loaded at runtime
`zenoh_dart` opens `libzenoh.so` on Android (see `packages/zenoh_dart/lib/src/bindings/native_library.dart`). Gradle packages everything under `android/app/src/main/jniLibs/<abi>/` into the APK, so the rename from `libzenohc.so` to `libzenoh.so` done by the copy script is required.
