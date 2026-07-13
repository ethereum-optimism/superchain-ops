---
name: fix-check-superchain-registry
description: Diagnose and fix a failing `check_superchain_registry` CircleCI job on superchain-ops, typically caused by the pinned lib/superchain-registry submodule drifting from upstream main.
---

# Fix `check_superchain_registry` CI failure

## What the check does

The CI chain is:

- `.circleci/config.yml` job `check_superchain_registry`
- -> `src/ci.just` recipe `check-superchain-registry-latest`
- -> `src/script/check-superchain-latest.sh`

The script compares the **pinned** submodule file
`lib/superchain-registry/superchain/extra/addresses/addresses.json`
against the **live upstream** file at
`https://raw.githubusercontent.com/ethereum-optimism/superchain-registry/main/superchain/extra/addresses/addresses.json`.

For every chain ID present in the *pinned* file it checks two keys —
`L1StandardBridgeProxy` and `SystemConfigProxy` — and fails (exit 1) if a key
is missing upstream or the addresses mismatch. It emits lines like:

```
Error: remote missing L1StandardBridgeProxy on chain <ID>
```

The check is **asymmetric**: it tolerates upstream having *extra* chains the
pinned file lacks, but hard-fails when the pinned file lists a chain that
upstream has *removed*. So the recurring cause is upstream deleting a chain
(e.g. rehearsal/test networks) while our submodule still points at the older
commit that includes it.

## Fast diagnosis

Reproduce locally without CI:

```bash
# Pinned (local submodule) file:
LOCAL=lib/superchain-registry/superchain/extra/addresses/addresses.json

# Live upstream main:
curl -sL "https://raw.githubusercontent.com/ethereum-optimism/superchain-registry/main/superchain/extra/addresses/addresses.json" -o /tmp/remote-addresses.json

# List chain IDs present locally but absent upstream (these are what break the check):
jq -n --slurpfile L "$LOCAL" --slurpfile R /tmp/remote-addresses.json \
  '$L[0] | keys[] | select(($R[0][.]) == null)'
```

Or just run the check itself: `just check-superchain-registry-latest` (or
`bash src/script/check-superchain-latest.sh`). The `Error: remote missing ...`
lines name the offending chain IDs.

## The fix

Bump the `lib/superchain-registry` submodule to current upstream `main`. This
is a one-line gitlink change.

1. Get upstream main HEAD SHA. If `git ls-remote` / GitHub API are blocked in
   your environment, the commits page or its `.atom` feed
   (`https://github.com/ethereum-optimism/superchain-registry/commits/main.atom`)
   expose the SHA, and `raw.githubusercontent.com` works for file content.
2. **Before bumping, confirm no in-repo task references the removed chain IDs**
   (search `src/tasks/` and configs). If a live task still needs a removed
   chain, escalate instead of bumping.
3. Update the gitlink:
   - If the submodule can be fetched:
     `git -C lib/superchain-registry fetch && git -C lib/superchain-registry checkout <SHA> && git add lib/superchain-registry`
   - If the registry remote is unfetchable but you have the SHA:
     `git update-index --cacheinfo 160000,<SHA>,lib/superchain-registry`
4. Verify **only** the gitlink changed: `git diff --cached --stat` should show
   a single line for `lib/superchain-registry`.
5. Commit and open a PR. CI re-runs the check against the newly pinned commit.

## Note on strictness / longer-term fix

The recurring root cause is the check's structural strictness: it hard-fails on
any upstream chain *removal*, even though a removed chain is harmless to
superchain-ops. A longer-term option (for maintainers, not part of the routine
fix) is to treat "remote missing" as a warning rather than a hard failure,
while still hard-failing on address *mismatches*. Do not implement that as part
of a routine drift bump.
