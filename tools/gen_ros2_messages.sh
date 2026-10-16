#!/usr/bin/env bash
# Regenerates the Dart bindings for the ros2 messages the app decodes, from
# the sb message vault (<messages_root>/ros2/message_definitions).
#
#   protobuf     PROTO_MESSAGES + imports -> lib/proto/ros2/<pkg>/<Leaf>.pb*.dart
#   FlatBuffers  FB_MESSAGES + imports    -> lib/fbs/ros2/<Leaf>_<pkg>_generated.dart
#
# sb's proto backend emits no Dart, so this runs `protoc --dart_out` over the
# vault .proto files itself. For FlatBuffers it repeats what
# `sb message compile --fb` does (sbcli_messages.md §5.3): `flatc --proto`
# turns each .proto into a .fbs, one staging directory per package, then
# `flatc --dart` compiles each .fbs with the package directories of its
# imports as -I. When sb has compiled the type, the binary schema of the
# staged .fbs is compared with sb's <message_targets>/fb/<pkg>/<Leaf>/<Leaf>.bfbs,
# so a layout that differs from the one the Python publisher uses fails here.
#
# Both output directories are rewritten from scratch. All outputs are
# committed, so this only needs to run after the message list or the vault
# changes. The decoders that use them are lib/topics/proto_decoder.dart and
# lib/topics/fb_decoder.dart.
#
# protoc, flatc and the vault root are taken from the `protoc:`, `flatc:` and
# `messages_root:` entries of ~/.swarmbotix/sb.config.yml (the ones
# `sb doctor` validates), falling back to PROTOC / FLATC / SB_MESSAGES_ROOT,
# then to PATH and ~/.swarmbotix/messages. The Dart protobuf generator needs
# `dart pub global activate protoc_plugin` once.
set -euo pipefail

# Vault names (<pkg>/<Leaf>, style ros2) the app decodes. Their imports are
# added automatically. <pkg> is the vault directory, which for custom/ is not
# the protobuf package (custom/*.proto declare `package swarmbotix.custom`).
PROTO_MESSAGES=(
  sensor_msgs/Imu
  sensor_msgs/CompressedImage
  sensor_msgs/Image
  std_msgs/String
  std_msgs/UInt8MultiArray
  custom/MarkerDetections
  custom/CubePoses
)
FB_MESSAGES=(
  sensor_msgs/Temperature
)

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
sb_config="${SB_CONFIG:-$HOME/.swarmbotix/sb.config.yml}"
proto_out="$repo/lib/proto/ros2"
fb_out="$repo/lib/fbs/ros2"

say() { echo "gen_ros2_messages: $*"; }
die() { echo "gen_ros2_messages: $*" >&2; exit 1; }

# config_value <sb.config key>: the value, or nothing for a missing or null key.
config_value() {
  local value=""
  if [[ -f "$sb_config" ]]; then
    value="$(sed -n "s/^$1:[[:space:]]*//p" "$sb_config" | head -n1)"
    value="${value%%[[:space:]]#*}"
    [[ "$value" == "null" ]] && value=""
  fi
  echo "$value"
}

# tool_path <sb.config key> <env override> <binary name>
tool_path() {
  local key="$1" path="$2" name="$3"
  [[ -z "$path" ]] && path="$(config_value "$key")"
  if [[ -z "$path" || ! -x "$path" ]]; then
    path="$(command -v "$name" || true)"
  fi
  [[ -n "$path" ]] || die "$name not found (set $key: in $sb_config, ${key^^}=..., or put it on PATH)"
  echo "$path"
}

protoc="$(tool_path protoc "${PROTOC:-}" protoc)"
flatc="$(tool_path flatc "${FLATC:-}" flatc)"

messages_root="${SB_MESSAGES_ROOT:-$(config_value messages_root)}"
messages_root="${messages_root:-$HOME/.swarmbotix/messages}"
defs="$messages_root/ros2/message_definitions"
targets="$messages_root/ros2/message_targets"
[[ -d "$defs" ]] || die "vault definitions not found at $defs"

export PATH="$PATH:$HOME/.pub-cache/bin"
command -v protoc-gen-dart >/dev/null ||
  die "protoc-gen-dart not found; run: dart pub global activate protoc_plugin"

# with_imports <pkg/Leaf>...: the messages and everything they import,
# transitively, once each, as <pkg>/<Leaf>.
with_imports() {
  local -a queue=("$@")
  local -A seen=()
  local msg dep
  while ((${#queue[@]})); do
    msg="${queue[0]}"
    queue=("${queue[@]:1}")
    [[ -n "${seen[$msg]:-}" ]] && continue
    seen[$msg]=1
    [[ -f "$defs/$msg.proto" ]] || die "no $msg.proto in $defs"
    echo "$msg"
    while read -r dep; do
      queue+=("${dep%.proto}")
    done < <(sed -n 's/^[[:space:]]*import[[:space:]]*"\([^"]*\)".*/\1/p' "$defs/$msg.proto")
  done
}

# --- protobuf ---------------------------------------------------------------
mapfile -t proto_all < <(with_imports "${PROTO_MESSAGES[@]}" | sort)
say "protoc $("$protoc" --version) at $protoc"
rm -rf "$proto_out"
mkdir -p "$proto_out"
(cd "$defs" && "$protoc" -I "$defs" --dart_out="$proto_out" "${proto_all[@]/%/.proto}")
for msg in "${proto_all[@]}"; do say "proto $msg"; done

# --- FlatBuffers ------------------------------------------------------------
mapfile -t fb_all < <(with_imports "${FB_MESSAGES[@]}" | sort)
say "flatc $("$flatc" --version | awk '{print $NF}') at $flatc"
stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT

# 1. .proto -> .fbs, one staging directory per package (flatc names the
#    output by leaf only). flatc warns that it cannot generate code from a
#    .proto; that is expected here, so its output is shown only on failure.
for msg in "${fb_all[@]}"; do
  mkdir -p "$stage/fbs/${msg%/*}"
  if ! log="$(cd "$defs" && "$flatc" --proto -I "$defs" -o "$stage/fbs/${msg%/*}" "$msg.proto" 2>&1)"; then
    echo "$log" >&2
    die "flatc --proto failed for $msg"
  fi
done

# 2. .fbs -> Dart, with -I for exactly the packages the message imports, as
#    sb does (a wrong Header.fbs on the path would shadow the right one).
rm -rf "$fb_out"
mkdir -p "$fb_out" "$stage/bfbs"
for msg in "${fb_all[@]}"; do
  include=()
  while read -r dep; do
    [[ "$dep" == "$msg" ]] || include+=(-I "$stage/fbs/${dep%/*}")
  done < <(with_imports "$msg")
  fbs="$stage/fbs/$msg.fbs"
  "$flatc" --dart "${include[@]}" -o "$fb_out" "$fbs"

  # 3. Same layout as sb's compiled schema, when sb has one.
  sb_bfbs="$targets/fb/$msg/${msg#*/}.bfbs"
  if [[ -f "$sb_bfbs" ]]; then
    "$flatc" -b --schema "${include[@]}" -o "$stage/bfbs/${msg%/*}" "$fbs"
    cmp -s "$stage/bfbs/$msg.bfbs" "$sb_bfbs" ||
      die "$msg: schema differs from sb's $sb_bfbs; recompile with sb message compile ros2/$msg --fb"
    say "fb $msg (matches sb's .bfbs)"
  else
    say "fb $msg (sb has not compiled it; layout not cross-checked)"
  fi
done
say "done"
