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

    echo ""
    mapfile -t templates < <(ls -1 template/)
    PS3="Select template name: "
    select template in "${templates[@]}"; do
        case $template in
            "")
                echo "Invalid selection, please enter a template name manually: "
                read -r template
                ;;
            *)
                break
                ;;
        esac
        break
    done

    existing_dirs=$(find "tasks/$network" -maxdepth 1 -type d 2>/dev/null | sort)
    echo ""
    echo "Existing directories: " 
    echo "${existing_dirs//$'\n'/$'\n  '}"

    # Find the highest number used in existing directory names
    # This is used to suggest the next available directory name.
    # If the number pattern is broken (001-task-name, 002-task-name, ...), this suggestion may not work.
    highest_num=0
    for dir in $existing_dirs; do
        basename=$(basename "$dir")
        if [[ $basename =~ ([0-9]{3}) ]]; then
            num=${BASH_REMATCH[1]}
            if (( 10#$num > highest_num )); then
                highest_num=$((10#$num))
            fi
        fi
    done
    next_num=$((highest_num + 1))
    suggested_name=$(printf "%03d-<enter-task-name>" $next_num)
    most_recent_task_dir=$(echo "$existing_dirs" | tail -n1)
    
    while true; do
        read -r -p "Enter task directory name (suggested: $suggested_name): " dirname
        if [[ -z "$dirname" ]]; then
            echo "Task directory name cannot be empty. Please try again."
        elif [[ -n "$most_recent_task_dir" && "$dirname" < "$(basename "$most_recent_task_dir")" ]]; then
            echo "Error: '$dirname' is lexicographically earlier than existing directories."
            echo "The last existing directory is: $(basename "$most_recent_task_dir")"
            echo "Please choose a name that comes after this alphabetically."
        else
            break
        fi
    done

    mkdir -p "tasks/${network}/${dirname}"
    config_path="tasks/${network}/${dirname}/config.toml"
    echo "template = \"${template}\"" > "${config_path}"
    echo "Created task directory '${dirname}' for network: ${network}"
}

# Run this function only if someone runs this script directly,
# not when it's imported by another script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    create_task
fi