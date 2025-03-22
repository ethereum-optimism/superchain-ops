#!/bin/bash
set -euo pipefail

# This script simulates a task both locally and with Tenderly.
# task: the path to the task to simulate
# nested_safe_name: the name of the nested safe to simulate as, leave blank for single tasks
simulate_tenderly() {
    task=$1
    nested_safe_name=$2

    root_dir=$(git rev-parse --show-toplevel)
    
    local_output_file="./simulation_output.txt"
    "$root_dir"/src/improvements/script/simulate-task.sh "$task" "$nested_safe_name" | tee "$local_output_file"

    # Extract Tenderly simulation link from output into a variable
    tenderly_link=$(grep -A 1 "Simulation link:" "$local_output_file" | grep -v "Simulation link:" | grep "https://" | tr -d '[:space:]')
    rm "$local_output_file"
    
    if [ -n "$tenderly_link" ]; then
        # Simulate the task with Tenderly
        "$root_dir"/src/improvements/script/get-tenderly-hashes.sh --from-link "$tenderly_link" 
    else
        echo -e "\n\n\033[1;31mSimulation link not found in console output\033[0m\n"
        exit 1
    fi
}

simulate_tenderly "$1" "$2"