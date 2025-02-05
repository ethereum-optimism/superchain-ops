#!/usr/bin/env bash

# shellcheck source=./select-network.sh
source "$(dirname "${BASH_SOURCE[0]}")/select-network.sh"

# Canonical list of lexicographically sorted tasks for a given network.
getSortedTaskForNetwork() {
    network=$1
    # If no network is specified, initiate the selection process.
    if [ -z "$network" ]; then
        network=$(select_network)

        task_dir="tasks/$network"

        if [ ! -d "$task_dir" ] || [ -z "$(ls -A "$task_dir")" ]; then
            echo -e "\033[31m\nError: The directory '$task_dir' is empty or does not exist.\033[0m" >&2
            return 1
        fi
    fi

    find "tasks/$network" -maxdepth 1 -type d 2>/dev/null | sort
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    getSortedTaskForNetwork "$1"
fi
