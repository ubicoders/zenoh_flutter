# Active iOS framework

This folder holds the `zenohc.xcframework` that the podspec in the parent directory vendors into the app.

Do not edit it by hand. From the repository root run:

```bash
./copy_zenoh_libs.sh <version> ios
```

which copies `packages/zenoh_dart/native/ios/<version>/zenohc.xcframework` here. See `docs/BUILD_IOS.md` for how to produce a version.
