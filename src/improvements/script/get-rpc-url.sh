#!/usr/bin/env bash
set -euo pipefail

NETWORK="$1"

# The directory names are official short names defined here: https://chainid.network/shortNameMapping.json
declare -A net_to_key=(
    [sep]=sepolia
    [eth]=mainnet
    [oeth]=opMainnet
    [opsep]=opSepolia
)
key="${net_to_key[{{NETWORK}}]:-}"
if [ -z "${key}" ]; then
    echo "Error: Must provide a valid network, '{{NETWORK}}' is not valid." >&2
    exit 1
fi

echo "${key}"
