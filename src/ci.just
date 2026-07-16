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

            # OPCMMigrateV800 requires the target chain to already be upgraded to V800/Super Root.
            # The raw example task simulation forks current chain state and cannot perform that
            # prerequisite upgrade before invoking migrate. Coverage lives in SuperRootMigrateTest,
            # which forks Sepolia, upgrades the chain, then runs migrate in the same forked state.
            if [ "$task_name" = "036-opcm-migrate-v800" ]; then
                echo "Skipping $task_name (requires pre-upgraded V800/Super Root chain state)"
                continue
            fi

            # OPCMUpgradeV800 now encodes SUPER_PERMISSIONED_CANNON (gt=5) game args as
            # proposer-only, matching the simplified op-contracts V800 ABI. No V800 OPCM is
            # deployed on-chain yet, so the forked OPCM this example task simulates against
            # predates that layout and reverts while decoding the args in _build. Coverage
            # lives in SuperRootUpgradeTest. Remove this skip once V800 is deployed on-chain.
            if [ "$task_name" = "035-opcm-upgrade-v800" ]; then
                echo "Skipping $task_name (forked OPCM predates simplified V800 SUPER_PERMISSIONED_CANNON args)"
                continue
            fi

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

    # These templates intentionally no longer require example-task regression
    # fixtures. The templates stay in src/template so historical tasks and
    # downstream references continue to compile.
    is_deprecated_template_without_example() {
        case "$1" in
            DelayedWETHOwnershipTemplate) return 0 ;;
            OPCMUpgradeV220toV410) return 0 ;;
            OPCMUpgradeV200) return 0 ;;
            OPCMUpgradeV300) return 0 ;;
            OPCMUpdatePrestateV300) return 0 ;;
            OPCMUpgradeV400) return 0 ;;
            OPCMUpgradeV410) return 0 ;;
            OPCMUpdatePrestateV410) return 0 ;;
            OPCMUpgradeSuperchainConfigV410) return 0 ;;
            RevShareSetup) return 0 ;;
            OPCMUpgradeV500) return 0 ;;
            UpdateRetirementTimestampV200) return 0 ;;
            UpdateRetirementTimestampV400) return 0 ;;
            UnpauseSuperchainConfig) return 0 ;;
            UnpauseSuperchainConfigV400) return 0 ;;
            UniFix) return 0 ;;
            BlacklistGamesV140) return 0 ;;
            BlacklistGamesV400) return 0 ;;
            L1PortalExecuteL2Call) return 0 ;;
            MigrateToLiveness2) return 0 ;;
            *) return 1 ;;
        esac
    }

    # Verify that every template file is referenced by at least one example task config.
    missing_templates=()
    deprecated_templates_without_examples=()
    while IFS= read -r template_file; do
        tmpl_name=$(basename "$template_file" .sol)
        if ! grep -R --quiet "templateName = \"${tmpl_name}\"" "${root_dir}/test/tasks/example"/*/*/config.toml 2>/dev/null; then
            if is_deprecated_template_without_example "$tmpl_name"; then
                deprecated_templates_without_examples+=("$tmpl_name")
            else
                missing_templates+=("$tmpl_name")
            fi
        fi
    done < <(find "${root_dir}/src/template" -type f ! -name "*.template.sol" ! -path "*/boilerplate/*")

    echo ""
    if [ ${#deprecated_templates_without_examples[@]} -ne 0 ]; then
        echo "Deprecated template(s) without example tasks (allowed; templates still compile):"
        for t in "${deprecated_templates_without_examples[@]}"; do
            echo "  - $t"
        done
        echo ""
    fi

    if [ ${#missing_templates[@]} -ne 0 ]; then
        echo -e "\033[31mError: The following template(s) do not have an example task referencing them:\033[0m" >&2
        for t in "${missing_templates[@]}"; do
            echo -e "\033[31m  • $t\033[0m" >&2
        done
        exit 1
    fi

    echo -e "\033[32mSuccess: All non-deprecated templates have a corresponding task.\033[0m"


test:
    forge build
    forge test
    just simulate-all-templates
