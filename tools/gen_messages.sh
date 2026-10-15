#!/usr/bin/env bash
# Regenerates the Python and Dart bindings for the test messages.
#
#   tools/proto/*.proto  (protobuf)    -> tools/<name>_pb2.py
#                                      -> lib/proto/<name>.pb*.dart
#   tools/fbs/*.fbs      (FlatBuffers) -> tools/<name>_generated.py
#                                      -> lib/fbs/<name>_<namespace>_generated.dart
#
# All outputs are committed, so this only needs to run after a schema changes.
#
# protoc and flatc are taken from the `protoc:` and `flatc:` entries of
# ~/.swarmbotix/sb.config.yml (the ones `sb doctor` validates), falling back
# to PROTOC / FLATC or the ones on PATH. The Dart protobuf generator needs
# `dart pub global activate protoc_plugin` once. At run time the Python
# outputs need `pip install protobuf flatbuffers`.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
py_out="$repo/tools"
sb_config="${SB_CONFIG:-$HOME/.swarmbotix/sb.config.yml}"

# tool_path <sb.config key> <env override> <binary name>
tool_path() {
  local key="$1" override="$2" name="$3" path=""
  path="$override"
  if [[ -z "$path" && -f "$sb_config" ]]; then
    path="$(sed -n "s/^$key:[[:space:]]*//p" "$sb_config" | head -n1)"
    [[ "$path" == "null" ]] && path=""
  fi
  if [[ -z "$path" || ! -x "$path" ]]; then
    path="$(command -v "$name" || true)"
  fi
  if [[ -z "$path" ]]; then
    echo "gen_messages: $name not found (set $key: in $sb_config, or ${override:+\$}${key^^}, or PATH)" >&2
    exit 1
  fi
  echo "$path"
}

protoc="$(tool_path protoc "${PROTOC:-}" protoc)"
flatc="$(tool_path flatc "${FLATC:-}" flatc)"

export PATH="$PATH:$HOME/.pub-cache/bin"
if ! command -v protoc-gen-dart >/dev/null; then
  echo "gen_messages: protoc-gen-dart not found; run: dart pub global activate protoc_plugin" >&2
  exit 1
fi

mkdir -p "$py_out" "$repo/lib/proto" "$repo/lib/fbs"

echo "gen_messages: protoc $("$protoc" --version) at $protoc"
for f in "$repo"/tools/proto/*.proto; do
  echo "gen_messages: $(basename "$f")"
  "$protoc" -I "$repo/tools/proto" --python_out="$py_out" --dart_out="$repo/lib/proto" "$f"
done

echo "gen_messages: flatc $("$flatc" --version | awk '{print $NF}') at $flatc"
for f in "$repo"/tools/fbs/*.fbs; do
  echo "gen_messages: $(basename "$f")"
  "$flatc" --python --gen-onefile -o "$py_out" "$f"
  "$flatc" --dart -o "$repo/lib/fbs" "$f"
done
echo "gen_messages: done"
