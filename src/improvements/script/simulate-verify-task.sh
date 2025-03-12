#!/bin/bash
set -euo pipefail


simulate_verify_task() {
    task=$1
    nested_safe_name=$2
    root_dir=$(git rev-parse --show-toplevel)
    local_output_file="./simulation_output.txt"
    remote_output_file="./remote_output.txt"

    # If the task is nested then we only simulate as the foundation.
    # In the future we could simulate as other nested safes. 
    # For testing purposes, we do not gain anything by simulating as other nested safes.
    nested_safe_name="foundation"
    gen_verify_input="true"
    op_verify_input_filepath="${root_dir}/OPVerifyInputs/$(basename "$(dirname "${task}")")/${task##*/}-input.json"

    "$root_dir"/src/improvements/script/simulate-task.sh "$task" "$nested_safe_name" "$gen_verify_input" "$op_verify_input_filepath" | tee "$local_output_file"

    # Extract domain separator and message hash from the simulation output
    DOMAIN_SEPARATOR_LOCAL=$(awk '/Domain Separator:/{print $3}' "$local_output_file")
    MESSAGE_HASH_LOCAL=$(awk '/Message Hash:/{print $3}' "$local_output_file")

    # Extract Tenderly payload from output into a variable
    TENDERLY_PAYLOAD=$(awk '/Simulation payload:/{flag=1;next}/\}\}\}\}$/{print;flag=0}flag' "$local_output_file")
    
    # Check if payload was extracted successfully
    if [ -n "$TENDERLY_PAYLOAD" ]; then
        # Simulate the task with Tenderly and extract the domain and message hashes
        "$root_dir"/src/improvements/script/get-tenderly-hashes.sh "$TENDERLY_PAYLOAD" 2>&1 | tee "$remote_output_file"   

        # Extract the domain and message hashes from the remote output
        DOMAIN_SEPARATOR_REMOTE=$(awk '/Domain Separator:/{print $3}' "$remote_output_file")
        MESSAGE_HASH_REMOTE=$(awk '/Message Hash:/{print $3}' "$remote_output_file")

        # Compare the local and remote hashes
        if [ "$DOMAIN_SEPARATOR_LOCAL" != "$DOMAIN_SEPARATOR_REMOTE" ]; then
            echo -e "\n\n\033[1;31mDomain separator mismatch\033[0m\n"
            exit 1
        fi
        if [ "$MESSAGE_HASH_LOCAL" != "$MESSAGE_HASH_REMOTE" ]; then
            echo -e "\n\n\033[1;31mMessage hash mismatch\033[0m\n"
            exit 1
        fi
        echo -e "\n\n\033[1;32mDomain separator and message hash match\033[0m\n"

        rm "$local_output_file"
        rm "$remote_output_file"
    else
        echo "Simulation output saved to: $local_output_file"
    fi
}

simulate_verify_task "$1" "$2"