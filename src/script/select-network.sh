#!/usr/bin/env bash

# This is a list of supported networks.
# If you want the CLI to support more networks, add them here.
get_supported_networks() {
    echo "eth sep oeth opsep"
}

select_network() {
    local networks
    IFS=' ' read -r -a networks <<<"$(get_supported_networks)"
    PS3="Select network: "
    select network in "${networks[@]}" "Other (specify)"; do
        case $network in
        "Other (specify)")
            read -r -p "Enter custom network name: " network
            ;;
        "")
            echo "Invalid selection, please enter a network name manually: " >&2
            read -r network
            ;;
        esac
        break
    done
    echo -e "\n\033[32mYou selected: $network\033[0m" >&2
    echo "$network"
}
