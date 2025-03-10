#!/usr/bin/env bash
# usage: ./generate-calldata-opcm200.sh src/improvements/tasks/sep/000-opcm-upgrade-v200/config.toml
set -euo pipefail

# Check if the required tools are installed
if ! command -v cast &> /dev/null; then
    echo "Error: cast is not installed. Please install foundry."
    exit 1
fi

# Check for jq
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install jq."
    exit 1
fi

# Check for yq (part of yq package)
if ! command -v yq &> /dev/null; then
    echo "Error: yq is not installed. Please install yq with TOML support."
    echo "You can install it with: pip install yq"
    exit 1
fi

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse command line arguments
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Generate calldata for OPCM upgrade"
    echo ""
    echo "Options:"
    echo "  -c, --config FILE    Path to config.toml file (default: same directory as script)"
    echo "  -r, --registry DIR   Path to superchain-registry directory (default: lib/superchain-registry)"
    echo "  -h, --help           Display this help message and exit"
    exit 1
}

# Default config file path
CONFIG_FILE="${SCRIPT_DIR}/config.toml"
# Default registry directory path (relative to the workspace root)
REGISTRY_DIR="lib/superchain-registry"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--config)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: Argument for $1 is missing" >&2
                usage
            fi
            CONFIG_FILE="$2"
            shift 2
            ;;
        -r|--registry)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: Argument for $1 is missing" >&2
                usage
            fi
            REGISTRY_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            ;;
    esac
done

# Check if config.toml exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: config.toml not found at $CONFIG_FILE"
    exit 1
fi

# Check if registry directory exists
if [ ! -d "$REGISTRY_DIR" ]; then
    echo "Error: Registry directory not found at $REGISTRY_DIR"
    exit 1
fi

# Path to addresses.json
ADDRESSES_PATH="${REGISTRY_DIR}/superchain/extra/addresses/addresses.json"

# Check if addresses.json exists
if [ ! -f "$ADDRESSES_PATH" ]; then
    echo "Error: addresses.json not found at $ADDRESSES_PATH"
    exit 1
fi

echo "Using config file: $CONFIG_FILE"
echo "Using registry directory: $REGISTRY_DIR"
echo "Using addresses file: $ADDRESSES_PATH"

# Get OPCM address from config.toml
OPCM_ADDRESS=$(yq -r '.opcmUpgrades.opcmAddress' "$CONFIG_FILE")
echo "OPCM Address: $OPCM_ADDRESS"
echo ""

# Initialize an empty array for the upgrade tuples
UPGRADE_TUPLES=()

# Parse the absolutePrestates array from config.toml
PRESTATES_COUNT=$(yq -r '.opcmUpgrades.absolutePrestates | length' "$CONFIG_FILE")

for i in $(seq 0 $((PRESTATES_COUNT - 1))); do
    CHAIN_ID=$(yq -r ".opcmUpgrades.absolutePrestates[$i].chainId" "$CONFIG_FILE")
    ABSOLUTE_PRESTATE=$(yq -r ".opcmUpgrades.absolutePrestates[$i].absolutePrestate" "$CONFIG_FILE")

    echo "Processing Chain ID: $CHAIN_ID"
    echo "Absolute Prestate: $ABSOLUTE_PRESTATE"

    # Extract SystemConfigProxy and ProxyAdmin addresses from addresses.json
    SYSTEM_CONFIG_PROXY=$(jq -r ".[\"$CHAIN_ID\"].SystemConfigProxy" "$ADDRESSES_PATH")
    PROXY_ADMIN=$(jq -r ".[\"$CHAIN_ID\"].ProxyAdmin" "$ADDRESSES_PATH")

    # Check if addresses were found
    if [ "$SYSTEM_CONFIG_PROXY" == "null" ]; then
        echo "Error: SystemConfigProxy not found for chain ID $CHAIN_ID"
        exit 1
    fi

    if [ "$PROXY_ADMIN" == "null" ]; then
        echo "Error: ProxyAdmin not found for chain ID $CHAIN_ID"
        exit 1
    fi

    echo "SystemConfigProxy: $SYSTEM_CONFIG_PROXY"
    echo "ProxyAdmin: $PROXY_ADMIN"
    echo ""

    # Add to the upgrade tuples
    UPGRADE_TUPLES+=("($SYSTEM_CONFIG_PROXY,$PROXY_ADMIN,$ABSOLUTE_PRESTATE)")
done



# Join the tuples with commas
UPGRADE_TUPLES_STR=$(IFS=,; echo "${UPGRADE_TUPLES[*]}")

# Generate the upgrade calldata
echo "Generating upgrade calldata..."
echo "Function signature: upgrade((address,address,bytes32)[])"
echo "Input: [$UPGRADE_TUPLES_STR]"
UPGRADE_CALLDATA=$(cast calldata "upgrade((address,address,bytes32)[])" "[$UPGRADE_TUPLES_STR]")
echo "Upgrade calldata: $UPGRADE_CALLDATA"
echo ""

# Generate the multicall calldata
echo "Generating multicall calldata..."
echo "Function signature: aggregate3((address,bool,bytes)[])"
echo "Input: [($OPCM_ADDRESS,false,$UPGRADE_CALLDATA)]"
MULTICALL_CALLDATA=$(cast calldata "aggregate3((address,bool,bytes)[])" "[($OPCM_ADDRESS,false,$UPGRADE_CALLDATA)]")
echo "Multicall calldata: $MULTICALL_CALLDATA"
echo ""
