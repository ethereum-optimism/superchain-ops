#!/usr/bin/env bash

# This file gets the RPC URL that the task will be executed on.
# Get the task path from the first argument
TASK_PATH="$1"

# The directory names are official short names defined here: https://chainid.network/shortNameMapping.json
if [[ "$TASK_PATH" == *"/eth/"* ]]; then
    echo "mainnet"
elif [[ "$TASK_PATH" == *"/sep/"* ]]; then
    echo "sepolia"
elif [[ "$TASK_PATH" == *"/opsep/"* ]]; then
    echo "opSepolia"
elif [[ "$TASK_PATH" == *"/oeth/"* ]]; then
    echo "opMainnet"
else
    echo "Error: Task path must contain either /eth/ or /sep/ or /opsep/" >&2
    exit 1
fi
