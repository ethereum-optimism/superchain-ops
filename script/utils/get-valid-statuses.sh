#!/bin/bash
set -euo pipefail

NON_TERMINAL_STATUSES=("DRAFT, NOT READY TO SIGN" "CONTINGENCY TASK, SIGN AS NEEDED" "READY TO SIGN")
TERMINAL_STATUSES=("SIGNED" "EXECUTED" "CANCELLED")
VALID_STATUSES=( "${NON_TERMINAL_STATUSES[@]}" "${TERMINAL_STATUSES[@]}" )

# Find README.md files for all tasks and process them.
files=$(find ./tasks -type f -path './tasks/*/*/README.md')

# Filters:
# Name of a file to exclude from searching for non-terminal tasks.
FOLDER_WITH_NO_TASKS="templates"
# Name of a file in a task directiory that specifies that the task is a nested safe task.
IF_THIS_ITS_NESTED="NestedSignFromJson.s.sol"