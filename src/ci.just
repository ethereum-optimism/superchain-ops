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
    # When we spawn too many concurrent processes, the simulation fails with 'solc exited with signal: 9 (SIGKILL)'.
    # The limit should be low enough to not cause issues, but high enough to not make the simulation too slow.
    max_parallel=7

    # Prints the value of KEY in ENV_FILE, or nothing when it is absent, empty or "null".
    read_nested_safe_name() {
        local value
        value=$(grep "$2" "$1" | cut -d '=' -f 2 || true)
        if [ -n "$value" ] && [ "$value" != "null" ]; then
            echo "$value"
        fi
    }

    simulate_example_task() {
        set -euo pipefail
        local task=${1%/}
        local start=$SECONDS
        local nested_safe_name_depth_1="" nested_safe_name_depth_2="" network
        if [ -f "$task/.env" ]; then
            nested_safe_name_depth_1=$(read_nested_safe_name "$task/.env" NESTED_SAFE_NAME_DEPTH_1)
            nested_safe_name_depth_2=$(read_nested_safe_name "$task/.env" NESTED_SAFE_NAME_DEPTH_2)
        fi
        network=$(basename "$(dirname "$task")")
        echo "Task: $task (network: $network, nested safes: '$nested_safe_name_depth_1' '$nested_safe_name_depth_2')"
        if ! "${root_dir}/src/script/simulate-task.sh" "$task" "$nested_safe_name_depth_1" "$nested_safe_name_depth_2" "$network"; then
            echo "FAILED: $task after $((SECONDS - start))s" >&2
            return 1
        fi
        echo "Simulated $task in $((SECONDS - start))s"
    }
    export root_dir
    export -f read_nested_safe_name simulate_example_task

    # A rolling pool rather than fixed batches: the next simulation starts as soon as any one
    # finishes, so a slow task never leaves the other slots idle. The trailing slash on the glob
    # matches directories only.
    tasks=("${root_dir}/test/tasks/example/"*/*/)
    # shellcheck disable=SC2016  # $1 must expand in the child bash, not here.
    printf '%s\0' "${tasks[@]}" | xargs -0 -n 1 -P "$max_parallel" bash -c 'simulate_example_task "$1"' _

    echo "${#tasks[@]} simulations run."

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
