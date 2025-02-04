#!/usr/bin/env bash

create_task() {
    echo ""
    PS3="Select network: "
    select network in eth sep oeth sep-dev-0 "Other (specify)"; do
        case $network in
        "Other (specify)")
            read -r -p "Enter custom network name: " network
            ;;
        "")
            echo "Invalid selection, please enter a network name manually: "
            read -r network
            ;;
        esac
        break
    done
    echo -e "\n\033[32mYou selected: $network\033[0m"

    echo ""
    mapfile -t templates < <(ls -1 template/)
    for i in "${!templates[@]}"; do
        templates["$i"]="${templates[$i]%.sol}"
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

    # This is an ordered list of all the tasks for a given network.
    existing_dirs=$(find "tasks/$network" -maxdepth 1 -type d 2>/dev/null | sort)
    echo ""

    most_recent_task_dir=$(echo "$existing_dirs" | tail -n1)

    suggestion=""
    if [[ -z "$most_recent_task_dir" ]]; then
        suggestion="Note: this is the first task for this network. Please choose a name that's lexicographically sensible"
    else
        suggestion="lexicographically after: $most_recent_task_dir"
    fi
    while true; do
        read -r -p "Enter task directory name ($suggestion): " dirname
        if [[ -z "$dirname" ]]; then
            echo -e "\n\033[31mTask directory name cannot be empty. Please try again.\033[0m\n"
        elif [[ -n "$most_recent_task_dir" && "$dirname" < "$(basename "$most_recent_task_dir")" ]]; then
            echo -e "\033[31mError: Task name '$dirname' is lexicographically earlier than existing directories.\033[0m"
            echo -e "\033[31mThe last existing directory is: $(basename "$most_recent_task_dir")\033[0m"
            echo -e "\033[31mPlease choose a name that comes after this lexicographically.\033[0m\n"
        elif [[ -n "$most_recent_task_dir" && "$dirname" == "$(basename "$most_recent_task_dir")" ]]; then
            echo -e "\033[31mError: Task name '$dirname' already exists.\033[0m"
            echo -e "\033[31mPlease choose a name that comes after this lexicographically.\033[0m\n"
        else
            break
        fi
    done

    task_path="tasks/${network}/${dirname}"
    mkdir -p "$task_path"
    config_path="$task_path/config.toml"
    readme_path="$task_path/README.md" # TODO: Each template should have a README.md
    echo "templateName = \"${template%.sol}\"" >"${config_path}"
    echo "# ${dirname}" >"${readme_path}"
    echo "Created task directory '${dirname}' for network: ${network}"
}

# Run this function only if someone runs this script directly,
# not when it's imported by another script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    create_task
fi
