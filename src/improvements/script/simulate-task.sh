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
    is_nested=$(forge script "$root_dir"/src/improvements/tasks/TaskManager.sol --sig "isNestedTask(string)" "$task/config.toml" --rpc-url "$rpcUrl" --json | jq -r '.returns["0"].value')
    echo "Is nested: $is_nested"
    pushd "$task" > /dev/null
    if [ "$is_nested" = "true" ]; then
        echo "Simulating nested task: $task"
        if [ -z "$nested_safe_name" ]; then
            echo "Error: this task requires a nested safe name e.g. foundation, council, chain-governor."
            exit 1
        fi
        SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path "$(pwd)"/.env --justfile "$nested_just_file" simulate "$nested_safe_name"
    else
        echo "Simulating single task: $task"
        SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path "$(pwd)"/.env --justfile "$single_just_file" simulate
    fi

    echo -e "\n\nDone simulating task: $task"
    echo ""
    popd > /dev/null
}

simulate_task "$1" "$2"