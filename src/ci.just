# Justfile commands used in CI

check-superchain-registry-latest:
    #!/usr/bin/env bash
    set -euo pipefail
    root_dir=$(git rev-parse --show-toplevel)
    bash ${root_dir}/src/script/check-superchain-latest.sh

# This command simulates tasks in the example directory. There should be a corresponding task for each template.
simulate-all-templates:
    #!/usr/bin/env bash
    set -euo pipefail
    root_dir=$(git rev-parse --show-toplevel)
    forge build
    simulation_count=0
    # When we spawn too many concurrent processes, the simulation fails with 'solc exited with signal: 9 (SIGKILL)'.
    # The batch size should be low enough to not cause issues, but high enough to not make the simulation too slow.
    batch_size=7
    current_batch=0

    # Collect PIDs of each background simulation.
    declare -a pids=()

    for task in "${root_dir}/test/tasks/example/"*/*; do
        if [ -d "$task" ]; then
            echo "Task: $task"
            nested_safe_name_depth_1=""
            nested_safe_name_depth_2=""
            if [ -f "$task/.env" ]; then
                echo "Found an env file"
                # Check if NESTED_SAFE_NAME_DEPTH_1 exists in the file and extract it
                if grep -q "NESTED_SAFE_NAME_DEPTH_1" "$task/.env"; then
                    echo "Found depth 1 name"
                    extracted_value=$(grep "NESTED_SAFE_NAME_DEPTH_1" "$task/.env" | cut -d '=' -f 2)
                    echo "Extracted depth 1 name: $extracted_value"
                    # Only use the extracted value if its not empty and not null
                    if [ -n "$extracted_value" ] && [ "$extracted_value" != "null" ]; then
                        nested_safe_name_depth_1="$extracted_value"
                    fi
                fi
                if grep -q "NESTED_SAFE_NAME_DEPTH_2" "$task/.env"; then
                    echo "Found depth 2 name"
                    extracted_value=$(grep "NESTED_SAFE_NAME_DEPTH_2" "$task/.env" | cut -d '=' -f 2)
                    echo "Extracted depth 2 name: $extracted_value"
                    if [ -n "$extracted_value" ] && [ "$extracted_value" != "null" ]; then
                        nested_safe_name_depth_2="$extracted_value"
                    fi
                fi
            fi

            # Extract network from the task path (first asterisk in the pattern)
            network=$(basename "$(dirname "$task")")
            task_name=$(basename "$task")
            task_path="$root_dir/test/tasks/example/$network/$task_name"

            # Launch each simulation in background.
            "${root_dir}/src/script/simulate-task.sh" "$task_path" "$nested_safe_name_depth_1" "$nested_safe_name_depth_2" "$network" & pids+=( "$!" )
            current_batch=$((current_batch + 1))

            # If we have reached the batch size, wait for this batch to complete
            if [ $current_batch -eq $batch_size ]; then
                echo "Waiting for batch of $batch_size simulations to complete..."
                # Wait for current batch to finish
                for pid in "${pids[@]}"; do
                    wait "$pid"
                    simulation_count=$((simulation_count + 1))
                done
                
                # Reset for next batch
                pids=()
                current_batch=0
                echo "Batch completed. Starting next batch..."
            fi
        fi
    done

    # Wait for any remaining simulations in the final batch
    if [ ${#pids[@]} -gt 0 ]; then
        echo "Waiting for final batch of ${#pids[@]} simulations to complete..."
        for pid in "${pids[@]}"; do
            wait "$pid"
            simulation_count=$((simulation_count + 1))
        done
    fi

    echo "$simulation_count simulations run."

    # Count template files (excluding *.template.sol and boilerplate dir).
    template_count=$(find "${root_dir}/src/template" -type f ! -name "*.template.sol" ! -path "*/boilerplate/*" | wc -l | xargs)

    # Verify that every template file is referenced by at least one example task config.
    missing_templates=()
    while IFS= read -r template_file; do
        tmpl_name=$(basename "$template_file" .sol)
        if ! grep -R --quiet "templateName = \"${tmpl_name}\"" "${root_dir}/test/tasks/example"/*/*/config.toml 2>/dev/null; then
            missing_templates+=("$tmpl_name")
        fi
    done < <(find "${root_dir}/src/template" -type f ! -name "*.template.sol" ! -path "*/boilerplate/*")

    echo ""
    if [ ${#missing_templates[@]} -ne 0 ]; then
        echo -e "\033[31mError: The following template(s) do not have an example task referencing them:\033[0m" >&2
        for t in "${missing_templates[@]}"; do
            echo -e "\033[31m  • $t\033[0m" >&2
        done
        echo -e "\033[32mSuccess: All templates have a corresponding task.\033[0m"
        exit 1
    fi


test:
    forge build
    forge test
    just simulate-all-templates