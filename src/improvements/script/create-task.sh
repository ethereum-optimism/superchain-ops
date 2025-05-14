#!/usr/bin/env bash

# shellcheck source=./select-network.sh
source "$(dirname "${BASH_SOURCE[0]}")/select-network.sh"

create_task() {
    echo ""
    network=$(select_network)

    echo ""
    templates=()
    while IFS= read -r line; do templates+=("$line"); done < <(ls -1 template/)
    for i in "${!templates[@]}"; do
        # Don't add directories to the list of templates i.e. boilerplate/ directory.
        if [[ -d "template/${templates[$i]}" ]]; then
            unset 'templates[$i]'
        else
            templates["$i"]="${templates[$i]%.sol}"
        fi
    done

    PS3="Select template name: "
    while true; do
        select template in "${templates[@]}"; do
            if [[ -z "$template" ]]; then
                echo -e "\n\033[31mInvalid selection. Please choose a number from the list.\033[0m\n"
                break
            elif [[ " ${templates[*]} " =~ ${template} ]]; then
                echo -e "\n\033[32mYou selected: $template\033[0m"
                break 2 # Exit both loops
            else
                echo -e "\n\033[31mUnexpected error. Please try again.\033[0m"
                break
            fi
        done
    done

    echo ""
    # Prompt the user (Enter → No by default)
    read -r -p "Is this a test task (i.e. lives in test/tasks/example/$network directory)? Type 'y' to confirm, or press Enter for No: " is_test_task

    echo ""
    if [[ "$is_test_task" == "Y" || "$is_test_task" == "y" || "$is_test_task" == "yes" ]]; then
        echo -e "\033[32mYou selected: Yes\033[0m"
        dest_dir="../../test/tasks/example"
        suggestion="This is a test task"
        is_test_task="true"
        echo ""
    else 
        echo -e "\033[32mYou selected: No\033[0m"
        dest_dir="tasks"
        # This is an ordered list of all the tasks for a given network.
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        sorted_existing_dirs=$("$script_dir/sorted-tasks.sh" "$network")

        echo ""
        if [[ -z "$sorted_existing_dirs" || $(echo "$sorted_existing_dirs" | wc -l) -eq 1 ]]; then
            suggestion="Note: this is the first task for this network. Please choose a name that's lexicographically sensible"
        else
            most_recent_task_dir=$(echo "$sorted_existing_dirs" | tail -n1)
            suggestion="lexicographically after: $(basename "$most_recent_task_dir")"
        fi
        is_test_task="false"
    fi

    while true; do
        read -r -p "Enter task directory name ($suggestion): " dirname
        if [[ -z "$dirname" ]]; then
            echo -e "\n\033[31mTask directory name cannot be empty. Please try again.\033[0m\n"
        elif [[ -n "$most_recent_task_dir" && "$dirname" < "$(basename "$most_recent_task_dir")" ]]; then
            echo -e "\033[31mError: Task name '$dirname' is lexicographically earlier than existing directories.\033[0m"
            echo -e "\033[31mThe last existing directory is: $(basename "$most_recent_task_dir")\033[0m"
            echo -e "\033[31mPlease choose a name that comes after this lexicographically.\033[0m"
            echo -e "\033[31mAlternatively, if you know what you're doing, you can manually insert a task without this cli.\033[0m\n"
        elif [[ -n "$most_recent_task_dir" && "$dirname" == "$(basename "$most_recent_task_dir")" ]]; then
            echo -e "\033[31mError: Task name '$dirname' already exists.\033[0m"
            echo -e "\033[31mPlease choose a name that comes after this lexicographically.\033[0m\n"
        else
            break
        fi
    done


    echo ""
    read -r -p "Enter optional short description of the task (hit enter to leave blank): " short_description
    if [[ -n "$short_description" ]]; then
        short_description=": $short_description"
    fi

    task_path="${dest_dir}/${network}/${dirname}"
    mkdir -p "$task_path"
    config_path="$task_path/config.toml"
    
    echo -e "l2chains = [] # e.g. [{name = \"OP Mainnet\", chainId = 10}]\ntemplateName = \"${template%.sol}\"" >"${config_path}"

    # Don't write the readme and validation files for test tasks.
    if [[ "$is_test_task" == "false" ]]; then
        # copy the readme template to readme_path
        readme_path="$task_path/README.md" 
        cp "template/boilerplate/README.template.md" "$readme_path"
        
        navigate_to_task_command="cd src/improvements/${dest_dir}/${network}/${dirname}"
        sed -e "s|<task-name>|$dirname|g" \
        -e "s|<short-description>|$short_description|g" \
        -e "s|<navigate-to-simulation-command>|$navigate_to_task_command|g" \
        -e "s|<navigate-to-signing-command>|$navigate_to_task_command|g" \
        "$readme_path" > "${readme_path}.tmp" \
        && mv "${readme_path}.tmp" "$readme_path"

        # copy the validation template to validation_path
        validation_path="$task_path/VALIDATION.md"
        cp "template/boilerplate/VALIDATION.template.md" "$validation_path"
    fi

    # Make .env file with TENDERLY_GAS set to 10000000 
    env_path="$task_path/.env"
    echo "TENDERLY_GAS=10000000" > "$env_path"
    if [[ "$is_test_task" == "true" ]]; then
        # Only add a fork block number if this is a test task. We want the test task to consistently use the same block number.
        echo "FORK_BLOCK_NUMBER=" >> "$env_path"
    fi

    echo "Created task directory '${dirname}' for network: ${network}"
    absolute_path=$(realpath "$task_path")
    echo -e "\n\033[32mDirectory created at:\033[0m"
    echo "$absolute_path"
}

# Run this function only if someone runs this script directly,
# not when it's imported by another script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    create_task
fi
