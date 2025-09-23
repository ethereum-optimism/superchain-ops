#!/usr/bin/env bash
set -euo pipefail

TASK_PATH="$1"
SAFE_NAME="$2"

if [[ -z "$SAFE_NAME" || "$SAFE_NAME" == "null" ]]; then
    echo "Error (get-safe.sh): Invalid safe name: ${SAFE_NAME}" >&2
    echo "Valid safe names: foundation, council, chain-governor, foundation-operations, base-operations, <custom-safe-name>" >&2
    exit 1
fi

ROOT_DIR=$(git rev-parse --show-toplevel)
ADDRESSES_FILE="${ROOT_DIR}/src/addresses.toml"
CONFIG_PATH="${TASK_PATH}/config.toml"

canonicalize_safe_name() {
    local input_name="$1"
    case "$input_name" in
        foundation) echo "FoundationUpgradeSafe" ;;
        council) echo "SecurityCouncil" ;;
        chain-governor) echo "ChainGovernorSafe" ;;
        foundation-operations) echo "FoundationOperationsSafe" ;;
        base-nested) echo "BaseNestedSafe" ;;
        base-operations) echo "BaseOperationsSafe" ;;
        base-council) echo "BaseSCSafe" ;;
        test-rehearsal-council) echo "TestRehearsalCouncil" ;;
        test-rehearsal-foundation) echo "TestRehearsalFoundation" ;;
        *) echo "$input_name" ;;
    esac
}

SAFE_NAME=$(canonicalize_safe_name "$SAFE_NAME")
get_safe_fallback() {
    local config_path="$1"
    local safe_name="$2"
    local fallback_safe

    fallback_safe=$(yq ".addresses.\"$safe_name\"" "$config_path")

    echo "$fallback_safe"
}

lookup_safe_address() {
    local network="$1"
    local safe_name="$2"
    local value
    value=$(yq ".${network}.\"$safe_name\"" "$ADDRESSES_FILE")
    if [[ -z "$value" || "$value" == "null" ]]; then
        value=$(get_safe_fallback "$CONFIG_PATH" "$safe_name")
    fi
    echo "$value"
}

case "$TASK_PATH" in
    *"/eth/"*) network="eth" ;;
    *"/sep/"*) network="sep" ;;
    *"/opsep/"*) network="opsep" ;;
    *"/oeth/"*) network="oeth" ;;
    *)
        echo "Error (get-safe.sh): Task path must contain either /eth/ or /sep/ or /opsep/" >&2
        exit 1
        ;;
esac

if [[ "$network" == "sep" && "$SAFE_NAME" == "ChainGovernorSafe" ]]; then
    echo "Error (get-safe.sh): chain-governor does not exist on sepolia" >&2
    exit 1
fi

safe=$(lookup_safe_address "$network" "$SAFE_NAME")

if [[ -z "$safe" || "$safe" == "null" ]]; then
    echo "Error (get-safe.sh): SAFE_NAME '$SAFE_NAME' not found in ${TASK_PATH}/config.toml" >&2
    exit 1
fi

echo "$safe"