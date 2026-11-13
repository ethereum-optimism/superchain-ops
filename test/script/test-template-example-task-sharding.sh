#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
script="$repo_root/src/script/list-template-example-tasks.sh"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p \
  "$tmpdir/test/tasks/example/eth/001-alpha" \
  "$tmpdir/test/tasks/example/eth/002-beta" \
  "$tmpdir/test/tasks/example/sep/003-gamma" \
  "$tmpdir/test/tasks/example/sep/023-u13-to-u16a" \
  "$tmpdir/test/tasks/example/sep/036-opcm-migrate-v800" \
  "$tmpdir/test/tasks/example/sep/040-delta"

all_tasks=$("$script" "$tmpdir")
expected_all=$(printf '%s\n' \
  "$tmpdir/test/tasks/example/eth/001-alpha" \
  "$tmpdir/test/tasks/example/eth/002-beta" \
  "$tmpdir/test/tasks/example/sep/003-gamma" \
  "$tmpdir/test/tasks/example/sep/040-delta")

if [ "$all_tasks" != "$expected_all" ]; then
  echo "Expected default selection to include every non-skipped task in sort order" >&2
  printf 'expected:\n%s\n' "$expected_all" >&2
  printf 'actual:\n%s\n' "$all_tasks" >&2
  exit 1
fi

shard_0=$(CIRCLE_NODE_TOTAL=3 CIRCLE_NODE_INDEX=0 "$script" "$tmpdir")
shard_1=$(CIRCLE_NODE_TOTAL=3 CIRCLE_NODE_INDEX=1 "$script" "$tmpdir")
shard_2=$(CIRCLE_NODE_TOTAL=3 CIRCLE_NODE_INDEX=2 "$script" "$tmpdir")

expected_shard_0=$(printf '%s\n' \
  "$tmpdir/test/tasks/example/eth/001-alpha" \
  "$tmpdir/test/tasks/example/sep/040-delta")
expected_shard_1="$tmpdir/test/tasks/example/eth/002-beta"
expected_shard_2="$tmpdir/test/tasks/example/sep/003-gamma"

if [ "$shard_0" != "$expected_shard_0" ]; then
  echo "Unexpected shard 0 selection" >&2
  exit 1
fi

if [ "$shard_1" != "$expected_shard_1" ]; then
  echo "Unexpected shard 1 selection" >&2
  exit 1
fi

if [ "$shard_2" != "$expected_shard_2" ]; then
  echo "Unexpected shard 2 selection" >&2
  exit 1
fi

if CIRCLE_NODE_TOTAL=3 CIRCLE_NODE_INDEX=3 "$script" "$tmpdir" >/dev/null 2>&1; then
  echo "Expected out-of-range CIRCLE_NODE_INDEX to fail" >&2
  exit 1
fi

if CIRCLE_NODE_TOTAL=0 CIRCLE_NODE_INDEX=0 "$script" "$tmpdir" >/dev/null 2>&1; then
  echo "Expected zero CIRCLE_NODE_TOTAL to fail" >&2
  exit 1
fi
