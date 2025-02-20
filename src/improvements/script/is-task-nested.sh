#!/bin/bash
set -euo pipefail

isNestedSafe() {
    local config_file_path="$1"
    
    # Get the repository root and template details
    local root_dir
    root_dir="$(git rev-parse --show-toplevel)"
    local template_dir="$root_dir/src/improvements/template"
    local script_dir="$root_dir/src/improvements/script"
    local template_name
    template_name="$(yq -r '.templateName' "$config_file_path")"
    echo "Template name: $template_name"
    
    # Opting to only get the first L2 chain id and assume all L2 chains have the same safeAddressString value.
    # It's not the job of this script to validate the config file.
    local l2_chain_id
    l2_chain_id="$(yq -r '.l2chains[0].chainId' "$config_file_path")"
    echo "L2 chain id: $l2_chain_id"

    # Get the safeAddressString from the template
    local safe_address_string
    safe_address_string="$(forge script "$template_dir/${template_name}.sol" --sig "safeAddressString" \
                          | sed -n 's/.*string "\(.*\)".*/\1/p')"
    echo "Safe address string: $safe_address_string"

    # Get the addresses JSON from the remote URL and extract the owner address
    local remote_url="https://raw.githubusercontent.com/ethereum-optimism/superchain-registry/main/superchain/extra/addresses/addresses.json"
    local addresses_json
    addresses_json="$(curl -sL "$remote_url")"
    local owner_address
    owner_address="$(jq -r ".[\"$l2_chain_id\"].\"$safe_address_string\"" <<< "$addresses_json")"
    echo "$safe_address_string: $owner_address"

    local contract_signer_count=0
    local eoa_signer_count=0

    # Call get-rpc-url.sh to get the RPC URL for the chain
    local rpc_url
    rpc_url="$("$script_dir"/get-rpc-url.sh "$config_file_path")"
    echo "Checking owners for contract: $owner_address using RPC: $rpc_url"

    # Get the list of owners
    local owners
    owners="$(cast call --rpc-url "$rpc_url" "$owner_address" "getOwners()(address[])" \
             | sed 's/\([a-fA-F0-9x]\{42\}\)/"\1"/g' \
             | jq -r '.[]')"

    # Get the threshold
    local threshold
    threshold="$(cast call --rpc-url "$rpc_url" "$owner_address" "getThreshold()(uint256)")"
    echo "Signer threshold: $threshold"

    # Check each owner for contract code
    while IFS= read -r owner; do
        local code
        code="$(cast codesize --rpc-url "$rpc_url" "$owner")"
        if [ "$code" -gt 0 ]; then
            echo "Owner address $owner contains code (size $code)."
            contract_signer_count=$((contract_signer_count + 1))
        else
            echo "Owner address $owner does not contain code."
            eoa_signer_count=$((eoa_signer_count + 1))
        fi
    done <<< "$owners"

    # Determine if nested safe based on the count of contract signers vs threshold
    local is_nested_safe
    if [ "$contract_signer_count" -ge "$threshold" ]; then
        is_nested_safe=true
    else
        is_nested_safe=false
    fi

    echo "Nested safe: $is_nested_safe"
    
    # Exit with a code based on the nested safe status.
    if [ "$is_nested_safe" = true ]; then
        return 0
    else
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ "$#" -ne 1 ]; then
        echo "Usage: $0 <config_file_path>"
        exit 1
    fi
    isNestedSafe "$1"
fi
