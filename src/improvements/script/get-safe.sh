#!/usr/bin/env bash

# Get the task path from the first argument
TASK_PATH="$1"
# Get the safe name from the third argument
SAFE_NAME="$2"

# Convert safe name to the correct format to read the config.toml file.
# Some chains do not have the concepts of foundation, council, or chain-governor.
# In these cases, we default to using the child-safe-1 and child-safe-2 etc to represent the 
# owners of the proxy admin owner.
if [[ "$SAFE_NAME" == "foundation" ]]; then
    SAFE_NAME="FoundationUpgradeSafe"
elif [[ "$SAFE_NAME" == "council" ]]; then
    SAFE_NAME="SecurityCouncil"
elif [[ "$SAFE_NAME" == "chain-governor" ]]; then
    SAFE_NAME="ChainGovernorSafe"
elif [[ "$SAFE_NAME" == "child-safe-1" ]]; then
    SAFE_NAME="ChildSafe1"
elif [[ "$SAFE_NAME" == "child-safe-2" ]]; then
    SAFE_NAME="ChildSafe2"
# Optionally add child-safe-3, child-safe-4, if necessary etc.
else
    echo "Error: Invalid safe name: ${SAFE_NAME}" >&2
    echo "Valid safe names: foundation, council, chain-governor, child-safe-1, child-safe-2" >&2
    exit 1
fi

# Check if the path contains eth/ or sep/
if [[ "$TASK_PATH" == *"/eth/"* ]]; then
    safe=$(yq ".addresses.\"$SAFE_NAME\"" "${TASK_PATH}/config.toml")
elif [[ "$TASK_PATH" == *"/sep/"* ]]; then
    if [[ "$SAFE_NAME" == "ChainGovernorSafe" ]]; then
        echo "Error: chain-governor does not exist on sepolia" >&2
        exit 1
    fi
    safe=$(yq ".addresses.\"$SAFE_NAME\"" "${TASK_PATH}/config.toml")
else
    echo "Error: Task path must contain either /eth/ or /sep/" >&2
    exit 1
fi

# Ensure a value was found for the safe
if [[ -z "$safe" || "$safe" == "null" ]]; then
    echo "Error: SAFE_NAME '$SAFE_NAME' not found in ${TASK_PATH}/config.toml" >&2
    exit 1
fi

echo "$safe"