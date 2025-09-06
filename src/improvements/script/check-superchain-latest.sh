#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# Overview:
#   Verify that the local lib/superchain-registry addresses.json file is
#   compatible with the remote version in the upstream Superchain Registry repo,
#   by comparing the L1StandardBridgeProxy and SystemConfigProxy addresses for
#   each chain ID. This script will exit with a non-zero exit code if any
#   differences are detected. It will NOT exit with a non-zero exit code if
#   all chains present in the local file match, but the remote file has
#   additional chains, to reduce the number of false positives.
#
#   It only checks those two keys per chain because the superchain-ops repo
#   starts from the L1StandardBridgeProxy address to discover the rest of the
#   chain addresses, and checking all addresses seemed to cause performance
#   issues. Therefore we probably could even remove the SystemConfigProxy
#   check, but it's there for good measure.
#
# Usage:
#   Production:
#     bash check-superchain-latest.sh
#
#   Debug/Test:
#     - Create a local `addresses.json` file that has some differences from the
#       local version, where you'd expect a success or failure based on the diff.
#     - Uncomment and set the `remote_file` variable to the path of your local
#       `addresses.json` file, instead of the network-fetched version.
#     - Run the script.
# ------------------------------------------------------------------------------

# Paths.
root_dir=$(git rev-parse --show-toplevel)
local_file="$root_dir/lib/superchain-registry/superchain/extra/addresses/addresses.json"
remote_url="https://raw.githubusercontent.com/ethereum-optimism/superchain-registry/main/superchain/extra/addresses/addresses.json"
remote_file=$(mktemp)

[[ -f "$local_file" ]] || { echo "Error: Local file not found: $local_file" >&2; exit 1; }

# Fetch remote JSON.
curl -sL "$remote_url" -o "$remote_file"

# For testing, skip curl and point at a local “remote” copy.
# remote_file="/absolute/path/to/your/test/addresses.json"

# Comparison block (jq filter):
# - Iterates over each chainId in the local JSON.
# - For each chain, only checks two keys: L1StandardBridgeProxy and SystemConfigProxy.
# - Uses `// null` to safely handle missing keys without errors.
# - Emits specific error messages if:
#     - local key is missing
#     - remote key is missing
#     - addresses differ between local and remote
# - Joins the results for both keys into one string per chain.
comparison=$(jq -n -r --argfile L "$local_file" --argfile R "$remote_file" '
  reduce ($L | keys[]) as $chain (""; . +
    (
      ["L1StandardBridgeProxy","SystemConfigProxy"]         # List of proxy keys to check
      | map(
          ($chain as $ch | . as $proxy |                       # For each proxy under this chain
             ($L[$ch][$proxy] // null) as $laddr |              # Get local address or null
             ($R[$ch][$proxy] // null) as $raddr |              # Get remote address or null
             if $laddr == null then                            # If local missing
               "Error: local missing \($proxy) on chain \($ch)\n"
             elif $raddr == null then                          # If remote missing
               "Error: remote missing \($proxy) on chain \($ch)\n"
             elif $laddr != $raddr then                        # If addresses differ
               "Error: address mismatch for \($proxy) on chain \($ch)\n  Local:  \($laddr)\n  Remote: \($raddr)\n"
             else                                              # No error if they match
               ""
             end
          )
      )
      | join("")                                             # Concatenate both proxy checks
    )
  )
')

# Cleanup: remove temp remote file if it came from mktemp.
if [[ "$remote_file" == *"tmp"* ]]; then
  rm -f "$remote_file"
fi

# Report results.
if [[ -n "$comparison" ]]; then
  echo "❌ Differences detected:" >&2
  printf "%b" "$comparison" >&2
  exit 1
else
  echo "✅ All L1StandardBridgeProxy & SystemConfigProxy addresses match."
fi
