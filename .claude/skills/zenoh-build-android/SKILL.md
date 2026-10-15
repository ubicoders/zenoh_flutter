---
name: zenoh-build-android
description: Build the zenoh-c native library (libzenohc.so) for Android with cargo-ndk and store it per ABI in this repo's versioned folders under packages/zenoh_dart/native/android/. Use this whenever the user wants to build zenoh for Android, rebuild libzenohc.so, update or bump the zenoh-c version for Android, run cargo ndk on zenoh-c, add a missing Android ABI, or refresh the libzenoh.so files in android/app/src/main/jniLibs, even if they don't name the script. Not for iOS (use zenoh-build-ios).
---

# Build zenoh-c for Android

`build_zenoh_android.sh` in this folder clones zenoh-c into `zenoh_c_build/` (git-ignored) and checks out a release tag. It cross-compiles that tag with cargo-ndk and copies one `libzenohc.so` per ABI into `packages/zenoh_dart/native/android/<VERSION>/<abi>/`. It does not change what the app ships. Activating a version is a separate `copy_zenoh_libs.sh` step, so several versions can sit side by side. `docs/BUILD_ANDROID.md` has the manual equivalent.

## When to use

- Trying or adopting a new zenoh-c release on Android (for example 1.6.2 -> 1.8.0).
- Rebuilding a version with another NDK, API level or ABI set, or after patching zenoh-c.
- Filling in a missing ABI. The committed 1.6.2 and 1.8.0 folders have no `x86`.

If the user did not name a version, show what exists (`ls packages/zenoh_dart/native/android/`) and the upstream tags (`git -C zenoh_c_build tag --sort=-v:refname | head`, or the zenoh-c GitHub tags page). Confirm the tag before building. Tags have no `v` prefix.

## Prerequisites (Linux or macOS)

- **Rust via rustup** (https://rustup.rs). Each zenoh-c release pins its compiler in `rust-toolchain.toml` (1.85.0 for 1.6.2, 1.93.0 for 1.8.0). rustup installs that toolchain on first use. The script adds the Android targets from inside the checkout, so they land in the pinned toolchain.
- **Android NDK r25 or newer**, preferably r28+, which produces 16 KB-aligned libraries (required on Android 15+ devices that use 16 KB pages). Flutter's default `ndkVersion` here is 28.2.13676358.
- **cargo-ndk**: `cargo install cargo-ndk`. It needs Rust 1.86+, so run that from the repo root, not inside `zenoh_c_build/`.
- git, and network access for the first clone.

## Run it

From the repo root:

```bash
bash .claude/skills/zenoh-build-android/build_zenoh_android.sh --dry-run 1.8.0   # plan only
bash .claude/skills/zenoh-build-android/build_zenoh_android.sh 1.8.0             # build
```

Do the dry run first. It prints the NDK it picked and every command it would run, and it reports missing tools as warnings instead of stopping. A cold build compiles all of zenoh once per ABI, at several minutes per ABI. Start the real build as a background command and wait for it to finish; a foreground call with a 2-minute timeout is killed mid-build.

| Variable | Default | Meaning |
|---|---|---|
| `ANDROID_NDK_HOME` | newest stable NDK in `$ANDROID_HOME/ndk`, `$ANDROID_SDK_ROOT/ndk`, `~/Android/Sdk/ndk`, `~/Library/Android/sdk/ndk` | NDK used to link. Beta and RC NDKs are only used when nothing else is installed, or when set here explicitly |
| `ANDROID_ABIS` | `arm64-v8a armeabi-v7a x86_64 x86` | ABIs to build. `arm64-v8a x86_64` covers phones and the emulator, and builds faster |
| `ANDROID_PLATFORM` | `24` | API level for `cargo ndk --platform`. Keep it at or below the app's `minSdk` (`flutter.minSdkVersion`, currently 24) |
| `ZENOH_C_SRC` | `<repo>/zenoh_c_build` | zenoh-c checkout, shared with the iOS build |
| `DRY_RUN` | unset | `1` is the same as `--dry-run` |

## Output and activation

```
packages/zenoh_dart/native/android/<VERSION>/
  arm64-v8a/libzenohc.so     <- zenoh_c_build/target/aarch64-linux-android/release/
  armeabi-v7a/libzenohc.so   <- zenoh_c_build/target/armv7-linux-androideabi/release/
  x86_64/libzenohc.so        <- zenoh_c_build/target/x86_64-linux-android/release/
  x86/libzenohc.so           <- zenoh_c_build/target/i686-linux-android/release/
```

These folders are committed to git, at roughly 10-14 MB per library. To ship a version, run this from the repo root (the copy script uses relative paths):

```bash
bash .claude/skills/zenoh-activate-libs/copy_zenoh_libs.sh 1.8.0      # -> android/app/src/main/jniLibs/<abi>/libzenoh.so
```

The copy renames the file to `libzenoh.so`, the name that `packages/zenoh_dart/lib/src/bindings/native_library.dart` opens on Android.

## Verify

```bash
ls -l packages/zenoh_dart/native/android/1.8.0/*/libzenohc.so
file packages/zenoh_dart/native/android/1.8.0/arm64-v8a/libzenohc.so   # ELF 64-bit LSB shared object, ARM aarch64
readelf -h packages/zenoh_dart/native/android/1.8.0/x86_64/libzenohc.so | grep Machine   # Advanced Micro Devices X86-64
bash .claude/skills/zenoh-activate-libs/copy_zenoh_libs.sh 1.8.0 && flutter run -d emulator-5554            # `flutter devices` lists device IDs
```

The app should start and connect. The log should show no `dlopen failed` or `Failed to load dynamic library` errors.

## Common failures

- **No NDK found, or "not an NDK folder"**: install "NDK (Side by side)" in Android Studio's SDK Manager. Or set `ANDROID_NDK_HOME` to a versioned folder such as `~/Android/Sdk/ndk/28.2.13676358`, not to the `ndk/` parent.
- **Wrong NDK version**: `unable to find library -lunwind` means the NDK is older than r25, and the script refuses such NDKs up front. `unable to find library -lgcc` is the opposite mismatch: a Rust older than 1.68 with NDK r23+. It means something overrode zenoh-c's pinned toolchain; check `RUSTUP_TOOLCHAIN` and `rustup override list`.
- **Missing rustup target** (`can't find crate for core` or `target may not be installed`): the targets went into a different toolchain. Run `rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android` inside `zenoh_c_build/`. If rustup says the pinned toolchain is not installed, first run `rustup toolchain install <channel>` with the channel from `zenoh_c_build/rust-toolchain.toml`.
- **cargo-ndk not installed**: run `cargo install cargo-ndk` from the repo root, and make sure `~/.cargo/bin` is on `PATH`.
- **Checkout fails**: either the tag does not exist (check the tag list), or an earlier build left local changes (`git -C zenoh_c_build status`). Discard those changes only after confirming they are generated files.
- **"expected ... libzenohc.so was not produced"**: the script looks in `zenoh_c_build/target`, or in `$CARGO_TARGET_DIR` when set. Check for a cargo config that moves the target dir.

## Dart bindings caveat

The FFI bindings (`packages/zenoh_dart/lib/src/bindings/zenoh_generated.dart`) were generated by ffigen (`packages/zenoh_dart/ffigen.yaml`) from the zenoh-c **1.6.2** headers. zenoh-c 1.8.0 has larger opaque structs; for example `z_owned_config_t` is 2008 bytes instead of 1984. `zenoh_client_native.dart` therefore pads those allocations by `_opaqueSlackBytes` (256).

A newer zenoh-c can outgrow that padding or change function signatures. The result is heap corruption or crashes at runtime, not a build error. Before switching the app to a new version, compare its headers with the bindings. The headers are in `zenoh_c_build/include/`, and the build writes `zenoh_opaque.h` there for the last target built. Regenerate the bindings if sizes or APIs changed.
