#!/usr/bin/env bash
set -euo pipefail

for cmd in gh jq yq; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Error: $cmd is required." >&2; exit 1; }
done

if [ -z "${GH_TOKEN:-}" ] && [ -n "${GITHUB_TOKEN:-}" ]; then
  export GH_TOKEN="$GITHUB_TOKEN"
fi
if [ -z "${GH_TOKEN:-}" ]; then
  echo "Error: GH_TOKEN (or GITHUB_TOKEN) is required." >&2
  exit 1
fi

repo="${CIRCLE_PROJECT_USERNAME:-}/${CIRCLE_PROJECT_REPONAME:-}"
if [ "$repo" = "/" ]; then
  repo="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
fi

nonce_slot="0x0000000000000000000000000000000000000000000000000000000000000005"
tmp_entries="$(mktemp)"
tmp_nonces="$(mktemp)"
tmp_errors="$(mktemp)"
trap 'rm -f "$tmp_entries" "$tmp_nonces" "$tmp_errors"' EXIT

gh api "/repos/$repo/pulls?state=open&per_page=100" --paginate -q '.[] | [.number,.head.sha] | @tsv' |
while IFS=$'\t' read -r pr sha; do
  gh api "/repos/$repo/pulls/$pr/files?per_page=100" --paginate -q '.[].filename' |
  while IFS= read -r path; do
    if [[ "$path" =~ ^(src/tasks/(eth|sep)|test/tasks/example/(eth|sep))/([^/]+)/ ]]; then
      base="${BASH_REMATCH[1]}"
      task_dir="${BASH_REMATCH[4]}"
      [[ "$task_dir" =~ ^([0-9]{3})- ]] || continue
      task_num="${BASH_REMATCH[1]}"
      printf '%s|%s|%s|%s|%s\n' "$base" "$pr" "$task_dir" "$task_num" "$sha"
    fi
  done
done | sort -u > "$tmp_entries"

awk -F'|' '
  { key=$1 FS $4; prs[key]=prs[key] ? prs[key] "," $2 : $2 }
  END {
    for (k in prs) {
      n=split(prs[k], a, ",");
      if (n > 1) {
        split(k, b, FS);
        printf "ERROR: duplicate task number %s in %s across PRs %s\n", b[2], b[1], prs[k];
      }
    }
  }
' "$tmp_entries" > "$tmp_errors"

while IFS='|' read -r base pr task_dir task_num sha; do
  config_path="$base/$task_dir/config.toml"
  content="$(gh api "/repos/$repo/contents/$config_path?ref=$sha" -q .content 2>/dev/null | base64 --decode || true)"
  [ -n "$content" ] || continue
  printf '%s' "$content" |
    yq -p=toml -o=json '.stateOverrides // {}' |
    jq -r --arg slot "$nonce_slot" '
      to_entries[] | .key as $addr | (.value // [])[] |
      select((.key|ascii_downcase) == ($slot|ascii_downcase)) |
      "\($addr)|\(.value|tostring)"
    ' |
    while IFS='|' read -r addr nonce; do
      addr="$(printf '%s' "$addr" | tr 'A-F' 'a-f')"
      if [[ "$nonce" =~ ^0x ]]; then
        nonce="$((nonce))"
      fi
      printf '%s|%s|%s|%s\n' "$base" "$pr" "$addr" "$nonce"
    done
done < "$tmp_entries" | sort -u > "$tmp_nonces"

awk -F'|' '
  { key=$1 FS $3 FS $4; prs[key]=prs[key] ? prs[key] "," $2 : $2 }
  END {
    for (k in prs) {
      n=split(prs[k], a, ",");
      if (n > 1) {
        split(k, b, FS);
        printf "ERROR: duplicate nonce %s for %s in %s across PRs %s\n", b[3], b[2], b[1], prs[k];
      }
    }
  }
' "$tmp_nonces" >> "$tmp_errors"

if [ -s "$tmp_errors" ]; then
  cat "$tmp_errors" >&2
  exit 1
fi

echo "OK: open PR task numbering and nonces are unique"
