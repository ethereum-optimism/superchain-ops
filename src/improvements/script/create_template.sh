#!/usr/bin/env bash

create_template() {
    while true; do
        if [ -t 0 ]; then
            echo ""
            read -r -p "Enter template file name (e.g. <template_name>.sol): " filename
        else
            read -r filename
        fi
        if [[ "$filename" == *.sol ]]; then
            touch "template/$filename"
            echo "Created template file: $filename"
            break
        else
            echo -e "\n\033[31mTemplate file cannot be empty and must end with '.sol'. Please try again.\033[0m"
        fi
    done
}

# Run this function only if someone runs this script directly,
# not when it's imported by another script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    create_template
fi
