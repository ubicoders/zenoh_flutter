#!/usr/bin/env bash
set -euo pipefail

# Builds zenoh-c for iOS (device + simulator) with cargo, wraps the result in a
# dynamic zenohc.framework per slice, and packages both slices into
# packages/zenoh_dart/native/ios/<VERSION>/zenohc.xcframework
#
# Must run on macOS with Xcode installed. See docs/BUILD_IOS.md.
#
# Usage:
#   bash .claude/skills/zenoh-build-ios/build_zenoh_ios.sh <version>   # e.g. ... 1.6.2 (from the repo root)
#
# Environment overrides:
#   ZENOH_C_SRC=zenoh_c_build      clone directory (git-ignored, shared with the Android build)
#   IOS_MIN_VERSION=13.0           deployment target (matches ios/Runner.xcodeproj)
#   SKIP_X86_64_SIM=1              skip the Intel simulator slice
#   FRAMEWORK_ID=org.eclipse.zenoh.zenohc   CFBundleIdentifier of the framework

VERSION=${1:-}
if [[ -z "$VERSION" ]]; then
  echo "Usage: bash .claude/skills/zenoh-build-ios/build_zenoh_ios.sh <version>   (e.g. 1.6.2)" >&2
  exit 1
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Error: iOS builds require macOS with Xcode (uname: $(uname -s))." >&2
  exit 1
fi
for tool in cargo rustup xcrun xcodebuild lipo install_name_tool codesign plutil; do
  command -v "$tool" >/dev/null 2>&1 || { echo "Error: '$tool' not found in PATH." >&2; exit 1; }
done

# This script lives in <repo>/.claude/skills/zenoh-build-ios/; the repo root is three levels up.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ZENOH_C_SRC="${ZENOH_C_SRC:-$ROOT_DIR/zenoh_c_build}"
IOS_MIN_VERSION="${IOS_MIN_VERSION:-13.0}"
FRAMEWORK_NAME="zenohc"
FRAMEWORK_ID="${FRAMEWORK_ID:-org.eclipse.zenoh.zenohc}"
OUT_DIR="$ROOT_DIR/packages/zenoh_dart/native/ios/$VERSION"
STAGE_DIR="$ZENOH_C_SRC/target/ios-frameworks"

# ---------------------------------------------------------------------------
# 1. Source checkout
# ---------------------------------------------------------------------------
if [[ ! -d "$ZENOH_C_SRC/.git" ]]; then
  echo "==> Cloning zenoh-c into $ZENOH_C_SRC"
  git clone https://github.com/eclipse-zenoh/zenoh-c.git "$ZENOH_C_SRC"
fi
echo "==> Checking out zenoh-c $VERSION"
git -C "$ZENOH_C_SRC" fetch --tags --quiet
git -C "$ZENOH_C_SRC" checkout --quiet "$VERSION"

# ---------------------------------------------------------------------------
# 2. Rust targets
# ---------------------------------------------------------------------------
TARGETS=(aarch64-apple-ios aarch64-apple-ios-sim)
if [[ "${SKIP_X86_64_SIM:-0}" != "1" ]]; then
  TARGETS+=(x86_64-apple-ios)
fi
echo "==> Ensuring Rust targets: ${TARGETS[*]}"
# Inside the checkout, so the targets land in the toolchain zenoh-c pins in rust-toolchain.toml.
(cd "$ZENOH_C_SRC" && rustup target add "${TARGETS[@]}")

# ---------------------------------------------------------------------------
# 3. cargo build (cdylib -> libzenohc.dylib per target)
# ---------------------------------------------------------------------------
export IPHONEOS_DEPLOYMENT_TARGET="$IOS_MIN_VERSION"
# Leave room in the Mach-O header so install_name_tool can rewrite the id below.
export RUSTFLAGS="${RUSTFLAGS:-} -C link-arg=-Wl,-headerpad_max_install_names"

for target in "${TARGETS[@]}"; do
  echo "==> cargo build --release --target $target"
  (cd "$ZENOH_C_SRC" && cargo build --release --target "$target")
  if [[ ! -f "$ZENOH_C_SRC/target/$target/release/lib${FRAMEWORK_NAME}.dylib" ]]; then
    echo "Error: expected $ZENOH_C_SRC/target/$target/release/lib${FRAMEWORK_NAME}.dylib was not produced." >&2
    exit 1
  fi
done

# ---------------------------------------------------------------------------
# 4. Wrap each slice in a zenohc.framework bundle
# ---------------------------------------------------------------------------
make_framework() {
  local platform=$1   # iPhoneOS | iPhoneSimulator
  local dylib=$2
  local fw_dir="${STAGE_DIR:?}/${platform:?}/${FRAMEWORK_NAME:?}.framework"

  rm -rf "$fw_dir"
  mkdir -p "$fw_dir/Headers"
  cp "$dylib" "$fw_dir/$FRAMEWORK_NAME"
  if [[ -d "$ZENOH_C_SRC/include" ]]; then
    cp -R "$ZENOH_C_SRC/include/." "$fw_dir/Headers/"
  fi

  install_name_tool -id "@rpath/$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME" "$fw_dir/$FRAMEWORK_NAME"
  # install_name_tool invalidates the linker's ad-hoc signature; re-sign ad hoc.
  codesign --force --sign - "$fw_dir/$FRAMEWORK_NAME" >/dev/null 2>&1 || true

  cat > "$fw_dir/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>$FRAMEWORK_NAME</string>
	<key>CFBundleIdentifier</key>
	<string>$FRAMEWORK_ID</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>$FRAMEWORK_NAME</string>
	<key>CFBundlePackageType</key>
	<string>FMWK</string>
	<key>CFBundleShortVersionString</key>
	<string>$VERSION</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>CFBundleSupportedPlatforms</key>
	<array>
		<string>$platform</string>
	</array>
	<key>MinimumOSVersion</key>
	<string>$IOS_MIN_VERSION</string>
</dict>
</plist>
PLIST
  plutil -lint "$fw_dir/Info.plist" >/dev/null
  echo "$fw_dir"
}

echo "==> Creating framework slices"
DEVICE_FW=$(make_framework iPhoneOS "$ZENOH_C_SRC/target/aarch64-apple-ios/release/lib${FRAMEWORK_NAME}.dylib")

SIM_DYLIB="$STAGE_DIR/lib${FRAMEWORK_NAME}-sim.dylib"
mkdir -p "$STAGE_DIR"
if [[ "${SKIP_X86_64_SIM:-0}" != "1" ]]; then
  lipo -create \
    "$ZENOH_C_SRC/target/aarch64-apple-ios-sim/release/lib${FRAMEWORK_NAME}.dylib" \
    "$ZENOH_C_SRC/target/x86_64-apple-ios/release/lib${FRAMEWORK_NAME}.dylib" \
    -output "$SIM_DYLIB"
else
  cp "$ZENOH_C_SRC/target/aarch64-apple-ios-sim/release/lib${FRAMEWORK_NAME}.dylib" "$SIM_DYLIB"
fi
SIM_FW=$(make_framework iPhoneSimulator "$SIM_DYLIB")

# ---------------------------------------------------------------------------
# 5. XCFramework into the versioned package folder
# ---------------------------------------------------------------------------
XCFRAMEWORK="${OUT_DIR:?}/${FRAMEWORK_NAME:?}.xcframework"
echo "==> Creating $XCFRAMEWORK"
rm -rf "$XCFRAMEWORK"
mkdir -p "$OUT_DIR"
xcodebuild -create-xcframework \
  -framework "$DEVICE_FW" \
  -framework "$SIM_FW" \
  -output "$XCFRAMEWORK"

echo ""
echo "XCFramework ready: $XCFRAMEWORK"
echo "Activate it for the app with:  bash .claude/skills/zenoh-activate-libs/copy_zenoh_libs.sh $VERSION ios"
