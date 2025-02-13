#!/usr/bin/env bash

# Get the task path from the first argument
TASK_PATH="$1"

# Check if the path contains eth/ or sep/
if [[ "$TASK_PATH" == *"/eth/"* ]]; then
    echo "mainnet"
elif [[ "$TASK_PATH" == *"/sep/"* ]]; then
    echo "sepolia"
else
    echo "Error: Task path must contain either /eth/ or /sep/" >&2
    exit 1
fi
