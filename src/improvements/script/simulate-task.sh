#!/bin/bash
set -euo pipefail

# Simulates a task given a path to the task directory. This function will determine if the task is nested or not then
# simulate it with the appropriate justfile.
simulate_task() {
    task=$1
    root_dir=$(git rev-parse --show-toplevel)
    nested_just_file="${root_dir}/src/improvements/nested.just"
    single_just_file="${root_dir}/src/improvements/single.just"

    rpcUrl=$("$root_dir"/src/improvements/script/get-rpc-url.sh "$task")
    echo "Task: $task"
    is_nested=$(forge script "$root_dir"/src/improvements/tasks/TaskRunner.sol --sig "isNestedTask(string)" "$task/config.toml" --rpc-url "$rpcUrl" --json | jq -r '.returns["0"].value')
    echo "Is nested: $is_nested"
    pushd "$task" > /dev/null
    if [ "$is_nested" = "true" ]; then
        echo "Simulating nested task: $task"
        SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path "$(pwd)"/.env --justfile "$nested_just_file" simulate foundation
    else
        echo "Simulating single task: $task"
        SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path "$(pwd)"/.env --justfile "$single_just_file" simulate
    fi
    echo "Done simulating task: $task"
    popd > /dev/null
}

simulate_task "$1"