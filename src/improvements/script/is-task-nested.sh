#!/bin/bash
set -euo pipefail

isNestedSafe() {
    local config_file_path="$1"
    
    local root_dir
    root_dir="$(git rev-parse --show-toplevel)"
    local script_dir="$root_dir/src/improvements/script"
    
    # Get the owner address for the task
    local owner_address
    owner_address="$(tail -n 1 < <("$script_dir"/get-task-owner.sh "$config_file_path"))"

    local contract_signer_count=0
    local eoa_signer_count=0

    local rpc_url
    rpc_url="$("$script_dir"/get-rpc-url.sh "$config_file_path")"
    echo "Checking owners for contract: $owner_address using RPC: $rpc_url"

    local owners
    owners="$(cast call --rpc-url "$rpc_url" "$owner_address" "getOwners()(address[])" \
             | sed 's/\([a-fA-F0-9x]\{42\}\)/"\1"/g' \
             | jq -r '.[]')"

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

    local is_nested_safe
    if [ "$contract_signer_count" -ge "$threshold" ]; then
        is_nested_safe=true
    else
        is_nested_safe=false
    fi

    echo "Nested safe: $is_nested_safe"
    
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
