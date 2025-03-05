#!/bin/bash
set -euo pipefail

# Simulates a task given a path to the task directory. 
# This function will determine if the task is nested or not then
# simulate it with the appropriate justfile. 
simulate_task() {
    task=$1
    nested_safe_name=$2
    root_dir=$(git rev-parse --show-toplevel)
    nested_just_file="${root_dir}/src/improvements/nested.just"
    single_just_file="${root_dir}/src/improvements/single.just"

    if [ -z "$task" ]; then
        echo "Error: task path is required"
        echo "Usage: $0 <task_path> [nested_safe_name]"
        exit 1
    fi
    
    rpcUrl=$("$root_dir"/src/improvements/script/get-rpc-url.sh "$task")
    echo "Task: $task"
    is_nested=$(forge script "$root_dir"/src/improvements/tasks/TaskRunner.sol --sig "isNestedTask(string)" "$task/config.toml" --rpc-url "$rpcUrl" --json | jq -r '.returns["0"].value')
    echo "Is nested: $is_nested"
    pushd "$task" > /dev/null
    if [ "$is_nested" = "true" ]; then
        echo "Simulating nested task: $task"
        if [ -z "$nested_safe_name" ]; then
            echo "Error: this task requires a nested safe name e.g. foundation, council, chain-governor."
            exit 1
        fi
        SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path "$(pwd)"/.env --justfile "$nested_just_file" simulate "$nested_safe_name" | tee ./simulation_output.txt
    else
        echo "Simulating single task: $task"
        SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path "$(pwd)"/.env --justfile "$single_just_file" simulate | tee ./simulation_output.txt
    fi

    # Extract Tenderly payload from output and save it
    awk '/------------------ Tenderly Simulation Payload ------------------/{flag=1;next}/\}\}\}\}$/{print;flag=0}flag' ./simulation_output.txt > ./tenderly_payload.json
    
    # Check if payload was extracted successfully
    if [ -s ./tenderly_payload.json ]; then
        echo -e "\n\nTenderly simulation payload saved to: ./tenderly_payload.json"
        rm ./simulation_output.txt
        
        PAYLOAD_FILE="$(pwd)/tenderly_payload.json"
        export PAYLOAD_FILE

        # Calculate locally the domain and message hashes from the Tenderly payload
        LOCAL_OUTPUT=$(forge script "$root_dir"/script/CalculateSafeHashes.s.sol -vvv)
        echo "$LOCAL_OUTPUT"

        # Extract the domain and message hashes from the local output
        DOMAIN_SEPARATOR_LOCAL=$(echo "$LOCAL_OUTPUT" | awk '/Domain Separator:/{print $3}')
        MESSAGE_HASH_LOCAL=$(echo "$LOCAL_OUTPUT" | awk '/Message Hash:/{print $3}')

        # Simulate the task with Tenderly and extract the domain and message hashes
        REMOTE_OUTPUT=$("$root_dir"/src/improvements/script/get-tenderly-hashes.sh ./tenderly_payload.json)
        echo "$REMOTE_OUTPUT"

        # Extract the domain and message hashes from the remote output
        DOMAIN_SEPARATOR_REMOTE=$(echo "$REMOTE_OUTPUT" | awk '/Domain Separator:/{print $3}')
        MESSAGE_HASH_REMOTE=$(echo "$REMOTE_OUTPUT" | awk '/Message Hash:/{print $3}')

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
    else
        echo "Simulation output saved to: ./simulation_output.txt"
    fi

    echo -e "\n\nDone simulating task: $task"
    popd > /dev/null
}

simulate_task "$1" "$2"