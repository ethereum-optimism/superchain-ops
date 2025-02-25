#!/usr/bin/env bash

# Get the task path from the first argument
TASK_PATH="$1"
# Get the path to the addresses.toml file directory from the second argument
TOML_PATH="$2"
# Get the safe name from the third argument
SAFE_NAME="$3"


# Convert safe name to the correct format
if [[ "$SAFE_NAME" == "foundation" ]]; then
    SAFE_NAME="FoundationUpgradeSafe"
elif [[ "$SAFE_NAME" == "council" ]]; then
    SAFE_NAME="SecurityCouncil"
elif [[ "$SAFE_NAME" == "chain-governor" ]]; then
    SAFE_NAME="ChainGovernorSafe"
else
    echo "Error: Invalid safe name: ${SAFE_NAME}" >&2
    echo "Valid safe names: foundation, council, chain-governor" >&2
    exit 1
fi

# Check if the path contains eth/ or sep/
if [[ "$TASK_PATH" == *"/eth/"* ]]; then
    safe=$(yq '.mainnetAddresses[] | select(.identifier == "'"$SAFE_NAME"'") | .addr' ${TOML_PATH}/addresses.toml)
elif [[ "$TASK_PATH" == *"/sep/"* ]]; then
    if [[ "$SAFE_NAME" == "ChainGovernorSafe" ]]; then
        echo "Error: chain-governor does not exist on sepolia" >&2
        exit 1
    fi
    safe=$(yq '.testnetAddresses[] | select(.identifier == "'"$SAFE_NAME"'") | .addr' ${TOML_PATH}/addresses.toml)
else
    echo "Error: Task path must contain either /eth/ or /sep/" >&2
    exit 1
fi

echo "$safe"