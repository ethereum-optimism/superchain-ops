#!/bin/bash
set -euo pipefail

# Simulates a task given a path to the task directory. 
# This function will determine if the task is nested or not then
# simulate it with the appropriate justfile. 
simulate_task() {
    task=$1
    nested_safe_name_depth_1=$2
    nested_safe_name_depth_2=$3
    root_dir=$(git rev-parse --show-toplevel)
    just_file="${root_dir}/src/improvements/justfile"

    if [ -z "$task" ]; then
        echo "Error: task path is required"
        echo "Usage: $0 <task_path> [nested_safe_name_depth_1] [nested_safe_name_depth_2]"
        exit 1
    fi
    
    rpcUrl=$("$root_dir"/src/improvements/script/get-rpc-url.sh "$task")
    echo "Task: $task"
    is_nested=$(forge script "$root_dir"/src/improvements/tasks/TaskManager.sol --sig "isNestedTask(string)" "$task/config.toml" --rpc-url "$rpcUrl" --json | jq -r '.returns["0"].value')
    echo "Is nested: $is_nested"
    pushd "$task" > /dev/null
    if [ "$is_nested" = "true" ]; then
        echo "Simulating nested task: $task"
        if [ -z "$nested_safe_name_depth_1" ]; then
            echo "Error: this task requires a nested safe name e.g. foundation, council, chain-governor."
            exit 1
        fi
        # TODO: If there is another level of nesting we should check and make sure the nested safe name depth 2 is set.
        SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path "$(pwd)"/.env --justfile "$just_file" simulate "$nested_safe_name_depth_1" "$nested_safe_name_depth_2"
    else
        echo "Simulating single task: $task"
        SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path "$(pwd)"/.env --justfile "$just_file" simulate
    fi

    echo -e "\n\nDone simulating task: $task"
    echo ""
    popd > /dev/null
}

# Arguments: 1. task path, 2. nested safe name depth 1, 3. nested safe name depth 2
simulate_task "$1" "$2" "$3"