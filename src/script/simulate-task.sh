#!/bin/bash
set -euo pipefail

# Simulates a task given a path to the task directory. 
# This function will determine if the task is nested or not then
# simulate it with the appropriate justfile. 
simulate_task() {
    task=$1
    nested_safe_name_depth_1=$2
    nested_safe_name_depth_2=$3
    network=$4
    root_dir=$(git rev-parse --show-toplevel)
    just_file="${root_dir}/src/justfile"

    if [ -z "$task" ]; then
        echo "Error: task path is required"
        echo "Usage: $0 <task_path> [nested_safe_name_depth_1] [nested_safe_name_depth_2]"
        exit 1
    fi
    
    rpcUrl=$("$root_dir"/src/script/get-rpc-url.sh "$network")
    echo "Task: $task"
    # Fork at the task's pinned block so this check reads the same chain state the simulation runs against.
    if [ -f "$task/.env" ]; then
        set -a
        # shellcheck disable=SC1091
        source "$task/.env"
        set +a
    fi
    fork_block_args=$(just --justfile "$just_file" _get-fork-block-args)

    # Tasks that declare DEPENDS_ON in their .env only make sense on top of the state left by
    # earlier tasks. Simulate them stacked on their dependencies, mirroring production stacked
    # simulations, instead of standalone.
    if [ -n "${DEPENDS_ON:-}" ]; then
        task_name=$(basename "$task")
        test_dir=$(dirname "$(dirname "$task")")
        echo "Simulating stacked task: $task (depends on: $DEPENDS_ON)"
        # shellcheck disable=SC2086  # fork_block_args must word-split ("--fork-block-number <n>" or empty)
        FETCH_TASKS_TEST_DIR="$test_dir" FETCH_TASKS_ONLY="$DEPENDS_ON,$task_name" \
            forge script "$root_dir"/src/tasks/StackedSimulator.sol:StackedSimulator \
            --sig "simulateStack(string,string)" "$network" "$task_name" \
            --ffi --fork-url "$rpcUrl" --fork-retries 10 --fork-retry-backoff 1000 ${fork_block_args}
        echo -e "\n\nDone simulating task: $task"
        echo ""
        return
    fi

    # shellcheck disable=SC2086  # fork_block_args must word-split ("--fork-block-number <n>" or empty)
    is_nested=$(forge script "$root_dir"/src/tasks/TaskManager.sol --sig "isNestedTask(string)" "$task/config.toml" --fork-url "$rpcUrl" --fork-retries 10 --fork-retry-backoff 1000 ${fork_block_args} --json | jq -r '.returns["0"].value')
    echo "Is nested: $is_nested"
    pushd "$task" > /dev/null
    if [ "$is_nested" = "true" ]; then
        echo "Simulating nested task: $task"
        if [ -z "$nested_safe_name_depth_1" ]; then
            echo "Error: this task requires a nested safe name e.g. foundation, council, chain-governor."
            exit 1
        fi
        SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path "$(pwd)"/.env --justfile "$just_file" simulate "$nested_safe_name_depth_1" "$nested_safe_name_depth_2"
    else
        echo "Simulating single task: $task"
        SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path "$(pwd)"/.env --justfile "$just_file" simulate
    fi

    echo -e "\n\nDone simulating task: $task"
    echo ""
    popd > /dev/null
}

# Arguments: 1. task path, 2. nested safe name depth 1, 3. nested safe name depth 2, 4. network
simulate_task "$1" "$2" "$3" "$4"