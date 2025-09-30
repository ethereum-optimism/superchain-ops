#!/usr/bin/env bash
set -euo pipefail

# Function to test a command and check its output
test_command() {
    local command="$1"
    local expected_output="$2"
    local actual_output

    # Run the command and capture the output
    actual_output=$(eval "$command" || true)

    # Check if the actual output matches the expected output
    if [[ "$actual_output" == *"$expected_output"* ]]; then
        echo "Test passed for: $command"
    else
        echo "Test failed for: $command"
        echo "Expected: $expected_output"
        echo "Got: $actual_output"
        exit 1
    fi
}

# Test cases
root_dir=$(git rev-parse --show-toplevel)
test_command "just new" "Error: No command specified"
test_command "just new template" "Error: No task type specified"
test_command "just new template invalid" "Error: Invalid task type 'invalid'"
test_command "just new task l2" "Error: Task type should not be specified for 'task' command"
# Test that all task types are supported by just new template
# Iterate over all Solidity files in the types folder
for file in "$root_dir"/src/tasks/types/*.sol; do
    # Extract the contract name from the file
    contract_name=$(basename "$file" .sol)
    # Convert the contract name to lowercase
    contract_name_lower=$(echo "$contract_name" | tr '[:upper:]' '[:lower:]')
    
    # Construct the test command
    test_command "echo \"Example.sol\" | just new template $contract_name_lower" "Task type: $contract_name"
    rm -rf "$root_dir"/src/template/Example.sol
done
test_command "just new invalid" "Error: Invalid command"

echo "All tests passed!"