#!/usr/bin/env bash
set -euo pipefail

# Builds zenoh-c for Android with cargo-ndk and stores one libzenohc.so per ABI in
#   packages/zenoh_dart/native/android/<VERSION>/<abi>/libzenohc.so
# Activating a built version for the app is a separate step: bash .claude/skills/zenoh-activate-libs/copy_zenoh_libs.sh <VERSION>
#
# Works on Linux or macOS. See docs/BUILD_ANDROID.md for the manual steps.
#
# Usage:
#   build_zenoh_android.sh [--dry-run] <version>     # e.g. build_zenoh_android.sh 1.6.2
#
# Environment overrides:
#   ZENOH_C_SRC=<repo>/zenoh_c_build   clone directory (git-ignored, shared with the iOS build)
#   ANDROID_NDK_HOME=<ndk dir>         default: newest stable NDK in $ANDROID_HOME/ndk,
#                                      $ANDROID_SDK_ROOT/ndk, ~/Android/Sdk/ndk or ~/Library/Android/sdk/ndk
#   ANDROID_ABIS="arm64-v8a armeabi-v7a x86_64 x86"   ABIs to build
#   ANDROID_PLATFORM=24                API level for cargo ndk --platform (keep <= the app's minSdk)
#   DRY_RUN=1                          same as --dry-run: print the commands, change nothing

usage() {
  echo "Usage: build_zenoh_android.sh [--dry-run] <version>   (e.g. 1.6.2)"
}

if (( $# == 0 )); then
  usage >&2
  exit 1
fi
DRY_RUN=${DRY_RUN:-0}
VERSION=""
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "Error: unknown option '$arg'." >&2; usage >&2; exit 1 ;;
    *)
      if [[ -n "$VERSION" ]]; then usage >&2; exit 1; fi
      VERSION=$arg
      ;;
  esac
done
if [[ -z "$VERSION" ]]; then
  usage >&2
  exit 1
fi
if [[ ! "$VERSION" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "Error: '$VERSION' does not look like a zenoh-c tag such as 1.6.2." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
die() { echo "Error: $*" >&2; exit 1; }

# A missing prerequisite stops a real run; a dry run only warns, so the whole plan is still shown.
need() {
  if [[ "$DRY_RUN" == "1" ]]; then echo "Warning: $*" >&2; else die "$*"; fi
}

quote() { local q; q=$(printf '%q ' "$@"); printf '%s' "${q% }"; }

# run CMD...: run CMD, or only print it on a dry run.
run() {
  if [[ "$DRY_RUN" == "1" ]]; then echo "[dry-run] $(quote "$@")"; else "$@"; fi
}

# run_in DIR CMD...: like run, but inside DIR. rustup and cargo must run inside the zenoh-c
# checkout so they use the Rust version its rust-toolchain.toml pins (it differs per release).
run_in() {
  local dir=$1
  shift
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "[dry-run] (cd $(quote "$dir") && $(quote "$@"))"
  else
    (cd "$dir" && "$@")
  fi
}

abi_triple() {
  case "$1" in
    arm64-v8a)   echo aarch64-linux-android ;;
    armeabi-v7a) echo armv7-linux-androideabi ;;
    x86_64)      echo x86_64-linux-android ;;
    x86)         echo i686-linux-android ;;
    *)           return 1 ;;
  esac
}

# Pkg.Revision of an NDK folder, e.g. 28.2.13676358 or 30.0.14904198-beta1.
ndk_revision() {
  sed -n 's/^Pkg\.Revision *= *//p' "$1/source.properties" | tr -d '\r'
}

# Newest NDK in an SDK's ndk/ folder. Stable releases win over -beta/-rc ones, so a preview
# NDK installed next to a stable one is not picked by accident.
newest_ndk() {
  local dir rev
  for dir in "$1"/*/; do
    dir=${dir%/}
    [[ -f "$dir/source.properties" ]] || continue
    rev=$(ndk_revision "$dir")
    case "$rev" in
      "")  ;;
      *-*) echo "0.${rev%%-*} $dir" ;;
      *)   echo "1.$rev $dir" ;;
    esac
  done | LC_ALL=C sort -t. -k1,1n -k2,2n -k3,3n -k4,4n | tail -n 1 | cut -d' ' -f2-
}

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
# This script lives in <repo>/.claude/skills/zenoh-build-android/; the repo root is three levels up.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ZENOH_C_SRC="${ZENOH_C_SRC:-$ROOT_DIR/zenoh_c_build}"
ANDROID_ABIS="${ANDROID_ABIS:-arm64-v8a armeabi-v7a x86_64 x86}"
ANDROID_PLATFORM="${ANDROID_PLATFORM:-24}"
OUT_DIR="$ROOT_DIR/packages/zenoh_dart/native/android/$VERSION"
# cargo resolves a relative CARGO_TARGET_DIR against the directory it runs in (the checkout).
TARGET_DIR="${CARGO_TARGET_DIR:-target}"
if [[ "$TARGET_DIR" != /* ]]; then TARGET_DIR="$ZENOH_C_SRC/$TARGET_DIR"; fi

if [[ -z "${ANDROID_ABIS//[ ,]/}" ]]; then die "ANDROID_ABIS is empty."; fi
read -r -a ABIS <<<"${ANDROID_ABIS//,/ }"
RUST_TARGETS=()
NDK_TARGET_ARGS=()
for abi in "${ABIS[@]}"; do
  triple=$(abi_triple "$abi") || die "unknown ABI '$abi' in ANDROID_ABIS (valid: arm64-v8a armeabi-v7a x86_64 x86)."
  RUST_TARGETS+=("$triple")
  NDK_TARGET_ARGS+=(-t "$abi")
done
if [[ ! "$ANDROID_PLATFORM" =~ ^[0-9]+$ ]]; then
  die "ANDROID_PLATFORM must be an API level such as 24, got '$ANDROID_PLATFORM'."
fi

if [[ "$DRY_RUN" == "1" ]]; then
  echo "==> DRY RUN: commands are printed; nothing is cloned, built or copied"
fi
echo "==> zenoh-c $VERSION for Android: ${ABIS[*]} (API level $ANDROID_PLATFORM)"

# ---------------------------------------------------------------------------
# 0. Prerequisites, all checked before anything is cloned or built
# ---------------------------------------------------------------------------
for tool in git cargo rustup cargo-ndk; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    case "$tool" in
      cargo-ndk)    need "'cargo-ndk' not found in PATH. Install it with: cargo install cargo-ndk" ;;
      cargo|rustup) need "'$tool' not found in PATH. Install Rust from https://rustup.rs" ;;
      *)            need "'$tool' not found in PATH." ;;
    esac
  fi
done

if [[ -n "${ANDROID_NDK_HOME:-}" ]]; then
  NDK_ORIGIN="from ANDROID_NDK_HOME"
else
  NDK_ORIGIN="auto-selected; set ANDROID_NDK_HOME to override"
  for sdk in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" "$HOME/Android/Sdk" "$HOME/Library/Android/sdk"; do
    if [[ -n "$sdk" && -d "$sdk/ndk" ]]; then
      ANDROID_NDK_HOME=$(newest_ndk "$sdk/ndk")
      if [[ -n "$ANDROID_NDK_HOME" ]]; then break; fi
    fi
  done
fi
if [[ -z "${ANDROID_NDK_HOME:-}" ]]; then
  need "no Android NDK found in \$ANDROID_HOME/ndk, ~/Android/Sdk/ndk or ~/Library/Android/sdk/ndk. Install 'NDK (Side by side)' with Android Studio's SDK Manager, or set ANDROID_NDK_HOME=/path/to/ndk/<version>."
  ANDROID_NDK_HOME="<ANDROID_NDK_HOME>"
elif [[ ! -f "$ANDROID_NDK_HOME/source.properties" ]]; then
  need "ANDROID_NDK_HOME=$ANDROID_NDK_HOME is not an NDK folder (no source.properties). Use a versioned folder such as ~/Android/Sdk/ndk/28.2.13676358."
else
  NDK_REV=$(ndk_revision "$ANDROID_NDK_HOME")
  echo "==> Android NDK ${NDK_REV:-(unknown version)} at $ANDROID_NDK_HOME ($NDK_ORIGIN)"
  NDK_MAJOR=${NDK_REV%%.*}
  if [[ "$NDK_MAJOR" =~ ^[0-9]+$ ]] && (( 10#$NDK_MAJOR < 25 )); then
    need "NDK $NDK_REV is too old: zenoh-c's Rust toolchain needs NDK r25 or newer (r28+ recommended)."
  fi
  if [[ "$NDK_REV" == *-* ]]; then
    echo "Warning: NDK $NDK_REV is a pre-release." >&2
  fi
fi

# ---------------------------------------------------------------------------
# 1. Source checkout
# ---------------------------------------------------------------------------
if [[ ! -d "$ZENOH_C_SRC/.git" ]]; then
  echo "==> Cloning zenoh-c into $ZENOH_C_SRC"
  run git clone https://github.com/eclipse-zenoh/zenoh-c.git "$ZENOH_C_SRC"
fi
echo "==> Checking out zenoh-c $VERSION"
if ! run git -C "$ZENOH_C_SRC" fetch --tags --quiet; then
  echo "Warning: 'git fetch --tags' failed (offline?); using the tags already in $ZENOH_C_SRC." >&2
fi
if ! run git -C "$ZENOH_C_SRC" checkout --quiet "$VERSION"; then
  die "could not check out '$VERSION' in $ZENOH_C_SRC. List tags with 'git -C $ZENOH_C_SRC tag --sort=-v:refname'; if git reported local changes, inspect them with 'git -C $ZENOH_C_SRC status'."
fi

# ---------------------------------------------------------------------------
# 2. Rust targets, added to the toolchain zenoh-c pins (hence inside the checkout)
# ---------------------------------------------------------------------------
echo "==> Ensuring Rust targets: ${RUST_TARGETS[*]}"
run_in "$ZENOH_C_SRC" rustup target add "${RUST_TARGETS[@]}"

# ---------------------------------------------------------------------------
# 3. cargo ndk build (cdylib -> libzenohc.so per ABI); a cold build takes a while
# ---------------------------------------------------------------------------
echo "==> Building with cargo ndk"
run_in "$ZENOH_C_SRC" env ANDROID_NDK_HOME="$ANDROID_NDK_HOME" \
  cargo ndk "${NDK_TARGET_ARGS[@]}" --platform "$ANDROID_PLATFORM" build --release

# ---------------------------------------------------------------------------
# 4. Copy into the versioned package folder
# ---------------------------------------------------------------------------
if [[ "$DRY_RUN" != "1" ]]; then
  for abi in "${ABIS[@]}"; do
    so="$TARGET_DIR/$(abi_triple "$abi")/release/libzenohc.so"
    [[ -f "$so" ]] || die "expected $so was not produced (is CARGO_TARGET_DIR or a cargo config moving the target dir?)."
  done
fi
echo "==> Copying libraries to $OUT_DIR"
for abi in "${ABIS[@]}"; do
  run mkdir -p "$OUT_DIR/$abi"
  run cp "$TARGET_DIR/$(abi_triple "$abi")/release/libzenohc.so" "$OUT_DIR/$abi/libzenohc.so"
done

echo ""
if [[ "$DRY_RUN" == "1" ]]; then
  echo "Dry run finished; nothing was changed. A real run writes:"
else
  echo "Android libraries ready:"
fi
for abi in "${ABIS[@]}"; do
  echo "  $OUT_DIR/$abi/libzenohc.so"
done
echo "Activate this version for the app (run from $ROOT_DIR):  bash .claude/skills/zenoh-activate-libs/copy_zenoh_libs.sh $VERSION"
