#!/bin/bash
set -euo pipefail

# This script simulates a task both locally and with Tenderly.
# It then verifies the hashes from both simulations against the provided as a parameter.
# task: the path to the task to simulate
# nested_safe_name: the name of the nested safe to simulate as, leave blank for single tasks
# domain_separator: the domain separator to verify against
# message_hash: the message hash to verify against
#
# Parses these strings from the local simulation output:
# Domain Separator: <hash>
# Message Hash: <hash>
# Simulation link: <link>
#
# Parses these strings from get-tenderly-hashes.sh:
# Domain Separator: <hash>
# Message Hash: <hash>
# Simulation link: <link>
simulate_verify_task() {
    task=$1
    nested_safe_name=$2
    domain_separator=$3
    message_hash=$4
    root_dir=$(git rev-parse --show-toplevel)
    local_output_file="./simulation_output.txt"
    remote_output_file="./remote_output.txt"

    echo "Simulating task $task with nested safe $nested_safe_name"
    echo "Verifying against domain separator: $domain_separator"
    echo "Verifying against message hash: $message_hash"

    "$root_dir"/src/improvements/script/simulate-task.sh "$task" "$nested_safe_name" | tee "$local_output_file"

    # Extract domain separator and message hash from the simulation output
    domain_separator_local=$(awk '/Domain Hash:/{print $3}' "$local_output_file")
    message_hash_local=$(awk '/Message Hash:/{print $3}' "$local_output_file")

    # Compare the local and provided domain separator and message hash
    if [ "$domain_separator_local" != "$domain_separator" ]; then
        echo -e "\n\n\033[1;31mLocal domain separator mismatch\033[0m\n"
        exit 1
    fi
    if [ "$message_hash_local" != "$message_hash" ]; then
        echo -e "\n\n\033[1;31mLocal message hash mismatch\033[0m\n"
        exit 1
    fi
    echo -e "\n\n\033[1;32mLocal hashes match\033[0m\n"

    # Extract Tenderly simulation link from output into a variable
    tenderly_link=$(grep -A 1 "Simulation link:" "$local_output_file" | grep -v "Simulation link:" | grep "https://" | tr -d '[:space:]')
    rm "$local_output_file"
    
    if [ -n "$tenderly_link" ]; then
        # Simulate the task with Tenderly and extract the domain and message hashes
        "$root_dir"/src/improvements/script/get-tenderly-hashes.sh --from-link "$tenderly_link" 2>&1 | tee "$remote_output_file"   

        # Extract the domain and message hashes from the remote output
        domain_separator_tenderly=$(awk '/Domain Separator:/{print $3}' "$remote_output_file")
        message_hash_tenderly=$(awk '/Message Hash:/{print $3}' "$remote_output_file")
        rm "$remote_output_file"

        # Compare the tenderly hashes with the provided hashes
        if [ "$domain_separator_tenderly" != "$domain_separator" ]; then
            echo -e "\n\n\033[1;31mTenderly domain separator mismatch\033[0m\n"
            exit 1
        fi
        if [ "$message_hash_tenderly" != "$message_hash" ]; then
            echo -e "\n\n\033[1;31mTenderly message hash mismatch\033[0m\n"
            exit 1
        fi
        echo -e "\n\n\033[1;32mTenderly hashes match\033[0m\n"
    else
        echo -e "\n\n\033[1;31mSimulation link not found in console output\033[0m\n"
        exit 1
    fi
}

simulate_verify_task "$1" "$2" "$3" "$4"