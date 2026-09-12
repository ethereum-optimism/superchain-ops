#!/usr/bin/env bash
set -euo pipefail

root_dir=${1:-$(git rev-parse --show-toplevel)}
node_total=${CIRCLE_NODE_TOTAL:-1}
node_index=${CIRCLE_NODE_INDEX:-0}

if ! [[ "$node_total" =~ ^[0-9]+$ ]] || [ "$node_total" -lt 1 ]; then
    echo "CIRCLE_NODE_TOTAL must be a positive integer, got '$node_total'" >&2
    exit 1
fi

if ! [[ "$node_index" =~ ^[0-9]+$ ]]; then
    echo "CIRCLE_NODE_INDEX must be a non-negative integer, got '$node_index'" >&2
    exit 1
fi

if [ "$node_index" -ge "$node_total" ]; then
    echo "CIRCLE_NODE_INDEX ($node_index) must be less than CIRCLE_NODE_TOTAL ($node_total)" >&2
    exit 1
fi

task_index=0
while IFS= read -r task; do
    task_name=$(basename "$task")

    # 023-u13-to-u16a exceeds the 15M gas limit. 036-opcm-migrate-v800 requires
    # pre-upgraded chain state and is covered by SuperRootMigrateTest.
    if [ "$task_name" = "023-u13-to-u16a" ] || [ "$task_name" = "036-opcm-migrate-v800" ]; then
        continue
    fi

    if [ $((task_index % node_total)) -eq "$node_index" ]; then
        echo "$task"
    fi

    task_index=$((task_index + 1))
done < <(find "$root_dir/test/tasks/example" -mindepth 2 -maxdepth 2 -type d | sort)
