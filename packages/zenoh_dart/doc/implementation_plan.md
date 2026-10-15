# Implementation Plan

## Native library distribution

1. ✅ Track release metadata in `tool/zenoh_binaries.json` (zenoh-c 1.6.2 desktop archives with checksums; the Android and iOS entries have no URL).
2. ✅ Extend `tool/fetch_zenoh_binaries.dart` to download artifacts and verify hashes.
3. ✅ Store unpacked shared libraries under `native/<platform>/` for bundling: Android and iOS per zenoh-c version (`native/<platform>/<version>/`), desktop per architecture. See `native/README.md`.
4. ✅ Document manual steps and eventual CI automation in `README.md`.
5. ✅ Provide per-platform build scripts in `tool/` for cases where official artifacts are unavailable. Android and iOS are built by the scripts at the repository root (`docs/BUILD_ANDROID.md`, `docs/BUILD_IOS.md`).

## Bindings generation

1. ✅ Maintain a thin typed wrapper over the generated bindings in `lib/src/bindings/zenoh_bindings.dart`.
2. ✅ Use `ffigen` with `ffigen.yaml` to generate the full API into `lib/src/bindings/zenoh_generated.dart`. The current file comes from the zenoh-c 1.6.2 headers; regenerating from 1.8.0 is still to do (see `doc/platform_support.md`).
3. ✅ Wrap generated bindings with idiomatic classes in `lib/src`.
4. Add unit tests validating session lifecycle and basic publish/subscribe flows once native binaries are available. So far there is one Windows-only pub/sub integration test (`test/zenoh_pubsub_integration_test.dart`).

## High-level Dart API

1. ✅ Expand `ZenohClient` with publish helpers backed by the bindings (subscribe done, query pending).
2. Provide resource lifecycle classes (`ZenohPublisher`, `ZenohSubscriber`) that manage underlying handles safely.
3. ✅ Expose streaming APIs using `StreamController` for subscriber callbacks.
4. Supply example snippets for ROS 2 interoperability in `example/lib/`.
5. Implement subscription/query wrappers once native callbacks are wired. Subscriptions are done (a zenoh FIFO channel polled by a background isolate); queries are pending.

## Tooling and CI

1. Create GitHub Actions workflows to fetch binaries and run Flutter unit tests on all platforms.
2. Add formatting and static analysis checks (`dart format`, `flutter analyze`).
3. Configure publishing safeguards (version checks, changelog gates).
