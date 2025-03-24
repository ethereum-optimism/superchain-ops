#!/usr/bin/env bash

# Get the task type from justfile
# It can be L2TaskBase or SimpleBase
TASK_TYPE="$1"

create_template() {
    # Determine the directory of this script so we can locate the template file.
    script_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
    template_source="${script_dir}/../template/EmptyTemplate.template.sol"

    if [[ ! -f "$template_source" ]]; then
        echo -e "\n\033[31mTemplate file not found at: ${template_source}\033[0m"
        exit 1
    fi

    while true; do
        if [ -t 0 ]; then
            echo ""
            read -r -p "Enter template file name (e.g. <template_name>.sol): " filename
        else
            read -r filename
        fi

        if [[ "$filename" == *.sol ]]; then
            contract_name="${filename%.sol}"
            template_path="template/$filename"
            mkdir -p "$(dirname "$template_path")"
            # Replace all occurrences of "EmptyTemplate" in the template file with the chosen contract name.
            # Replace MultisigTask with the chosen task type.
            # Replace TASk_TYPE.sol with MultisigTask.sol
            # Remove the _configureTask and taskType functions. As these are
            # already implemented in the TASK_TYPE contract.
            # Remove the AddressRegistry and IGnosisSafe imports.
            sed -e "s/EmptyTemplate/${contract_name}/g" \
                -e "s/MultisigTask/${TASK_TYPE}/g" \
                -e "s/${TASK_TYPE}.sol/types\/${TASK_TYPE}.sol/g" \
                -e '/function _configureTask/,/}/d' \
                -e "s/, AddressRegistry//g" \
                -e '/import {IGnosisSafe}/d' \
                -e '/function taskType/,/}/d' \
                "$template_source" > "$template_path"
            # Remove the safeAddressString function if the task type is OPCMBaseTask
            if [[ "$TASK_TYPE" == "OPCMBaseTask" ]]; then
                sed -i '' '/function safeAddressString/,/}/d' "$template_path"
            fi
            absolute_path=$(realpath "$template_path")
            echo -e "\033[32mTask type: ${TASK_TYPE}\033[0m"
            echo -e "\n\033[32mTemplate created at:\033[0m"
            echo "$absolute_path"
            break
        else
            echo -e "\n\033[31mTemplate file name must end with '.sol'. Please try again.\033[0m"
        fi
    done
}

# Run this function only if someone runs this script directly,
# not when it's imported by another script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    create_template
fi
