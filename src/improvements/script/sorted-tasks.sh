#!/usr/bin/env bash

# Canonical list of lexicographically sorted tasks for a given network.
getSortedTaskForNetwork() {
    network=$1
    find "tasks/$network" -maxdepth 1 -type d 2>/dev/null | sort
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    getSortedTaskForNetwork "$1"
fi
