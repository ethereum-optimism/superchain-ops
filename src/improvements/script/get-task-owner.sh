#!/bin/bash
set -euo pipefail

getTaskOwner() {
    local config_file_path="$1"
    
    root_dir="$(git rev-parse --show-toplevel)"
    local template_dir="$root_dir/src/improvements/template"
    local template_name
    template_name="$(yq -r '.templateName' "$config_file_path")"
    echo "Template name: $template_name"

    # Get the first L2 chain id
    # Opting to only get the first L2 chain id and assume all L2 chains have the same safeAddressString value.
    # It's not the job of this script to validate the config file.
    local l2_chain_id
    l2_chain_id="$(yq -r '.l2chains[0].chainId' "$config_file_path")"
    echo "L2 chain id: $l2_chain_id"

    local safe_address_string
    safe_address_string="$(forge script "$template_dir/${template_name}.sol" --sig "safeAddressString" \
                          | sed -n 's/.*string "\(.*\)".*/\1/p')"
    echo "Safe address string: $safe_address_string"

    local remote_url="https://raw.githubusercontent.com/ethereum-optimism/superchain-registry/main/superchain/extra/addresses/addresses.json"
    local addresses_json
    addresses_json="$(curl -sL "$remote_url")"
    local owner_address
    owner_address="$(jq -r ".[\"$l2_chain_id\"].\"$safe_address_string\"" <<< "$addresses_json")"
    echo "$safe_address_string: $owner_address"

    echo "$owner_address"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ "$#" -ne 1 ]; then
        echo "Usage: $0 <config_file_path>"
        exit 1
    fi
    getTaskOwner "$1"
fi
