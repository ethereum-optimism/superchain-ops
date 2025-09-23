#!/usr/bin/env bash

create_template() {
    # Determine the directory of this script so we can locate the template file.
    task_type=$1
    root_dir=$(git rev-parse --show-toplevel)
    template_source_dir="${root_dir}/src/improvements/template/boilerplate/"

    if [[ -z "$task_type" ]]; then
        echo -e "\n\033[31mNo task type provided. Available task types are: L2TaskBase, SimpleTaskBase, OPCMTaskBase\033[0m"
        exit 1
    fi

    if [[ ! -d "$template_source_dir" ]]; then
        echo -e "\n\033[31mTemplate source directory not found at: ${template_source_dir}\033[0m"
        exit 1
    fi

    while true; do
        if [ -t 0 ]; then
            echo ""
            echo -e "Enter template file name (e.g.\033[33m <template_name>.sol\033[0m)."
            echo "    - Make the name generic enough so that other developers know it is reusable."
            echo "    - Follow single responsibility: one task per template (see: TransferL1PAO and TransferL2PAO)."
            echo "    - Ideally, the name should start with a verb like 'Transfer', 'Update', 'Set'."
            echo "    - Avoid using 'Template' in the name."
            echo -e "\033[33mTip: Name with future reuse in mind.\033[0m"
            echo ""
            read -r -p "Filename: " filename
        else
            read -r filename
        fi

        if [[ "$filename" == *.sol ]]; then
            contract_name="${filename%.sol}"
            template_path="${root_dir}/src/improvements/template/${filename}"
            mkdir -p "$(dirname "$template_path")"
            
            template_source="${template_source_dir}/${task_type}.template.sol"
            if [[ ! -f "$template_source" ]]; then
                echo -e "\n\033[31mTemplate file not found at: ${template_source}\033[0m"
                exit 1
            fi

            existing_template_contract_name="${task_type}Template"
            sed -e "s/${existing_template_contract_name}/${contract_name}/g" \
                "$template_source" > "$template_path"

            absolute_path=$(realpath "$template_path")
            echo -e "\033[32mTask type: ${task_type}\033[0m"
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
    create_template "$1"
fi