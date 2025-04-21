#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------
# Script to fetch the latest storage layout for a given contract.
#
# This script:
# 1. Reads the latest release tag from the main branch of the
#    `superchain-registry` repository.
# 2. Uses that tag to download the corresponding storage layout
#    JSON file from the `optimism` monorepo.
#
# Usage:
#   ./fetch-latest-storage-layout.sh <contract-name>
#
# Example:
#   ./fetch-latest-storage-layout.sh L2StandardBridge
#
# Requirements:
# - `curl` for HTTP requests
# - `yq` for parsing the TOML standard-versions file
#
# Exits with an error if the contract name is missing or empty.
# -----------------------------------------------------------

contract_name_arg="${1:-}"

# Check if contract name is unset or only whitespace
if [[ -z "${contract_name_arg// }" ]]; then
  echo "Usage: $0 <contract-name>"
  echo "Error: Contract name is required and cannot be empty"
  exit 1
fi

fetch_latest_storage_layout() {
    local contract_name=$1
    # Read from main branch of superchain-registry to ensure we're always using the latest release tag.
    remote_url_standard_versions="https://raw.githubusercontent.com/ethereum-optimism/superchain-registry/refs/heads/main/validation/standard/standard-versions-mainnet.toml"
    remote_toml_standard_versions=$(curl -sL "$remote_url_standard_versions")

    latest_release_tag=$(echo "$remote_toml_standard_versions" | yq -p=toml 'keys | .[0]')

    remote_url_storage_layout="https://raw.githubusercontent.com/ethereum-optimism/optimism/refs/tags/${latest_release_tag}/packages/contracts-bedrock/snapshots/storageLayout/${contract_name}.json"
    remote_storage_layout=$(curl -sL "$remote_url_storage_layout")

    echo "$remote_storage_layout"
}

fetch_latest_storage_layout "$contract_name_arg"