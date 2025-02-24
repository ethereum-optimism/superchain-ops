#!/usr/bin/env bash

# Get the task path from the first argument
TASK_PATH="$1"
SCRIPT_PATH="$2"
SAFE_NAME="$3"


# Convert safe name to the correct format
if [[ "$SAFE_NAME" == "foundation" ]]; then
    SAFE_NAME="FoundationUpgradeSafe"
elif [[ "$SAFE_NAME" == "council" ]]; then
    SAFE_NAME="SecurityCouncil"
else
    echo "Error: Invalid safe name" >&2
    exit 1
fi

# Check if the path contains eth/ or sep/
if [[ "$TASK_PATH" == *"/eth/"* ]]; then
    safe=$(yq '.mainnetAddresses[] | select(.identifier == "'"$SAFE_NAME"'") | .addr' ${SCRIPT_PATH}/addresses.toml)
elif [[ "$TASK_PATH" == *"/sep/"* ]]; then
    safe=$(yq '.testnetAddresses[] | select(.identifier == "'"$SAFE_NAME"'") | .addr' ${SCRIPT_PATH}/addresses.toml)
else
    echo "Error: Task path must contain either /eth/ or /sep/" >&2
    exit 1
fi

echo "$safe"