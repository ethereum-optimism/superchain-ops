#!/bin/bash

set -euo pipefail
# Script to check the syncing status and block timestamp of an Ethereum RPC endpoint

URL=$1
TIME_DIFF_THRESHOLD=$2

get_current_block() {
    data='{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
    # shellcheck disable=SC2086
    response=$(curl -s -X POST -H "Content-Type: application/json" --data "$data" $URL)
    hex=$(echo "$response" | jq -r '.result')
    trimmed_hex=${hex#0x}
    echo $((16#$trimmed_hex))
}

# Check that the node is synced
data='{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}'
response=$(curl -s -X POST -H "Content-Type: application/json" --data "$data" "$URL")
syncing=$(echo "$response" | jq -r '.result')
if [ "$syncing" != "false" ]; then
  echo "$URL is syncing."
  exit 1
fi
echo "Replica is not syncing."

first_block=$(get_current_block)
echo "First block: $first_block"

if [ "$first_block" -eq 0 ]; then
  echo "Block height is 0."
  exit 1
fi

sleep 15

second_block=$(get_current_block)
echo "Second block: $second_block"
if [ "$first_block" -ge "$second_block" ]; then
  echo "Block height is not increasing."
  exit 1
fi


echo "RPC endpoint at $URL is healthy."
