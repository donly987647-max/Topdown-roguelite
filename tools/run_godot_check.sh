#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: $0 <success-marker-or-dash> <godot-args...>" >&2
  exit 2
fi

success_marker="$1"
shift
godot_bin="${GODOT_BIN:-godot}"
timeout_seconds="${GODOT_TEST_TIMEOUT_SECONDS:-90}"
log_file="$(mktemp)"
trap 'rm -f "$log_file"' EXIT

set +e
timeout "${timeout_seconds}s" "$godot_bin" "$@" >"$log_file" 2>&1
status=$?
set -e

sed -n '1,400p' "$log_file"

if [[ $status -ne 0 ]]; then
  echo "Godot command failed or timed out (exit $status)." >&2
  exit "$status"
fi

if grep -Eq 'SCRIPT ERROR:|Parse Error:|Compile Error:|^ERROR:|Invalid call\.' "$log_file"; then
  echo "Godot emitted a parser, compiler, script, or runtime error." >&2
  exit 1
fi

if [[ "$success_marker" != "-" ]] && ! grep -Fq "$success_marker" "$log_file"; then
  echo "Missing success marker: $success_marker" >&2
  exit 1
fi
