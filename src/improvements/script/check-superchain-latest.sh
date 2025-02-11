#!/usr/bin/env bash
set -euo pipefail

root_dir=$(git rev-parse --show-toplevel)

local_file="${root_dir}/lib/superchain-registry/superchain/extra/addresses/addresses.json"
remote_url="https://raw.githubusercontent.com/ethereum-optimism/superchain-registry/main/superchain/extra/addresses/addresses.json"

if [[ ! -f "$local_file" ]]; then
  echo "Local file not found: ${local_file}"
  exit 1
fi
local_hash=$(sha256sum "$local_file" | awk '{print $1}')

remote_hash=$(curl -sL "$remote_url" | sha256sum | awk '{print $1}')

if [[ "$local_hash" != "$remote_hash" ]]; then
    echo "The addresses file is not up to date."
    echo "Local hash:  $local_hash"
    echo "Remote hash: $remote_hash"
    exit 1
else
    echo "The addresses file is up to date."
    exit 0
fi
