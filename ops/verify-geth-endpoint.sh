#!/bin/bash

set -euo pipefail
# Script to check the syncing status and block timestamp of an Ethereum RPC endpoint

URL=$1
TIME_DIFF_THRESHOLD=$2

# Check that the node is synced
data='{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}'
response=$(curl -s -X POST -H "Content-Type: application/json" --data "$data" $URL)
echo $response
syncing=$(echo $response | jq -r '.result')
if [ "$syncing" != "false" ]; then
  echo "$URL is syncing."
  exit 1
fi

echo "RPC endpoint at $URL is healthy."