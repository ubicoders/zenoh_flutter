#!/bin/bash

# Script to copy standard zenoh-c native libraries to Android jniLibs
VERSION=$1

if [ -z "$VERSION" ]; then
  echo "Usage: ./copy_zenoh_libs.sh <version>"
  echo "Available versions in packages/zenoh_dart/native/android/:"
  ls -1 packages/zenoh_dart/native/android/
  exit 1
fi

SRC_DIR="packages/zenoh_dart/native/android/$VERSION"

if [ ! -d "$SRC_DIR" ]; then
  echo "Error: Version $VERSION not found in $SRC_DIR"
  exit 1
fi

DEST_DIR="android/app/src/main/jniLibs"

echo "Copying Zenoh C libraries for version $VERSION..."
for arch in arm64-v8a armeabi-v7a x86 x86_64; do
    if [ -f "$SRC_DIR/$arch/libzenohc.so" ]; then
        mkdir -p "$DEST_DIR/$arch"
        cp "$SRC_DIR/$arch/libzenohc.so" "$DEST_DIR/$arch/libzenoh.so"
        echo " -> Copied $arch as libzenoh.so"
    else
        echo " -> Warning: libzenohc.so for $arch not found in $SRC_DIR"
    fi
done

echo ""
echo "Successfully updated Android jniLibs to Zenoh $VERSION!"
