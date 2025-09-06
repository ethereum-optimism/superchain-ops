#!/usr/bin/env bash

# This file gets the RPC URL that the task will be executed on.
# Get the task path from the first argument
TASK_PATH="$1"

# The directory names are official short names defined here: https://chainid.network/shortNameMapping.json
# Check if the path contains eth/ or sep/
if [[ "$TASK_PATH" == *"/eth/"* ]]; then
    echo "mainnet"
elif [[ "$TASK_PATH" == *"/sep/"* ]]; then
    echo "sepolia"
elif [[ "$TASK_PATH" == *"/oeth/"* ]]; then
    echo "opMainnet"
else
    echo "Error: Task path must contain either /eth/ or /sep/ or /oeth/" >&2
    exit 1
fi
