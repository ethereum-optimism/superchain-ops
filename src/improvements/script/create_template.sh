#!/usr/bin/env bash

create_template() {
    while true; do
        if [ -t 0 ]; then
            read -r -p "Enter template file name (<template_name>.sol): " filename
        else
            read -r filename
        fi
        if [[ "$filename" == *.sol ]]; then
            touch "template/$filename"
            echo "Created template file: $filename"
            break
        else
            echo "Error: Template file must end with .sol. Please try again."
        fi
    done
}

# Run this function only if someone runs this script directly,
# not when it's imported by another script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    create_template
fi
