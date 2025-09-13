#!/usr/bin/env bash
set -euo pipefail

NETWORK="${1:-}"
if [ -z "${NETWORK}" ]; then
    echo "Error: Must provide a network short name (e.g., eth, sep, oeth, opsep)." >&2
    exit 1
fi

# The keys correspond to the task directory names and are official short names defined here: https://chainid.network/shortNameMapping.json
# The values correspond to the RPC URL keys in foundry.toml
declare -A net_to_key=(
    [sep]=sepolia
    [eth]=mainnet
    [oeth]=opMainnet
    [opsep]=opSepolia
)

key="${net_to_key[${NETWORK}]:-}"
if [ -z "${key}" ]; then
    echo "Error: Must provide a valid network, '${NETWORK}' is not valid." >&2
    exit 1
fi

echo "${key}"
