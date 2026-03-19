# android_lidar_view

A new Flutter project.

## Building Zenoh C for Android

If you are cloning this project onto a new machine or need to rebuild the `zenoh-c` native libraries from scratch for Android, follow these precise steps to manually compile them:

### 1. Prerequisites
Ensure you have the following installed on your machine:
- **Rust & Cargo**: (`curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`)
- **Android NDK**: The Native Development Kit (typically found in `~/Android/Sdk/ndk/`)

### 2. Prepare the Rust Environment
Add the necessary Android architecture targets to your Rust toolchain:
```bash
rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android
```
*(Note: If the build fails because of a missing `core` crate, make sure you append `--toolchain <version>` to match your active channel, e.g., `--toolchain 1.93.0`)*

Next, install `cargo-ndk` which effortlessly handles cross-compiling for Android:
```bash
cargo install cargo-ndk
```

### 3. Build the Binaries
Clone the official `zenoh-c` repository somewhere (e.g., inside a temporary `zenoh_c_build` folder).
*Note: We explicitly specify `--branch 1.6.2` to exactly match the native version officially tied to `zenoh_dart` 0.2.0 bindings.*
```bash
git clone --branch 1.6.2 https://github.com/eclipse-zenoh/zenoh-c.git zenoh_c_build
cd zenoh_c_build
```

Export your NDK home variable to point to your NDK installation. For example:
```bash
export ANDROID_NDK_HOME=$HOME/Android/Sdk/ndk/28.2.13676358
```

Compile for all Android architectures at once using `cargo-ndk`:
```bash
cargo ndk -t arm64-v8a -t armeabi-v7a -t x86_64 -t x86 build --release
```

### 4. Deploy the Libraries to the Project
Once the build concludes, copy the generated `.so` files out of the `target/` directory and into your app's `jniLibs` folder so that Flutter can bundle them into your APK:

```bash
cd ..
# Ensure the subdirectories exist
mkdir -p android/app/src/main/jniLibs/arm64-v8a
mkdir -p android/app/src/main/jniLibs/armeabi-v7a
mkdir -p android/app/src/main/jniLibs/x86_64
mkdir -p android/app/src/main/jniLibs/x86

# Copy the libraries
cp zenoh_c_build/target/aarch64-linux-android/release/libzenohc.so android/app/src/main/jniLibs/arm64-v8a/
cp zenoh_c_build/target/armv7-linux-androideabi/release/libzenohc.so android/app/src/main/jniLibs/armeabi-v7a/
cp zenoh_c_build/target/x86_64-linux-android/release/libzenohc.so android/app/src/main/jniLibs/x86_64/
cp zenoh_c_build/target/i686-linux-android/release/libzenohc.so android/app/src/main/jniLibs/x86/
``` 

*You can also copy the libraries directly into `packages/zenoh_dart/native/android/<arch>/` if you are working with the plugin package locally.*
