#!/bin/bash

# Copies a built zenoh-c version into the location the Flutter app bundles from.
#   ./copy_zenoh_libs.sh <version> [android|ios|all]      (default platform: android)
#
#   android: packages/zenoh_dart/native/android/<version>/<abi>/libzenohc.so
#            -> android/app/src/main/jniLibs/<abi>/libzenoh.so
#   ios:     packages/zenoh_dart/native/ios/<version>/zenohc.xcframework
#            -> packages/zenoh_dart/ios/Frameworks/zenohc.xcframework (vendored by the podspec)

VERSION=$1
PLATFORM=${2:-android}

usage() {
  echo "Usage: ./copy_zenoh_libs.sh <version> [android|ios|all]"
  echo "Available Android versions in packages/zenoh_dart/native/android/:"
  ls -1 packages/zenoh_dart/native/android/ 2>/dev/null
  echo "Available iOS versions in packages/zenoh_dart/native/ios/:"
  ls -1 packages/zenoh_dart/native/ios/ 2>/dev/null
}

if [ -z "$VERSION" ]; then
  usage
  exit 1
fi

copy_android() {
  SRC_DIR="packages/zenoh_dart/native/android/$VERSION"
  if [ ! -d "$SRC_DIR" ]; then
    echo "Error: Android version $VERSION not found in $SRC_DIR"
    return 1
  fi

  DEST_DIR="android/app/src/main/jniLibs"
  echo "Copying Zenoh C libraries for Android, version $VERSION..."
  for arch in arm64-v8a armeabi-v7a x86 x86_64; do
    if [ -f "$SRC_DIR/$arch/libzenohc.so" ]; then
      mkdir -p "$DEST_DIR/$arch"
      cp "$SRC_DIR/$arch/libzenohc.so" "$DEST_DIR/$arch/libzenoh.so"
      echo " -> Copied $arch as libzenoh.so"
    else
      echo " -> Warning: libzenohc.so for $arch not found in $SRC_DIR"
    fi
  done
  echo "Successfully updated Android jniLibs to Zenoh $VERSION!"
}

copy_ios() {
  SRC_FW="packages/zenoh_dart/native/ios/$VERSION/zenohc.xcframework"
  if [ ! -d "$SRC_FW" ]; then
    echo "Error: iOS version $VERSION not found at $SRC_FW (run ./build_zenoh_ios.sh $VERSION on macOS first)"
    return 1
  fi

  DEST_DIR="packages/zenoh_dart/ios/Frameworks"
  DEST_FW="${DEST_DIR:?}/zenohc.xcframework"
  echo "Copying Zenoh C XCFramework for iOS, version $VERSION..."
  mkdir -p "$DEST_DIR"
  rm -rf "$DEST_FW"
  cp -R "$SRC_FW" "$DEST_FW"
  echo " -> Copied zenohc.xcframework to $DEST_DIR"
  echo "Successfully updated iOS vendored framework to Zenoh $VERSION!"
  echo "Run 'cd ios && pod install' (or 'flutter clean') so CocoaPods picks up the new binary."
}

case "$PLATFORM" in
  android) copy_android ;;
  ios)     copy_ios ;;
  all)     copy_android; echo ""; copy_ios ;;
  *)       echo "Error: unknown platform '$PLATFORM'"; usage; exit 1 ;;
esac
