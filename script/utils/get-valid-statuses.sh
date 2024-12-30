#!/bin/bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TASKS_DIR="$BASE_DIR/../../tasks"
export TEMPLATES_FOLDER_WITH_NO_TASKS="templates"
export NESTED_SAFE_TASK_INDICATOR="NestedSignFromJson.s.sol"

# Status arrays
export NON_TERMINAL_STATUSES=("DRAFT, NOT READY TO SIGN" "CONTINGENCY TASK, SIGN AS NEEDED" "READY TO SIGN")
export TERMINAL_STATUSES=("SIGNED" "EXECUTED" "CANCELLED")
export VALID_STATUSES=( "${NON_TERMINAL_STATUSES[@]}" "${TERMINAL_STATUSES[@]}" )

# Find README.md files for all tasks
FILES_FOUND_BY_GET_VALID_STATUSES=$(find "$TASKS_DIR" -type f -path "$TASKS_DIR/*/*/README.md")
export FILES_FOUND_BY_GET_VALID_STATUSES
