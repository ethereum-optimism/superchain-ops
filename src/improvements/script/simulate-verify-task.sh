#!/bin/bash
set -euo pipefail


simulate_verify_task() {
    task=$1
    nested_safe_name=$2
    root_dir=$(git rev-parse --show-toplevel)
    local_output_file="./simulation_output.txt"
    remote_output_file="./remote_output.txt"
    forge_output_file="./forge_output.txt"

    rpcUrl=$("$root_dir"/src/improvements/script/get-rpc-url.sh "$task")

    # If the task is nested then we only simulate as the foundation.
    # In the future we could simulate as other nested safes. 
    # For testing purposes, we do not gain anything by simulating as other nested safes.
    nested_safe_name="foundation"

    "$root_dir"/src/improvements/script/simulate-task.sh "$task" "$nested_safe_name" | tee "$local_output_file"


    # Extract Tenderly payload from output into a variable
    export TENDERLY_PAYLOAD=$(awk '/Simulation payload:/{flag=1;next}/\}\}\}\}$/{print;flag=0}flag' "$local_output_file")
    
    # Simulate the task with Tenderly and extract the domain and message hashes
    "$root_dir"/src/improvements/script/get-tenderly-hashes.sh "$TENDERLY_PAYLOAD" 2>&1 | tee "$remote_output_file"   

    # Extract the domain and message hashes from the remote output
    domain_separator_remote=$(awk '/Remote Domain Separator:/{print $4}' "$remote_output_file")
    message_hash_remote=$(awk '/Remote Message Hash:/{print $4}' "$remote_output_file")

    # Calculate the domain and message hashes locally using forge
    forge script --rpc-url "$rpcUrl" "$root_dir"/script/CalculateSafeHashes.s.sol -vvv | tee "$forge_output_file"

    # Extract domain separator and message hash from the simulation output
    domain_separator_local=$(awk '/Forge Domain Separator:/{print $4}' "$forge_output_file")
    message_hash_local=$(awk '/Forge Message Hash:/{print $4}' "$forge_output_file")

    # Compare the local and remote hashes
    if [ "$domain_separator_local" != "$domain_separator_remote" ]; then
        echo -e "\n\n\033[1;31mDomain separator mismatch\033[0m\n"
        exit 1
    fi
    if [ "$message_hash_local" != "$message_hash_remote" ]; then
        echo -e "\n\n\033[1;31mMessage hash mismatch\033[0m\n"
        exit 1
    fi
    echo -e "\n\n\033[1;32mRemote/Local Domain separator and message hash match\033[0m\n"

    rm "$local_output_file"
    rm "$remote_output_file"
    rm "$forge_output_file"
}

simulate_verify_task "$1" "$2"