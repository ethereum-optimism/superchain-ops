#!/bin/bash
set -euo pipefail

# Simulates a task given a path to the task directory. 
# This function will determine if the task is nested or not then
# simulate it with the appropriate justfile. 
verify_task() {
    simulation_output_file=$1
    root_dir=$(git rev-parse --show-toplevel)

    # Extract Tenderly payload from output and save it
    awk '/------------------ Tenderly Simulation Payload ------------------/{flag=1;next}/\}\}\}\}$/{print;flag=0}flag' "$simulation_output_file" > ./tenderly_payload.json
    
    # Check if payload was extracted successfully
    if [ -s ./tenderly_payload.json ]; then
        echo -e "\n\nTenderly simulation payload saved to: ./tenderly_payload.json"
        
        PAYLOAD_FILE="$(pwd)/tenderly_payload.json"
        export PAYLOAD_FILE

        # Calculate locally the domain and message hashes from the Tenderly payload
        forge script "$root_dir"/script/CalculateSafeHashes.s.sol -vvv 2>&1 | tee ./local_output.txt

        # Extract the domain and message hashes from the local output
        DOMAIN_SEPARATOR_LOCAL=$(awk '/Domain Separator:/{print $3}' ./local_output.txt)
        MESSAGE_HASH_LOCAL=$(awk '/Message Hash:/{print $3}' ./local_output.txt)

        # Simulate the task with Tenderly and extract the domain and message hashes
        "$root_dir"/src/improvements/script/get-tenderly-hashes.sh ./tenderly_payload.json 2>&1 | tee ./remote_output.txt   

        # Extract the domain and message hashes from the remote output
        DOMAIN_SEPARATOR_REMOTE=$(awk '/Domain Separator:/{print $3}' ./remote_output.txt)
        MESSAGE_HASH_REMOTE=$(awk '/Message Hash:/{print $3}' ./remote_output.txt)

        # Compare the local and remote hashes
        if [ "$DOMAIN_SEPARATOR_LOCAL" != "$DOMAIN_SEPARATOR_REMOTE" ]; then
            echo -e "\n\n\033[1;31mDomain separator mismatch\033[0m\n"
            exit 1
        fi
        if [ "$MESSAGE_HASH_LOCAL" != "$MESSAGE_HASH_REMOTE" ]; then
            echo -e "\n\n\033[1;31mMessage hash mismatch\033[0m\n"
            exit 1
        fi

        rm ./tenderly_payload.json
        rm ./local_output.txt
        rm ./remote_output.txt
    else
        echo "Simulation output saved to: ./simulation_output.txt"
    fi
}

verify_task $1