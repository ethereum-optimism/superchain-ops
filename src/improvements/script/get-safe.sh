#!/usr/bin/env bash

# Get the task path from the first argument
TASK_PATH="$1"
# Get the safe name from the third argument
SAFE_NAME="$2"

if [[ -z "$SAFE_NAME" || "$SAFE_NAME" == "null" ]]; then
    echo "Error: Invalid safe name: ${SAFE_NAME}" >&2
    echo "Valid safe names: foundation, council, chain-governor, foundation-operations, base-operations, <custom-safe-name>" >&2
    exit 1
fi

# Convert safe name to the correct format to read the config.toml file.
# In the cases where the safe name is not one of foundation, council, chain-governor, foundation-operations, base-operations then
# tasks should use a custom name to represent the owners of the proxy admin owner. They should put these safes
# under the addresses section of the config.toml file.
if [[ "$SAFE_NAME" == "foundation" ]]; then
    SAFE_NAME="FoundationUpgradeSafe"
elif [[ "$SAFE_NAME" == "council" ]]; then
    SAFE_NAME="SecurityCouncil"
elif [[ "$SAFE_NAME" == "chain-governor" ]]; then
    SAFE_NAME="ChainGovernorSafe"
elif [[ "$SAFE_NAME" == "foundation-operations" ]]; then
    SAFE_NAME="FoundationOperationsSafe"
elif [[ "$SAFE_NAME" == "base-nested" ]]; then
    # This is Base's nested safe, which is a 2/2 between Base and the Base Security
    # Council (SC), which rolls up into a 2/2 between that Safe and the Optimism
    # Foundation for Base's L1PAO.
    SAFE_NAME="BaseNestedSafe"
elif [[ "$SAFE_NAME" == "base-operations" ]]; then
    # This is Base's safe, which one signer on the BaseNestedSafe 2/2.
    SAFE_NAME="BaseOperationsSafe"
elif [[ "$SAFE_NAME" == "base-council" ]]; then
    # This is Base's Security Council safe, which is the other signer on the BaseNestedSafe 2/2.
    SAFE_NAME="BaseSCSafe"
fi

root_dir=$(git rev-parse --show-toplevel)
get_safe_fallback() {
    local config_path="$1"
    local safe_name="$2"
    local fallback_safe

    fallback_safe=$(yq ".addresses.\"$safe_name\"" "$config_path")

    echo "$fallback_safe"
}

# Check if the path contains eth/ or sep/
case "$TASK_PATH" in
    *"/eth/"*)
        safe=$(yq ".eth.\"$SAFE_NAME\"" "${root_dir}/src/improvements/addresses.toml")
        [[ -z "$safe" || "$safe" == "null" ]] && safe=$(get_safe_fallback "${TASK_PATH}/config.toml" "$SAFE_NAME")
        ;;
    *"/sep/"*)
        if [[ "$SAFE_NAME" == "ChainGovernorSafe" ]]; then
            echo "Error: chain-governor does not exist on sepolia" >&2
            exit 1
        fi
        safe=$(yq ".sep.\"$SAFE_NAME\"" "${root_dir}/src/improvements/addresses.toml")
        [[ -z "$safe" || "$safe" == "null" ]] && safe=$(get_safe_fallback "${TASK_PATH}/config.toml" "$SAFE_NAME")
        ;;
    *)
        echo "Error: Task path must contain either /eth/ or /sep/" >&2
        exit 1
        ;;
esac

# Ensure a value was found for the safe
if [[ -z "$safe" || "$safe" == "null" ]]; then
    echo "Error: SAFE_NAME '$SAFE_NAME' not found in ${TASK_PATH}/config.toml" >&2
    exit 1
fi

echo "$safe"