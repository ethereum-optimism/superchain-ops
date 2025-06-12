#!/bin/bash
set -euo pipefail
if [[ -z "${TMPDIR:-}" ]]; then # Set a default value if TMPDIR is not set useful for the CI for example.
  TMPDIR=/tmp
fi

ANVIL_PID=""
LOGFILE=$(mktemp ${TMPDIR}/"sim-sequence.XXXXX")
LOGFILE_ANVIL=$(mktemp ${TMPDIR}/"anvil.XXXXX")
## Nonce Values
MAX_NONCE_ERROR=9999999 # This is a impossible value for a nonce, if the value is still this after the simulation it means there is an issue when fetching the nonce.

# Foundation Upgrade Safe nonce.
FUS_BEFORE=$MAX_NONCE_ERROR
# Foundation Operation Safe nonce.
FOS_BEFORE=$MAX_NONCE_ERROR
# Security Council Safe nonce.
SC_BEFORE=$MAX_NONCE_ERROR
SC_NONCE_ENV=$MAX_NONCE_ERROR
# L1 Proxy Admin Owner Safe nonce.
L1PAO_BEFORE=$MAX_NONCE_ERROR
# Chain Governor Safe nonce.
CG_BEFORE=$MAX_NONCE_ERROR
# Base Proxy Admin Owner Safe nonce.
BL1PAO_BEFORE=$MAX_NONCE_ERROR
# Base Owner Safe nonce.
BOS_BEFORE=$MAX_NONCE_ERROR
# Unichain 3of3 Safe nonce.
U3_BEFORE=$MAX_NONCE_ERROR
# Unichain Owner Safe nonce.
UOS_BEFORE=$MAX_NONCE_ERROR

# Nonce values from config.toml
FUS_NONCE_CONFIG=$MAX_NONCE_ERROR
FOS_NONCE_CONFIG=$MAX_NONCE_ERROR
SC_NONCE_CONFIG=$MAX_NONCE_ERROR
L1PAO_NONCE_CONFIG=$MAX_NONCE_ERROR
BL1PAO_NONCE_CONFIG=$MAX_NONCE_ERROR
BOS_NONCE_CONFIG=$MAX_NONCE_ERROR
U3_NONCE_CONFIG=$MAX_NONCE_ERROR
UOS_NONCE_CONFIG=$MAX_NONCE_ERROR

# DisplaySafeBeforeNonces checks and displays the nonces of all Safe contracts
# by comparing their on-chain nonces with the nonces specified in the environment file.
# For each Safe contract, it:
# 1. Fetches the on-chain nonce using cast call
# 2. Compares it with the nonce from the env file (if present)
# 3. Logs a warning if there's a mismatch
# 4. For Safes not found in the env file, displays their current on-chain nonce
#
# Parameters:
#   $1 - Message to display before nonce checks
#   $2 - Path to environment file containing SAFE_NONCE entries
#
# The function handles both mainnet and Sepolia network Safes based on IS_SEPOLIA flag

# Function to read nonce values from config.toml
reset_nonce() {
    FUS_NONCE_CONFIG=$MAX_NONCE_ERROR
    FOS_NONCE_CONFIG=$MAX_NONCE_ERROR
    SC_NONCE_CONFIG=$MAX_NONCE_ERROR
    L1PAO_NONCE_CONFIG=$MAX_NONCE_ERROR
    BL1PAO_NONCE_CONFIG=$MAX_NONCE_ERROR
    BOS_NONCE_CONFIG=$MAX_NONCE_ERROR
    U3_NONCE_CONFIG=$MAX_NONCE_ERROR
    UOS_NONCE_CONFIG=$MAX_NONCE_ERROR
}

read_addresses() {
    local addresses_file="$1"
    local network="$2"

    # Check if config file exists
    if [[ ! -f "$addresses_file" ]]; then
        echo "Error: addresses.toml file not found: $addresses_file" >&2
        return 1
    fi

    # Use yq to read the addresses section directly
    yq -p=toml -o=json ".$network" "$addresses_file" | jq -r 'to_entries[] | "\(.key) \(.value)"'
}

display_addresses() {
    local config_file="$1"

    echo "Addresses from $config_file:"
    read_addresses "$config_file" "$network" | while read -r key value; do
        echo "  $key: $value"
    done
}
read_nonce_v20() {
    local config_file="$1"

    # Check if config file exists
    if [[ ! -f "$config_file" ]]; then
        echo "Error: Config file not found: $config_file" >&2
        return 1
    fi

    # Convert toml to json and extract address:value pairs
    local json_data=$(yq -p=toml -o=json .stateOverrides "$config_file")
    # If there is no stateOverrides in the config file, return 1
    if [[ $json_data == "null" ]]; then
        return 1
    fi
    # Use jq to extract address:value pairs
    while IFS=: read -r addr value; do
        # Remove quotes and whitespace
        addr=$(echo "$addr" | tr -d '"' | tr -d ' ')
        value=$(echo "$value" | tr -d '"' | tr -d ' ')

        # Convert hex to decimal
        local nonce_decimal=$(echo $((value)))
        # Get safe name based on address
        local safe_name=""
        if [[ "$IS_SEPOLIA" == "TRUE" ]]; then
            case $addr in
                "$Fake_Foundation_Upgrade_Safe")
                    safe_name="Fake Foundation Upgrade Safe"
                    ;;
                "$Fake_Foundation_Operation_Safe")
                    safe_name="Fake Foundation Operation Safe"
                    ;;
                "$Fake_Security_Council_Safe")
                    safe_name="Fake Security Council"
                    ;;
                "$Fake_Proxy_Admin_Owner_Safe")
                    safe_name="Fake L1PAO"
                    ;;
                *)
                    safe_name="Unknown Safe"
                    ;;
            esac
        else
            case $addr in
                "$Foundation_Upgrade_Safe")
                    safe_name="Foundation Upgrade Safe"
                    ;;
                "$Foundation_Operation_Safe")
                    safe_name="Foundation Operation Safe"
                    ;;
                "$Security_Council_Safe")
                    safe_name="Security Council"
                    ;;
                "$Proxy_Admin_Owner_Safe")
                    safe_name="L1PAO"
                    ;;
                "$Base_Proxy_Admin_Owner_safe")
                    safe_name="Base Proxy Admin Owner"
                    ;;
                "$Base_Owner_Safe")
                    safe_name="Base Owner"
                    ;;
                "$Unichain_3of3_Safe")
                    safe_name="Unichain 3of3"
                    ;;
                "$Unichain_Owner_Safe")
                    safe_name="Unichain Owner"
                    ;;
                *)
                    safe_name="Unknown Safe"
                    ;;
            esac
        fi

        # Output the safe name and nonce
        echo "$safe_name=$nonce_decimal"
        echo "${safe_name}_ADDR=$addr"
    done < <(echo "$json_data" | jq -r 'to_entries[] | "\(.key):\(.value[].value)"')
}

# Function to display nonce values from config.toml
DisplaySafeBeforeNoncesv20() {

    local message="$1"
    local config_file="$2"

    echo -e "\n$message"

    # Get nonce values from config.toml
    local nonce_values=$(read_nonce_v20 "$config_file")

    # Process each nonce value
    while IFS='=' read -r key value; do
        if [[ $key == *_ADDR ]]; then
            # Skip address entries
            continue
        fi

        # Get the address for this safe
        local addr_key="${key}_ADDR"
        local addr=$(echo "$nonce_values" | grep "^$addr_key=" | cut -d'=' -f2)

        # Set the appropriate BEFORE variable
        if [[ "$IS_SEPOLIA" == "TRUE" ]]; then
            case $key in
                "Fake Foundation Upgrade Safe")
                    FUS_NONCE_CONFIG=$value
                    ;;
                "Fake Foundation Operation Safe")
                    FOS_NONCE_CONFIG=$value
                    ;;
                "Fake Security Council")
                    SC_NONCE_CONFIG=$value
                    ;;
                "Fake L1PAO")
                    L1PAO_NONCE_CONFIG=$value
                    ;;
                "Fake Base Owner Safe")
                    BOS_NONCE_CONFIG=$value
                    ;;
                "Fake Base Proxy Admin Owner Safe")
                    BL1PAO_NONCE_CONFIG=$value
                    ;;
            esac
        else
            case $key in
                "Foundation Upgrade Safe")
                    FUS_NONCE_CONFIG=$value
                    ;;
                "Foundation Operation Safe")
                    FOS_NONCE_CONFIG=$value
                    ;;
                "Security Council")
                    SC_NONCE_CONFIG=$value
                    ;;
                "L1PAO")
                    L1PAO_NONCE_CONFIG=$value
                    ;;
                "Base Proxy Admin Owner")
                    BL1PAO_NONCE_CONFIG=$value
                    ;;
                "Base Owner")
                    BOS_NONCE_CONFIG=$value
                    ;;
                "Unichain 3of3")
                    U3_NONCE_CONFIG=$value
                    ;;
                "Unichain Owner")
                    UOS_NONCE_CONFIG=$value
                    ;;
            esac

        fi
    done <<< "$nonce_values"
    if [[ "$IS_SEPOLIA" == "TRUE" ]]; then
            FUS_BEFORE=$(cast call $Fake_Foundation_Upgrade_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
            if [[ $FUS_NONCE_CONFIG -ne $MAX_NONCE_ERROR ]]; then
              if [[ $FUS_BEFORE -ne $FUS_NONCE_CONFIG ]]; then
                log_warning "Fake Foundation Upgrade Safe (FUS) [$Fake_Foundation_Upgrade_Safe] on-chain nonce: $FUS_BEFORE, env nonce: $FUS_NONCE_CONFIG: $FUS_BEFORE != $FUS_NONCE_CONFIG"
              else
                log_info "Fake Foundation Upgrade Safe (FUS) [$Fake_Foundation_Upgrade_Safe] on-chain nonce: $FUS_BEFORE, env nonce: $FUS_NONCE_CONFIG: $FUS_BEFORE == $FUS_NONCE_CONFIG"
              fi
            else
              echo "[+] $(date '+%Y-%m-%d %H:%M:%S') Fake Foundation Upgrade Safe (FUS) [$Foundation_Upgrade_Safe] on-chain nonce: $FUS_BEFORE (not in env file)"
            fi
            FOS_BEFORE=$(cast call $Fake_Foundation_Operation_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
            if [[ $FOS_NONCE_CONFIG -ne $MAX_NONCE_ERROR ]]; then
              if [[ $FOS_BEFORE -ne $FOS_NONCE_CONFIG ]]; then
              log_warning "Fake Foundation Operation Safe (FOS) [$Fake_Foundation_Operation_Safe] on-chain nonce: $FOS_BEFORE, env nonce: $FOS_NONCE_CONFIG: $FOS_BEFORE != $FOS_NONCE_CONFIG"
              else
                log_info "Fake Foundation Operation Safe (FOS) [$Fake_Foundation_Operation_Safe] on-chain nonce: $FOS_BEFORE, env nonce: $FOS_NONCE_CONFIG: $FOS_BEFORE == $FOS_NONCE_CONFIG"
              fi
            else
              echo "[+] $(date '+%Y-%m-%d %H:%M:%S') Fake Foundation Operation Safe (FOS) [$Fake_Foundation_Operation_Safe] on-chain nonce: $FOS_BEFORE (not in env file)"
            fi
            SC_BEFORE=$(cast call $Fake_Security_Council_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
            if [[ $SC_NONCE_CONFIG -ne $MAX_NONCE_ERROR ]]; then
              if [[ $SC_BEFORE -ne $SC_NONCE_CONFIG ]]; then
                log_warning "Fake Security Council Safe (SC) [$Fake_Security_Council_Safe] on-chain nonce: $SC_BEFORE, env nonce: $SC_NONCE_CONFIG: $SC_BEFORE != $SC_NONCE_CONFIG"
              else
                log_info "Fake Security Council Safe (SC) [$Fake_Security_Council_Safe] on-chain nonce: $SC_BEFORE, env nonce: $SC_NONCE_CONFIG: $SC_BEFORE == $SC_NONCE_CONFIG"
              fi
            else
              echo "[+] $(date '+%Y-%m-%d %H:%M:%S') Fake Security Council Safe (SC) [$Fake_Security_Council_Safe] on-chain nonce: $SC_BEFORE (not in env file)"
            fi
            L1PAO_BEFORE=$(cast call $Fake_Proxy_Admin_Owner_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
            if [[ $L1PAO_NONCE_CONFIG -ne $MAX_NONCE_ERROR ]]; then
              if [[ $L1PAO_BEFORE -ne $L1PAO_NONCE_CONFIG ]]; then
                log_warning "Fake L1 Proxy Admin Owner Safe (L1PAO) [$Fake_Proxy_Admin_Owner_Safe] on-chain nonce: $L1PAO_BEFORE, env nonce: $L1PAO_NONCE_CONFIG: $L1PAO_BEFORE != $L1PAO_NONCE_CONFIG"
              else
                log_info "Fake L1 Proxy Admin Owner Safe (L1PAO) [$Fake_Proxy_Admin_Owner_Safe] on-chain nonce: $L1PAO_BEFORE, env nonce: $L1PAO_NONCE_CONFIG: $L1PAO_BEFORE == $L1PAO_NONCE_CONFIG"
              fi
            else
              echo "[+] $(date '+%Y-%m-%d %H:%M:%S')Fake L1 Proxy Admin Owner Safe (L1PAO) [$Fake_Proxy_Admin_Owner_Safe] on-chain nonce: $L1PAO_BEFORE (not in env file)"
            fi
            BOS_BEFORE=$(cast call $Fake_Base_Owner_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
            if [[ $BOS_NONCE_CONFIG -ne $MAX_NONCE_ERROR ]]; then
              if [[ $BOS_BEFORE -ne $BOS_NONCE_CONFIG ]]; then
              log_warning "Fake Base Owner Safe (BOS) [$Fake_Base_Owner_Safe] on-chain nonce: $BOS_BEFORE, env nonce: $BOS_NONCE_CONFIG: $BOS_BEFORE != $BOS_NONCE_CONFIG"
            else
              log_info " Fake Base Owner Safe (BOS) [$Fake_Base_Owner_Safe] on-chain nonce: $BOS_BEFORE, env nonce: $BOS_NONCE_CONFIG: $BOS_BEFORE == $BOS_NONCE_CONFIG"
            fi
            else
              echo "[+] $(date '+%Y-%m-%d %H:%M:%S')Fake Base Owner Safe (BOS) [$Fake_Base_Owner_Safe] on-chain nonce: $BOS_BEFORE (not in env file)"
            fi
            BL1PAO_BEFORE=$(cast call $Fake_Base_Proxy_Admin_Owner_safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
            if [[ $BL1PAO_NONCE_CONFIG -ne $MAX_NONCE_ERROR ]]; then
              if [[ $BL1PAO_BEFORE -ne $BL1PAO_NONCE_CONFIG ]]; then
                log_warning "Fake Base Proxy Admin Owner Safe (BL1PAO) [$Fake_Base_Proxy_Admin_Owner_safe] on-chain nonce: $BL1PAO_BEFORE, env nonce: $BL1PAO_NONCE_CONFIG: $BL1PAO_BEFORE != $BL1PAO_NONCE_CONFIG"
              else
                log_info " Fake Base Proxy Admin Owner Safe (BL1PAO) [$Fake_Base_Proxy_Admin_Owner_safe] on-chain nonce: $BL1PAO_BEFORE, env nonce: $BL1PAO_NONCE_CONFIG: $BL1PAO_BEFORE == $BL1PAO_NONCE_CONFIG"
              fi
            else
              echo "[+] $(date '+%Y-%m-%d %H:%M:%S')Fake Base Proxy Admin Owner Safe (BL1PAO) [$Fake_Base_Proxy_Admin_Owner_safe] on-chain nonce: $BL1PAO_BEFORE (not in env file)"
            fi

    else
          FOS_BEFORE=$(cast call $Foundation_Operation_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
          if [[ $FOS_NONCE_CONFIG -ne $MAX_NONCE_ERROR ]]; then
            if [[ $FOS_BEFORE -ne $FOS_NONCE_CONFIG ]]; then
              log_warning "Foundation Operation Safe (FOS) [$Foundation_Operation_Safe] on-chain nonce: $FOS_BEFORE, env nonce: $FOS_NONCE_CONFIG: $FOS_BEFORE != $FOS_NONCE_CONFIG"
            else
            log_info "Foundation Operation Safe (FOS) [$Foundation_Operation_Safe] on-chain nonce: $FOS_BEFORE, env nonce: $FOS_NONCE_CONFIG: $FOS_BEFORE == $FOS_NONCE_CONFIG"
          fi
          else
            echo "[+] $(date '+%Y-%m-%d %H:%M:%S')Foundation Operation Safe (FOS) [$Foundation_Operation_Safe] on-chain nonce: $FOS_BEFORE (not in env file)"
          fi
          FUS_BEFORE=$(cast call $Foundation_Upgrade_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
          if [[ $FUS_NONCE_CONFIG -ne $MAX_NONCE_ERROR ]]; then
            if [[ $FUS_BEFORE -ne $FUS_NONCE_CONFIG ]]; then
              log_warning "Foundation Upgrade Safe (FUS) [$Foundation_Upgrade_Safe] on-chain nonce: $FUS_BEFORE, env nonce: $FUS_NONCE_CONFIG: $FUS_BEFORE != $FUS_NONCE_CONFIG"
            else
              log_info "Foundation Upgrade Safe (FUS) [$Foundation_Upgrade_Safe] on-chain nonce: $FUS_BEFORE, env nonce: $FUS_NONCE_CONFIG: $FUS_BEFORE == $FUS_NONCE_CONFIG"
            fi
          else
            echo "[+] $(date '+%Y-%m-%d %H:%M:%S')Foundation Upgrade Safe (FUS) [$Foundation_Upgrade_Safe] on-chain nonce: $FUS_BEFORE (not in env file)"
          fi

          SC_BEFORE=$(cast call $Security_Council_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
          if [[ $SC_NONCE_CONFIG -ne $MAX_NONCE_ERROR ]]; then
            if [[ $SC_BEFORE -ne $SC_NONCE_CONFIG ]]; then
              log_warning "Security Council Safe (SC) [$Security_Council_Safe] on-chain nonce: $SC_BEFORE, env nonce: $SC_NONCE_CONFIG: $SC_BEFORE != $SC_NONCE_CONFIG"
            else
              log_info "Security Council Safe (SC) [$Security_Council_Safe] on-chain nonce: $SC_BEFORE, env nonce: $SC_NONCE_CONFIG: $SC_BEFORE == $SC_NONCE_CONFIG"
            fi
          else
            echo "[+] $(date '+%Y-%m-%d %H:%M:%S')Security Council Safe (SC) [$Security_Council_Safe] on-chain nonce: $SC_BEFORE (not in env file)"
          fi

          L1PAO_BEFORE=$(cast call $Proxy_Admin_Owner_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
          if [[ $L1PAO_NONCE_CONFIG -ne $MAX_NONCE_ERROR ]]; then
            if [[ $L1PAO_BEFORE -ne $L1PAO_NONCE_CONFIG ]]; then
            log_warning "L1 Proxy Admin Owner Safe (L1PAO) [$Proxy_Admin_Owner_Safe] on-chain nonce: $L1PAO_BEFORE, env nonce: $L1PAO_NONCE_CONFIG: $L1PAO_BEFORE != $L1PAO_NONCE_CONFIG"
          else
            log_info "L1 Proxy Admin Owner Safe (L1PAO) [$Proxy_Admin_Owner_Safe] on-chain nonce: $L1PAO_BEFORE, env nonce: $L1PAO_NONCE_CONFIG: $L1PAO_BEFORE == $L1PAO_NONCE_CONFIG"
          fi
          else
            echo "[+] $(date '+%Y-%m-%d %H:%M:%S')L1 Proxy Admin Owner Safe (L1PAO) [$Proxy_Admin_Owner_Safe] on-chain nonce: $L1PAO_BEFORE (not in env file)"
          fi

          BOS_BEFORE=$(cast call $Base_Owner_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
          if [[ $BOS_NONCE_CONFIG -ne $MAX_NONCE_ERROR ]]; then
            if [[ $BOS_BEFORE -ne $BOS_NONCE_CONFIG ]]; then
            log_warning "Base Owner Safe (BOS) [$Base_Owner_Safe] on-chain nonce: $BOS_BEFORE, env nonce: $BOS_NONCE_CONFIG: $BOS_BEFORE != $BOS_NONCE_CONFIG"
          else
            log_info "Base Owner Safe (BOS) [$Base_Owner_Safe] on-chain nonce: $BOS_BEFORE, env nonce: $BOS_NONCE_CONFIG: $BOS_BEFORE == $BOS_NONCE_CONFIG"
          fi
          else
            echo "[+] $(date '+%Y-%m-%d %H:%M:%S')Base Owner Safe (BOS) [$Base_Owner_Safe] on-chain nonce: $BOS_BEFORE (not in env file)"
          fi
          BL1PAO_BEFORE=$(cast call $Base_Proxy_Admin_Owner_safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
          if [[ $BL1PAO_NONCE_CONFIG -ne $MAX_NONCE_ERROR ]]; then
            if [[ $BL1PAO_BEFORE -ne $BL1PAO_NONCE_CONFIG ]]; then
              log_warning "Base Proxy Admin Owner Safe (BL1PAO) [$Base_Proxy_Admin_Owner_safe] on-chain nonce: $BL1PAO_BEFORE, env nonce: $BL1PAO_NONCE_CONFIG: $BL1PAO_BEFORE != $BL1PAO_NONCE_CONFIG"
            else
              log_info "Base Proxy Admin Owner Safe (BL1PAO) [$Base_Proxy_Admin_Owner_safe] on-chain nonce: $BL1PAO_BEFORE, env nonce: $BL1PAO_NONCE_CONFIG: $BL1PAO_BEFORE == $BL1PAO_NONCE_CONFIG"
            fi
          else
            echo "[+] $(date '+%Y-%m-%d %H:%M:%S')Base Proxy Admin Owner Safe (BL1PAO) [$Base_Proxy_Admin_Owner_safe] on-chain nonce: $BL1PAO_BEFORE (not in env file)"
          fi

          U3_BEFORE=$(cast call $Unichain_3of3_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
          if [[ $U3_NONCE_CONFIG -ne $MAX_NONCE_ERROR ]]; then
            if [[ $U3_BEFORE -ne $U3_NONCE_CONFIG ]]; then
            log_warning "Unichain 3of3 Safe (U3) [$Unichain_3of3_Safe] on-chain nonce: $U3_BEFORE, env nonce: $U3_NONCE_CONFIG: $U3_BEFORE != $U3_NONCE_CONFIG"
          else
            log_info "Unichain 3of3 Safe (U3) [$Unichain_3of3_Safe] on-chain nonce: $U3_BEFORE, env nonce: $U3_NONCE_CONFIG: $U3_BEFORE == $U3_NONCE_CONFIG"
          fi
          else
            echo "[+] $(date '+%Y-%m-%d %H:%M:%S')Unichain 3of3 Safe (U3) [$Unichain_3of3_Safe] on-chain nonce: $U3_BEFORE (not in env file)"
          fi

          UOS_BEFORE=$(cast call $Unichain_Owner_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
          if [[ $UOS_NONCE_CONFIG -ne $MAX_NONCE_ERROR ]]; then
            if [[ $UOS_BEFORE -ne $UOS_NONCE_CONFIG ]]; then
              log_warning "Unichan Owner Safe (UOS) [$Unichain_Owner_Safe] on-chain nonce: $UOS_BEFORE, env nonce: $UOS_NONCE_CONFIG: $UOS_BEFORE != $UOS_NONCE_CONFIG"
            else
              log_info "Unichain Owner Safe (UOS) [$Unichain_Owner_Safe] on-chain nonce: $UOS_BEFORE, env nonce: $UOS_NONCE_CONFIG: $UOS_BEFORE == $UOS_NONCE_CONFIG"
            fi
          else
            echo "[+] $(date '+%Y-%m-%d %H:%M:%S')Unichain Owner Safe (UOS) [$Unichain_Owner_Safe] on-chain nonce: $UOS_BEFORE (not in env file)"
          fi
    fi
}

DisplaySafeBeforeNonces() {

  echo -e "\n$1"
  local env_file=$2

  # Extract all SAFE_NONCE entries from the env file
  local safe_nonces=$(grep -E "^SAFE_NONCE_" "$env_file" || echo "")

  # Create arrays to track which addresses have been found in the env file
  local found_addresses=()

  # Loop through each SAFE_NONCE entry
  for nonce_entry in $safe_nonces; do
    # Extract the address part (after SAFE_NONCE_)
    local addr=$(echo "$nonce_entry" | grep -o -E "SAFE_NONCE_0X[a-fA-F0-9]{40}" | cut -d'_' -f3)
    local current_nonce=$(echo "$nonce_entry" | cut -d'=' -f2 | tr -d '"')
    # Convert to uppercase for case-insensitive comparison
    local addr_upper=$(echo "$addr" | tr '[:lower:]' '[:upper:]')

    # Add to found addresses list
    found_addresses+=("$addr_upper")

    # Check for Foundation Upgrade Safe
    if [[ "$addr_upper" == $(echo "$Foundation_Upgrade_Safe" | tr '[:lower:]' '[:upper:]') ]]; then
      FUS_BEFORE=$(cast call $Foundation_Upgrade_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
      FUS_NONCE_ENV=$current_nonce
      if [[ $FUS_BEFORE -ne $FUS_NONCE_ENV ]]; then
        log_warning "Foundation Upgrade Safe (FUS) [$Foundation_Upgrade_Safe] on-chain nonce: $FUS_BEFORE, env nonce: $FUS_NONCE_ENV: $FUS_BEFORE != $FUS_NONCE_ENV"
      else
        log_info "Foundation Upgrade Safe (FUS) [$Foundation_Upgrade_Safe] on-chain nonce: $FUS_BEFORE, env nonce: $FUS_NONCE_ENV: $FUS_BEFORE == $FUS_NONCE_ENV"
      fi
    fi

    # Check for Foundation Operation Safe
    if [[ "$addr_upper" == $(echo "$Foundation_Operation_Safe" | tr '[:lower:]' '[:upper:]') ]]; then
      FOS_BEFORE=$(cast call $Foundation_Operation_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
      FOS_NONCE_ENV=$current_nonce
      if [[ $FOS_BEFORE -ne $FOS_NONCE_ENV ]]; then
        log_warning "Foundation Operation Safe (FOS) [$Foundation_Operation_Safe] on-chain nonce: $FOS_BEFORE, env nonce: $FOS_NONCE_ENV: $FOS_BEFORE != $FOS_NONCE_ENV"
      else
        log_info "Foundation Operation Safe (FOS) [$Foundation_Operation_Safe] on-chain nonce: $FOS_BEFORE, env nonce: $FOS_NONCE_ENV: $FOS_BEFORE == $FOS_NONCE_ENV"
      fi
    fi

    # Check for Security Council Safe
    if [[ "$addr_upper" == $(echo "$Security_Council_Safe" | tr '[:lower:]' '[:upper:]') ]]; then
      SC_BEFORE=$(cast call $Security_Council_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
      SC_NONCE_ENV=$current_nonce
      if [[ $SC_BEFORE -ne $SC_NONCE_ENV ]]; then
        log_warning "Security Council Safe (SC) [$Security_Council_Safe] on-chain nonce: $SC_BEFORE, env nonce: $SC_NONCE_ENV: $SC_BEFORE != $SC_NONCE_ENV"
      else
        log_info "Security Council Safe (SC) [$Security_Council_Safe] on-chain nonce: $SC_BEFORE, env nonce: $SC_NONCE_ENV: $SC_BEFORE == $SC_NONCE_ENV"
      fi
    fi

    # Check for L1 Proxy Admin Owner Safe
    if [[ "$addr_upper" == $(echo "$Proxy_Admin_Owner_Safe" | tr '[:lower:]' '[:upper:]') ]]; then
      L1PAO_BEFORE=$(cast call $Proxy_Admin_Owner_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
      L1PAO_NONCE_ENV=$current_nonce
      if [[ $L1PAO_BEFORE -ne $L1PAO_NONCE_ENV ]]; then
        log_warning "L1 Proxy Admin Owner Safe (L1PAO) [$Proxy_Admin_Owner_Safe] on-chain nonce: $L1PAO_BEFORE, env nonce: $L1PAO_NONCE_ENV: $L1PAO_BEFORE != $L1PAO_NONCE_ENV"
      else
        log_info "L1 Proxy Admin Owner Safe (L1PAO) [$Proxy_Admin_Owner_Safe] on-chain nonce: $L1PAO_BEFORE, env nonce: $L1PAO_NONCE_ENV: $L1PAO_BEFORE == $L1PAO_NONCE_ENV"
      fi
    fi

    # Check for Base Proxy Admin Owner Safe
    if [[ "$addr_upper" == $(echo "$Base_Proxy_Admin_Owner_safe" | tr '[:lower:]' '[:upper:]') ]]; then
      BL1PAO_BEFORE=$(cast call $Base_Proxy_Admin_Owner_safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
      BL1PAO_NONCE_ENV=$current_nonce
      if [[ $BL1PAO_BEFORE -ne $BL1PAO_NONCE_ENV ]]; then
        log_warning "Base Proxy Admin Owner Safe (BL1PAO) [$Base_Proxy_Admin_Owner_safe] on-chain nonce: $BL1PAO_BEFORE, env nonce: $BL1PAO_NONCE_ENV: $BL1PAO_BEFORE != $BL1PAO_NONCE_ENV"
      else
        log_info "Base Proxy Admin Owner Safe (BL1PAO) [$Base_Proxy_Admin_Owner_safe] on-chain nonce: $BL1PAO_BEFORE, env nonce: $BL1PAO_NONCE_ENV: $BL1PAO_BEFORE == $BL1PAO_NONCE_ENV"
      fi
    fi

    # Check for Base Owner Safe
    if [[ "$addr_upper" == $(echo "$Base_Owner_Safe" | tr '[:lower:]' '[:upper:]') ]]; then
      BOS_BEFORE=$(cast call $Base_Owner_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
      BOS_NONCE_ENV=$current_nonce
      if [[ $BOS_BEFORE -ne $BOS_NONCE_ENV ]]; then
        log_warning "Base Owner Safe (BOS) [$Base_Owner_Safe] on-chain nonce: $BOS_BEFORE, env nonce: $BOS_NONCE_ENV: $BOS_BEFORE != $BOS_NONCE_ENV"
      else
        log_info "Base Owner Safe (BOS) [$Base_Owner_Safe] on-chain nonce: $BOS_BEFORE, env nonce: $BOS_NONCE_ENV: $BOS_BEFORE == $BOS_NONCE_ENV"
      fi
    fi

    # Check for Unichain 3of3 Safe

    if [[ "$addr_upper" == $(echo "$Unichain_3of3_Safe" | tr '[:lower:]' '[:upper:]') ]]; then
      U3_BEFORE=$(cast call $Unichain_3of3_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
      U3_NONCE_ENV=$current_nonce
      if [[ $U3_BEFORE -ne $U3_NONCE_ENV ]]; then
        log_warning "Unichain 3of3 Safe (U3) [$Unichain_3of3_Safe] on-chain nonce: $U3_BEFORE, env nonce: $U3_NONCE_ENV: $U3_BEFORE != $U3_NONCE_ENV"
      else
        log_info "Unichain 3of3 Safe (U3) [$Unichain_3of3_Safe] on-chain nonce: $U3_BEFORE, env nonce: $U3_NONCE_ENV: $U3_BEFORE == $U3_NONCE_ENV"
      fi
    fi

    # Check for Unichain Owner Safe
    if [[ "$addr_upper" == $(echo "$Unichain_Owner_Safe" | tr '[:lower:]' '[:upper:]') ]]; then
      UOS_BEFORE=$(cast call $Unichain_Owner_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
      UOS_NONCE_ENV=$current_nonce
      if [[ $UOS_BEFORE -ne $UOS_NONCE_ENV ]]; then
        log_warning "Unichain Owner Safe (UOS) [$Unichain_Owner_Safe] on-chain nonce: $UOS_BEFORE, env nonce: $UOS_NONCE_ENV: $UOS_BEFORE != $UOS_NONCE_ENV"
      else
        log_info "Unichain Owner Safe (UOS) [$Unichain_Owner_Safe] on-chain nonce: $UOS_BEFORE, env nonce: $UOS_NONCE_ENV: $UOS_BEFORE == $UOS_NONCE_ENV"
      fi
    fi
    # Sepolia
    if [[ "$IS_SEPOLIA" == "TRUE" ]]; then
        # Check for Fake Foundation Upgrade Safe (Sepolia)
    if [[ "$addr_upper" == $(echo "$Fake_Foundation_Upgrade_Safe" | tr '[:lower:]' '[:upper:]') ]]; then
      FUS_BEFORE=$(cast call $Fake_Foundation_Upgrade_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
      FUS_NONCE_ENV=$current_nonce
      if [[ $FUS_BEFORE -ne $FUS_NONCE_ENV ]]; then
        log_warning "Fake Foundation Upgrade Safe (FUS) [$Fake_Foundation_Upgrade_Safe] on-chain nonce: $FUS_BEFORE, env nonce: $FUS_NONCE_ENV: $FUS_BEFORE != $FUS_NONCE_ENV"
      else
        log_info "Fake Foundation Upgrade Safe (FUS) [$Fake_Foundation_Upgrade_Safe] on-chain nonce: $FUS_BEFORE, env nonce: $FUS_NONCE_ENV: $FUS_BEFORE == $FUS_NONCE_ENV"
      fi
    fi

    # Check for Fake Foundation Operation Safe (Sepolia)
    if [[ "$addr_upper" == $(echo "$Fake_Foundation_Operation_Safe" | tr '[:lower:]' '[:upper:]') ]]; then
      FOS_BEFORE=$(cast call $Fake_Foundation_Operation_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
      FOS_NONCE_ENV=$current_nonce
      if [[ $FOS_BEFORE -ne $FOS_NONCE_ENV ]]; then
        log_warning "Fake Foundation Operation Safe (FOS) [$Fake_Foundation_Operation_Safe] on-chain nonce: $FOS_BEFORE, env nonce: $FOS_NONCE_ENV: $FOS_BEFORE != $FOS_NONCE_ENV"
      else
        log_info "Fake Foundation Operation Safe (FOS) [$Fake_Foundation_Operation_Safe] on-chain nonce: $FOS_BEFORE, env nonce: $FOS_NONCE_ENV: $FOS_BEFORE == $FOS_NONCE_ENV"
      fi
    fi

    # Check for Fake Security Council Safe (Sepolia)
    if [[ "$addr_upper" == $(echo "$Fake_Security_Council_Safe" | tr '[:lower:]' '[:upper:]') ]]; then
      SC_BEFORE=$(cast call $Fake_Security_Council_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
      SC_NONCE_ENV=$current_nonce
      if [[ $SC_BEFORE -ne $SC_NONCE_ENV ]]; then
        log_warning "Fake Security Council Safe (SC) [$Fake_Security_Council_Safe] on-chain nonce: $SC_BEFORE, env nonce: $SC_NONCE_ENV: $SC_BEFORE != $SC_NONCE_ENV"
      else
        log_info "Fake Security Council Safe (SC) [$Fake_Security_Council_Safe] on-chain nonce: $SC_BEFORE, env nonce: $SC_NONCE_ENV: $SC_BEFORE == $SC_NONCE_ENV"
      fi
    fi

    # Check for Fake Proxy Admin Owner Safe (Sepolia)
    if [[ "$addr_upper" == $(echo "$Fake_Proxy_Admin_Owner_Safe" | tr '[:lower:]' '[:upper:]') ]]; then
      L1PAO_BEFORE=$(cast call $Fake_Proxy_Admin_Owner_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
      L1PAO_NONCE_ENV=$current_nonce
      if [[ $L1PAO_BEFORE -ne $L1PAO_NONCE_ENV ]]; then
        log_warning "Fake L1 Proxy Admin Owner Safe (L1PAO) [$Fake_Proxy_Admin_Owner_Safe] on-chain nonce: $L1PAO_BEFORE, env nonce: $L1PAO_NONCE_ENV: $L1PAO_BEFORE != $L1PAO_NONCE_ENV"
      else
        log_info "Fake L1 Proxy Admin Owner Safe (L1PAO) [$Fake_Proxy_Admin_Owner_Safe] on-chain nonce: $L1PAO_BEFORE, env nonce: $L1PAO_NONCE_ENV: $L1PAO_BEFORE == $L1PAO_NONCE_ENV"
      fi
    fi
  fi
  done

  # Now display all safes that weren't found in the env file
  if [[ "$IS_SEPOLIA" == "TRUE" ]]; then
    # Handle Sepolia safes
    local all_safes=(
      "$Fake_Foundation_Upgrade_Safe:FUS:Foundation Upgrade Safe"
      "$Fake_Foundation_Operation_Safe:FOS:Foundation Operation Safe"
      "$Fake_Security_Council_Safe:SC:Security Council Safe"
      "$Fake_Proxy_Admin_Owner_Safe:L1PAO:L1 Proxy Admin Owner Safe"
    )
  else
    # Handle mainnet safes
    local all_safes=(
      "$Foundation_Upgrade_Safe:FUS:Foundation Upgrade Safe"
      "$Foundation_Operation_Safe:FOS:Foundation Operation Safe"
      "$Security_Council_Safe:SC:Security Council Safe"
      "$Proxy_Admin_Owner_Safe:L1PAO:L1 Proxy Admin Owner Safe"
      "$Base_Proxy_Admin_Owner_safe:BL1PAO:Base Proxy Admin Owner Safe"
      "$Base_Owner_Safe:BOS:Base Owner Safe"
      "$Unichain_3of3_Safe:U3:Unichain 3of3 Safe"
      "$Unichain_Owner_Safe:UOS:Unichain Owner Safe"
    )
  fi

  # Display safes not found in env file
  # set -x
  for safe_info in "${all_safes[@]}"; do
    IFS=':' read -r safe_addr var_name safe_name <<< "$safe_info"
    local safe_addr_upper=$(echo "$safe_addr" | tr '[:lower:]' '[:upper:]')

    # Check if this address was already found in the env file
    local found=false
    if [[ ${#found_addresses[@]} -gt 0 ]]; then
      for found_addr in "${found_addresses[@]}"; do
        if [[ "$found_addr" == "$safe_addr_upper" ]]; then
          found=true
          break
        fi
      done
    fi

    if [[ "$found" == "false" ]]; then
      local current_nonce=$(cast call $safe_addr "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
      # Set the corresponding variable
      eval "${var_name}_BEFORE=$current_nonce"
      echo "[+] $(date '+%Y-%m-%d %H:%M:%S') $safe_name ($var_name) [$safe_addr] on-chain nonce: $current_nonce (not in env file)"
    fi
  done
}

IS_3_OF_3=0
ANVIL_LOCALHOST_RPC="http://localhost:8545"
IS_SEPOLIA=FALSE
## LOG utilies
log_debug() {
    echo "[-] $(date '+%Y-%m-%d %H:%M:%S') [DEBUG] $1" | tee -a "$LOGFILE"
}

# Function to log warning messages
log_warning() {
    echo -e "\033[0;33m[⚠️] $(date '+%Y-%m-%d %H:%M:%S') [WARNING] $1\033[0m" | tee -a "$LOGFILE"
}

# Function to log error messages and exit the script
log_error() {
    echo -e "\033[0;31m[❌] $(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1\033[0m" | tee -a "$LOGFILE" >&2
}

log_info() {
    echo -e "\033[0;34m[ℹ️] $(date '+%Y-%m-%d %H:%M:%S') [INFO] $1\033[0m" | tee -a "$LOGFILE"
}

# Log the nonce with error and exit the script.
log_nonce_error() {
  echo -e "\033[0;31mFoundation Upgrade Safe (FuS) [$Foundation_Upgrade_Safe] nonce: "$FUS_BEFORE".\033[0m"
  echo -e "\033[0;31mFoundation Operation Safe (FoS) [$Foundation_Operation_Safe] nonce: "$FOS_BEFORE".\033[0m"
  echo -e "\033[0;31mSecurity Council Safe (SC) [$Security_Council_Safe] nonce: "$SC_BEFORE".\033[0m"
  echo -e "\033[0;31mL1ProxyAdminOwner (L1PAO) [$Proxy_Admin_Owner_Safe] nonce: "$L1PAO_BEFORE".\033[0m"
  echo -e "\033[0;31mBase Proxy Admin Owner (BL1PAO) [$Base_Proxy_Admin_Owner_safe] nonce: "$BL1PAO_BEFORE".\033[0m"
  echo -e "\033[0;31mBase Owner (BOS) [$Base_Owner_Safe] nonce: "$BOS_BEFORE".\033[0m"
  echo -e "\033[0;31mUnichain 3of3 (U3) [$Unichain_3of3_Safe] nonce: "$U3_BEFORE".\033[0m"
  echo -e "\033[0;31mUnichain Owner (UOS) [$Unichain_Owner_Safe] nonce: "$UOS_BEFORE".\033[0m"
  exit 1

}


#TODO: GET THE ADDRESSES FROM SUPERCHAIN-REGISTRY IN THE FUTURE, since they are the safes addresses this sholdn't change so often so this fine.

## Chain Governor Safe
Chain_Governor_Safe=""

## MAINNET
# SC
Security_Council_Safe=0xc2819DC788505Aac350142A7A707BF9D03E3Bd03
# FUS
Foundation_Upgrade_Safe=0x847B5c174615B1B7fDF770882256e2D3E95b9D92
# FOS
Foundation_Operation_Safe=0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A
# L1PAO
Proxy_Admin_Owner_Safe=0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A
# BL1PAO
Base_Proxy_Admin_Owner_safe=0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c
# BOS
Base_Owner_Safe=0x9855054731540A48b28990B63DcF4f33d8AE46A1
# U3
Unichain_3of3_Safe=0x6d5B183F538ABB8572F5cD17109c617b994D5833
# UOS
Unichain_Owner_Safe=0xb0c4C487C5cf6d67807Bc2008c66fa7e2cE744EC

## SEPOLIA
#SSC
Fake_Security_Council_Safe=0xf64bc17485f0B4Ea5F06A96514182FC4cB561977
# SFUS
Fake_Foundation_Upgrade_Safe=0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B
# SFOS
Fake_Foundation_Operation_Safe=0x837DE453AD5F21E89771e3c06239d8236c0EFd5E
# SEPL1PAO
Fake_Proxy_Admin_Owner_Safe=0x1Eb2fFc903729a0F03966B917003800b145F56E2
# Fake BOS 
Fake_Base_Owner_Safe=0x6AF0674791925f767060Dd52f7fB20984E8639d8
# Fake BL1PAO
Fake_Base_Proxy_Admin_Owner_safe=0x0fe884546476dDd290eC46318785046ef68a0BA9
# Fake Nested Safe
Fake_Base_Nested_Safe=0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f

DESTROY_ANVIL_AFTER_EXECUTION=true

error_exit() {
  echo "Error: $1" >&2
  exit 1
}

# Disable state overrides in Simulation.sol. The only state override currently
# disabled is the nonce override.
disable_state_overrides() {
  # Create a backup
  local simulation_file="$root_dir/lib/base-contracts/script/universal/Simulation.sol"
  local backup_file="${simulation_file}.bak"
  cp "$simulation_file" "$backup_file"

  # Comment out lines containing 'state = addNonceOverride'.
  awk '/state = addNonceOverride/ { print "        // " $0; next } { print }' "$simulation_file" > "${simulation_file}.tmp"

  # Replace the original file with the modified version, and ensure cleanup on exit.
  mv "${simulation_file}.tmp" "$simulation_file"
  trap cleanup EXIT
}

cleanup() {
  unset SIMULATE_WITHOUT_LEDGER

  local simulation_file="$root_dir/lib/base-contracts/script/universal/Simulation.sol"
  local backup_file="${simulation_file}.bak"

  if [[ -f "$backup_file" ]]; then
    mv "$backup_file" "$simulation_file"
  fi

  # Kill the anvil fork at the end if it was started by this script
  if $DESTROY_ANVIL_AFTER_EXECUTION; then
    echo "Kill anvil with the PID: \"$ANVIL_PID\" since the flag DESTROY_ANVIL_AFTER_EXECUTION is set to \"TRUE\"."
    kill -9 $ANVIL_PID
  fi
}

createFork() {
  # Start a fork
  # check if the port is already open
  if lsof -Pi :8545 -sTCP:LISTEN -t >/dev/null ; then
    log_warning "Anvil is detected and running on port 8545, we use the current instance of anvil."
    DESTROY_ANVIL_AFTER_EXECUTION=false
  else
    log_info "No instance of anvil is detected, starting anvil fork on \"$ANVIL_LOCALHOST_RPC\" by forking $RPC_URL."
    if [[ -n "$block_number" ]]; then
      anvil -f $RPC_URL --fork-block-number $block_number >> $LOGFILE_ANVIL &
      ANVIL_PID=$!
    else
      anvil -f $RPC_URL >> $LOGFILE_ANVIL &
      ANVIL_PID=$!

    fi
    sleep 5
  fi
}

NonceDisplayModified(){
  echo -e "\n$1"

  if [[ "$IS_SEPOLIA" == "TRUE" ]]; then
    # Only get and display Sepolia safes
    if [[ $FUS_BEFORE -eq $MAX_NONCE_ERROR || $FOS_BEFORE -eq $MAX_NONCE_ERROR || $SC_BEFORE -eq $MAX_NONCE_ERROR || $L1PAO_BEFORE -eq $MAX_NONCE_ERROR ]]; then
      log_error "Nonce values are not available for one or more Sepolia safes please investigate."
      exit 99
    fi

    FUS_AFTER=$(cast call $Fake_Foundation_Upgrade_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    FOS_AFTER=$(cast call $Fake_Foundation_Operation_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    SC_AFTER=$(cast call $Fake_Security_Council_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    L1PAO_AFTER=$(cast call $Fake_Proxy_Admin_Owner_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)

    if [[ $FUS_BEFORE -ne $FUS_AFTER ]]; then
      echo -e "\033[0;32mFake Foundation Upgrade Safe (FuS) [$Fake_Foundation_Upgrade_Safe] nonce: "$FUS_AFTER" ("$FUS_BEFORE" -> "$FUS_AFTER").\033[0m"
    else
      echo "Fake Foundation Upgrade Safe (FuS) [$Fake_Foundation_Upgrade_Safe] nonce: "$(cast call $Fake_Foundation_Upgrade_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)"."
    fi

    if [[ $FOS_BEFORE -ne $FOS_AFTER ]]; then
      echo -e "\033[0;32mFake Foundation Operation Safe (FoS) [$Fake_Foundation_Operation_Safe] nonce: "$FOS_AFTER" ("$FOS_BEFORE" -> "$FOS_AFTER").\033[0m"
    else
      echo "Fake Foundation Operation Safe (FoS) [$Fake_Foundation_Operation_Safe] nonce: "$(cast call $Fake_Foundation_Operation_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)"."
    fi

    if [[ $SC_BEFORE -ne $SC_AFTER ]]; then
      echo -e "\033[0;32mFake Security Council Safe (SC) [$Fake_Security_Council_Safe] nonce: "$SC_AFTER" ("$SC_BEFORE" -> "$SC_AFTER").\033[0m"
    else
      echo "Fake Security Council Safe (SC) [$Fake_Security_Council_Safe] nonce: "$(cast call $Fake_Security_Council_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)"."
    fi

    if [[ $L1PAO_BEFORE -ne $L1PAO_AFTER ]]; then
      echo -e "\033[0;32mFake L1ProxyAdminOwner (L1PAO) [$Fake_Proxy_Admin_Owner_Safe] nonce: "$L1PAO_AFTER" ("$L1PAO_BEFORE" -> "$L1PAO_AFTER").\033[0m"
    else
      echo "Fake L1ProxyAdminOwner (L1PAO) [$Fake_Proxy_Admin_Owner_Safe] nonce: "$(cast call $Fake_Proxy_Admin_Owner_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)"."
    fi
  else
    # Handle mainnet safes (existing code)
    if [[ $FUS_BEFORE -eq $MAX_NONCE_ERROR || $FOS_BEFORE -eq $MAX_NONCE_ERROR || $SC_BEFORE -eq $MAX_NONCE_ERROR ]]; then
      log_error "Nonce values are not available for one or more safes please investigate."
      exit 99
    fi

    if [[ $IS_3_OF_3 -eq 1 ]]; then
      IS_3_OF_3=0 #Reset the 3_OF_3 flag
      Chain_Governor_Safe="" # Reset the Chain_Governor_Safe
    fi
    FUS_AFTER=$(cast call $Foundation_Upgrade_Safe  "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    FOS_AFTER=$(cast call $Foundation_Operation_Safe  "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    SC_AFTER=$(cast call $Security_Council_Safe  "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    L1PAO_AFTER=$(cast call $Proxy_Admin_Owner_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    BL1PAO_AFTER=$(cast call $Base_Proxy_Admin_Owner_safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    BOS_AFTER=$(cast call $Base_Owner_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    U3_AFTER=$(cast call $Unichain_3of3_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    UOS_AFTER=$(cast call $Unichain_Owner_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)

    if [[ $FUS_BEFORE -ne $FUS_AFTER ]]; then
      echo -e "\033[0;32mFoundation Upgrade Safe (FuS) [$Foundation_Upgrade_Safe] nonce: "$FUS_AFTER" ("$FUS_BEFORE" -> "$FUS_AFTER").\033[0m"
    else
      echo "Foundation Upgrade Safe (FuS) [$Foundation_Upgrade_Safe] nonce: "$(cast call $Foundation_Upgrade_Safe  "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)"."
    fi

    if [[ $FOS_BEFORE -ne $FOS_AFTER ]]; then
      echo -e "\033[0;32mFoundation Operation Safe (FoS) [$Foundation_Operation_Safe] nonce: "$FOS_AFTER" ("$FOS_BEFORE" -> "$FOS_AFTER").\033[0m"
    else
      echo "Foundation Operation Safe (FoS) [$Foundation_Operation_Safe] nonce: "$(cast call $Foundation_Operation_Safe  "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)"."
    fi
    if [[ $SC_BEFORE -ne $SC_AFTER ]]; then
      echo -e "\033[0;32mSecurity Council Safe (SC) [$Security_Council_Safe] nonce: "$SC_AFTER" ("$SC_BEFORE" -> "$SC_AFTER").\033[0m"
    else
      echo "Security Council Safe (SC) [$Security_Council_Safe] nonce: "$(cast call $Security_Council_Safe  "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)"."
    fi
    if [[ $L1PAO_BEFORE -ne $L1PAO_AFTER ]]; then
      echo -e "\033[0;32mL1ProxyAdminOwner (L1PAO) [$Proxy_Admin_Owner_Safe] nonce: "$L1PAO_AFTER" ("$L1PAO_BEFORE" -> "$L1PAO_AFTER").\033[0m"
    else
      echo "L1ProxyAdminOwner (L1PAO) [$Proxy_Admin_Owner_Safe] nonce: "$(cast call $Proxy_Admin_Owner_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)"."
    fi
    if [[ $BOS_BEFORE -ne $BOS_AFTER ]]; then
      echo -e "\033[0;32mBase Owner (BOS) [$Base_Owner_Safe] nonce: "$BOS_AFTER" ("$BOS_BEFORE" -> "$BOS_AFTER").\033[0m"
    else
      echo "Base Owner (BOS) [$Base_Owner_Safe] nonce: "$(cast call $Base_Owner_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)"."
    fi
    if [[ $BL1PAO_BEFORE -ne $BL1PAO_AFTER ]]; then
      echo -e "\033[0;32mBase Proxy Admin Owner (BL1PAO) [$Base_Proxy_Admin_Owner_safe] nonce: "$BL1PAO_AFTER" ("$BL1PAO_BEFORE" -> "$BL1PAO_AFTER").\033[0m"
    else
      echo "Base Proxy Admin Owner (BL1PAO) [$Base_Proxy_Admin_Owner_safe] nonce: "$(cast call $Base_Proxy_Admin_Owner_safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)"."
    fi
    if [[ $U3_BEFORE -ne $U3_AFTER ]]; then
      echo -e "\033[0;32mUnichain 3of3 (U3) [$Unichain_3of3_Safe] nonce: "$U3_AFTER" ("$U3_BEFORE" -> "$U3_AFTER").\033[0m"
    else
      echo "Unichain 3of3 (U3) [$Unichain_3of3_Safe] nonce: "$(cast call $Unichain_3of3_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)"."
    fi
    if [[ $UOS_BEFORE -ne $UOS_AFTER ]]; then
      echo -e "\033[0;32mUnichain Owner (UOS) [$Unichain_Owner_Safe] nonce: "$UOS_AFTER" ("$UOS_BEFORE" -> "$UOS_AFTER").\033[0m"
    else
      echo "Unichain Owner (UOS) [$Unichain_Owner_Safe] nonce: "$(cast call $Unichain_Owner_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)"."
    fi
  fi
}

# Displays nonces from environment variables when available, highlighting them in orange
# and showing the difference with on-chain values
DisplayNonceFromEnv() {
  echo -e "\n$1"

  # Read nonce values from .env file
  local env_file="$2"
  log_info "env_file: $env_file"

  # Read all SAFE_NONCE entries from the env file
  local safe_nonces=$(grep -E "^SAFE_NONCE_" "$env_file" || echo "")

  if [[ "$IS_SEPOLIA" == "TRUE" ]]; then
    # Get current on-chain nonces for Sepolia
    local fus_chain=$(cast call $Fake_Foundation_Upgrade_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    local fos_chain=$(cast call $Fake_Foundation_Operation_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    local sc_chain=$(cast call $Fake_Security_Council_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    local l1pao_chain=$(cast call $Fake_Proxy_Admin_Owner_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)

    # Display Sepolia nonces
    echo "Fake Foundation Upgrade Safe (FuS) [$Fake_Foundation_Upgrade_Safe] nonce: $fus_chain"
    echo "Fake Foundation Operation Safe (FoS) [$Fake_Foundation_Operation_Safe] nonce: $fos_chain"
    echo "Fake Security Council Safe (SC) [$Fake_Security_Council_Safe] nonce: $sc_chain"
    echo "Fake L1ProxyAdminOwner (L1PAO) [$Fake_Proxy_Admin_Owner_Safe] nonce: $l1pao_chain"

    # Check if any of these addresses have nonce overrides in the env file
    for nonce_entry in $safe_nonces; do
      local addr=$(echo "$nonce_entry" | cut -d'=' -f1 | cut -d'_' -f2)
      local value=$(echo "$nonce_entry" | cut -d'=' -f2 | tr -d '"')

      # Convert to uppercase for case-insensitive comparison
      local addr_upper=$(echo "$addr" | tr '[:lower:]' '[:upper:]')

      # Check each Sepolia safe address
      for safe_addr in "$Fake_Foundation_Upgrade_Safe" "$Fake_Foundation_Operation_Safe" "$Fake_Security_Council_Safe" "$Fake_Proxy_Admin_Owner_Safe"; do
        local safe_upper=$(echo "$safe_addr" | tr '[:lower:]' '[:upper:]')
        if [[ "$addr_upper" == "$safe_upper" ]]; then
          # Get safe name for display
          local safe_name=""
          if [[ "$safe_addr" == "$Fake_Foundation_Upgrade_Safe" ]]; then
            safe_name="Fake Foundation Upgrade Safe (FuS)"
          elif [[ "$safe_addr" == "$Fake_Foundation_Operation_Safe" ]]; then
            safe_name="Fake Foundation Operation Safe (FoS)"
          elif [[ "$safe_addr" == "$Fake_Security_Council_Safe" ]]; then
            safe_name="Fake Security Council Safe (SC)"
          elif [[ "$safe_addr" == "$Fake_Proxy_Admin_Owner_Safe" ]]; then
            safe_name="Fake L1ProxyAdminOwner (L1PAO)"
          fi

          # Get current chain nonce
          local chain_nonce=""
          if [[ "$safe_addr" == "$Fake_Foundation_Upgrade_Safe" ]]; then
            chain_nonce="$fus_chain"
          elif [[ "$safe_addr" == "$Fake_Foundation_Operation_Safe" ]]; then
            chain_nonce="$fos_chain"
          elif [[ "$safe_addr" == "$Fake_Security_Council_Safe" ]]; then
            chain_nonce="$sc_chain"
          elif [[ "$safe_addr" == "$Fake_Proxy_Admin_Owner_Safe" ]]; then
            chain_nonce="$l1pao_chain"
          fi

          echo -e "\033[0;33m$safe_name [$safe_addr] nonce: $chain_nonce (ENV: $value)\033[0m"
        fi
      done
    done
  else
    # Get current on-chain nonces for mainnet
    local fus_chain=$(cast call $Foundation_Upgrade_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    local fos_chain=$(cast call $Foundation_Operation_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    local sc_chain=$(cast call $Security_Council_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    local l1pao_chain=$(cast call $Proxy_Admin_Owner_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    local bl1pao_chain=$(cast call $Base_Proxy_Admin_Owner_safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    local bos_chain=$(cast call $Base_Owner_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    local u3_chain=$(cast call $Unichain_3of3_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    local uos_chain=$(cast call $Unichain_Owner_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)

    # Get the nonce address and identify them from the env file
    local safe_nonces=$(grep -E "^SAFE_NONCE_" "$env_file" || echo "")


    # Display mainnet nonces
    echo "Foundation Upgrade Safe (FuS) [$Foundation_Upgrade_Safe] nonce: $fus_chain"
    echo "Foundation Operation Safe (FoS) [$Foundation_Operation_Safe] nonce: $fos_chain"
    echo "Security Council Safe (SC) [$Security_Council_Safe] nonce: $sc_chain"
    echo "L1ProxyAdminOwner (L1PAO) [$Proxy_Admin_Owner_Safe] nonce: $l1pao_chain"
    echo "Base Proxy Admin Owner (BL1PAO) [$Base_Proxy_Admin_Owner_safe] nonce: $bl1pao_chain"
    echo "Base Owner (BOS) [$Base_Owner_Safe] nonce: $bos_chain"
    echo "Unichain 3of3 (U3) [$Unichain_3of3_Safe] nonce: $u3_chain"
    echo "Unichain Owner (UOS) [$Unichain_Owner_Safe] nonce: $uos_chain"

    # Check if any of these addresses have nonce overrides in the env file
    for nonce_entry in $safe_nonces; do
      local addr=$(echo "$nonce_entry" | cut -d'=' -f1 | cut -d'_' -f2)
      local value=$(echo "$nonce_entry" | cut -d'=' -f2 | tr -d '"')

      # Convert to uppercase for case-insensitive comparison
      local addr_upper=$(echo "$addr" | tr '[:lower:]' '[:upper:]')

      # Check each mainnet safe address
      for safe_addr in "$Foundation_Upgrade_Safe" "$Foundation_Operation_Safe" "$Security_Council_Safe" "$Proxy_Admin_Owner_Safe" "$Base_Proxy_Admin_Owner_safe" "$Base_Owner_Safe" "$Unichain_3of3_Safe" "$Unichain_Owner_Safe"; do
        local safe_upper=$(echo "$safe_addr" | tr '[:lower:]' '[:upper:]')
        if [[ "$addr_upper" == "$safe_upper" ]]; then
          # Get safe name for display
          local safe_name=""
          if [[ "$safe_addr" == "$Foundation_Upgrade_Safe" ]]; then
            safe_name="Foundation Upgrade Safe (FuS)"
          elif [[ "$safe_addr" == "$Foundation_Operation_Safe" ]]; then
            safe_name="Foundation Operation Safe (FoS)"
          elif [[ "$safe_addr" == "$Security_Council_Safe" ]]; then
            safe_name="Security Council Safe (SC)"
          elif [[ "$safe_addr" == "$Proxy_Admin_Owner_Safe" ]]; then
            safe_name="L1ProxyAdminOwner (L1PAO)"
          elif [[ "$safe_addr" == "$Base_Proxy_Admin_Owner_safe" ]]; then
            safe_name="Base Proxy Admin Owner (BL1PAO)"
          elif [[ "$safe_addr" == "$Base_Owner_Safe" ]]; then
            safe_name="Base Owner (BOS)"
          elif [[ "$safe_addr" == "$Unichain_3of3_Safe" ]]; then
            safe_name="Unichain 3of3 (U3)"
          elif [[ "$safe_addr" == "$Unichain_Owner_Safe" ]]; then
            safe_name="Unichain Owner (UOS)"
          fi

          # Get current chain nonce
          local chain_nonce=""
          if [[ "$safe_addr" == "$Foundation_Upgrade_Safe" ]]; then
            chain_nonce="$fus_chain"
          elif [[ "$safe_addr" == "$Foundation_Operation_Safe" ]]; then
            chain_nonce="$fos_chain"
          elif [[ "$safe_addr" == "$Security_Council_Safe" ]]; then
            chain_nonce="$sc_chain"
          elif [[ "$safe_addr" == "$Proxy_Admin_Owner_Safe" ]]; then
            chain_nonce="$l1pao_chain"
          elif [[ "$safe_addr" == "$Base_Proxy_Admin_Owner_safe" ]]; then
            chain_nonce="$bl1pao_chain"
          elif [[ "$safe_addr" == "$Base_Owner_Safe" ]]; then
            chain_nonce="$bos_chain"
          elif [[ "$safe_addr" == "$Unichain_3of3_Safe" ]]; then
            chain_nonce="$u3_chain"
          elif [[ "$safe_addr" == "$Unichain_Owner_Safe" ]]; then
            chain_nonce="$uos_chain"
          fi

          echo -e "\033[0;33m$safe_name [$safe_addr] nonce: $chain_nonce (ENV: $value)\033[0m"
        fi
      done
    done
  fi
}


# Displays the current nonce values for various safes before simulation
# $1: Message to display before showing nonce values
BeforeNonceDisplay(){
  echo -e "\n$1"

  if [[ "$IS_SEPOLIA" == "TRUE" ]]; then
    # Only get and display Sepolia safes
  # Only get and display Sepolia safes
    FUS_BEFORE=$(cast call $Fake_Foundation_Upgrade_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    FOS_BEFORE=$(cast call $Fake_Foundation_Operation_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    SC_BEFORE=$(cast call $Fake_Security_Council_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    L1PAO_BEFORE=$(cast call $Fake_Proxy_Admin_Owner_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    BOS_BEFORE=$(cast call $Fake_Base_Owner_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    BL1PAO_BEFORE=$(cast call $Fake_Base_Proxy_Admin_Owner_safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    NESTED_BEFORE=$(cast call $Fake_Base_Nested_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)


    echo "Fake Foundation Upgrade Safe (FuS) [$Fake_Foundation_Upgrade_Safe] nonce: "$FUS_BEFORE"."
    echo "Fake Foundation Operation Safe (FoS) [$Fake_Foundation_Operation_Safe] nonce: "$FOS_BEFORE"."
    echo "Fake Security Council Safe (SC) [$Fake_Security_Council_Safe] nonce: "$SC_BEFORE"."
    echo "Fake L1ProxyAdminOwner (L1PAO) [$Fake_Proxy_Admin_Owner_Safe] nonce: "$L1PAO_BEFORE"."
    echo "Fake Base Owner (BOS) [$Fake_Base_Owner_Safe] nonce: "$BOS_BEFORE"."
    echo "Fake Base Proxy Admin Owner (BL1PAO) [$Fake_Base_Proxy_Admin_Owner_safe] nonce: "$BL1PAO_BEFORE"."
    echo "Fake Base Nested Safe (Nested) [$Fake_Base_Nested_Safe] nonce: "$NESTED_BEFORE"."
  else
    # Get and display all mainnet safes
    FUS_BEFORE=$(cast call $Foundation_Upgrade_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    FOS_BEFORE=$(cast call $Foundation_Operation_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    SC_BEFORE=$(cast call $Security_Council_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    L1PAO_BEFORE=$(cast call $Proxy_Admin_Owner_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    BL1PAO_BEFORE=$(cast call $Base_Proxy_Admin_Owner_safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    BOS_BEFORE=$(cast call $Base_Owner_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    U3_BEFORE=$(cast call $Unichain_3of3_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)
    UOS_BEFORE=$(cast call $Unichain_Owner_Safe "nonce()(uint256)" --rpc-url $ANVIL_LOCALHOST_RPC)

    echo "Foundation Upgrade Safe (FuS) [$Foundation_Upgrade_Safe] nonce: "$FUS_BEFORE"."
    echo "Foundation Operation Safe (FoS) [$Foundation_Operation_Safe] nonce: "$FOS_BEFORE"."
    echo "Security Council Safe (SC) [$Security_Council_Safe] nonce: "$SC_BEFORE"."
    echo "L1ProxyAdminOwner (L1PAO) [$Proxy_Admin_Owner_Safe] nonce: "$L1PAO_BEFORE"."
    echo "Base Proxy Admin Owner (BL1PAO) [$Base_Proxy_Admin_Owner_safe] nonce: "$BL1PAO_BEFORE"."
    echo "Base Owner (BOS) [$Base_Owner_Safe] nonce: "$BOS_BEFORE"."
    echo "Unichain 3of3 (U3) [$Unichain_3of3_Safe] nonce: "$U3_BEFORE"."
    echo "Unichain Owner (UOS) [$Unichain_Owner_Safe] nonce: "$UOS_BEFORE"."
  fi
}



check_if_task_is_3_of_3() {
  local file_path="$1"
  Chain_Governor_Extract=$(grep "CHAIN_GOVERNOR_SAFE=" "$file_path" | awk -F '[ ]' '{print $1}') || true

  if [[ -n "$Chain_Governor_Extract" ]]; then
    Chain_Governor_Safe=$(echo $Chain_Governor_Extract | awk -F '[=]' '{print $2}')
    if [[ -z "$Chain_Governor_Safe" ]]; then
      log_error "The Chain Governor Safe is not set in the $file_path file."
      exit 99
    fi
    log_info "Nested Task with 3 safes detected. This is using the superchain-ops v1.0"
    IS_3_OF_3=1
  else
    log_info "Nested Task with 2 safes detected. This is using the superchain-ops v1.0"
    IS_3_OF_3=0
  fi
}
## Check if the nonce has the correct env format.
check_nonce_override() {
  local file_path="$1"
  if grep -q "SAFE_NONCE=" "$file_path"; then
    log_error "SAFE_NONCE= is found in the $file_path file, please make sure to use the SAFE_NONCE_XXXX format."
    exit 99
  elif grep -q "SAFE_NONCE_.*=\"\"" "$file_path"; then
    log_warning "SAFE_NONCE_XXXX is set to empty (\"\") in the $file_path file, the simulation is about to take the current nonce values."
  elif grep -q "SAFE_NONCE_.*=" "$file_path"; then
    return 0  # True, no "SAFE_NONCE_*=" is found
  else
    log_warning "SAFE_NONCE_XXXX is not **present** in the $file_path file, the simulation is about to take the current nonce values."
  fi
}
# Find unique task folder(s) for a given task ID
find_task_folder() {
  local task_id="$1"

  # Search in both directories
  matching_folders=$(find "$task_base_dir" "$root_dir/src/improvements/tasks/${network}" -name "${task_id}*" -type d)

  if [[ -z "$matching_folders" ]]; then
    error_exit "No folder found matching task ID '$task_id' in either tasks/${network} or src/improvements/tasks/${network}."
  fi

  matching_count=$(echo "$matching_folders" | wc -l)
  if [[ "$matching_count" -gt 1 ]]; then
    echo "Error: Multiple folders found matching task ID '$task_id':" >&2
    echo "$matching_folders" >&2
    exit 1
  fi

  echo "$matching_folders"
}

# --- Main Script ---
# ##############################################################
# Simulates a sequence of tasks for a given network by running them against an Anvil
# fork with state overrides disabled.
#
# Usage:
#   ./script/utils/sim-sequence.sh <network> <array-of-task-IDs>
#
# Example:
#   ./script/utils/sim-sequence.sh eth "021 022 base-003 ink-001"

# Validate input arguments
if [[ "$#" -lt 2 || "$#" -gt 3 ]]; then
  echo "Usage: $0 <network> \"<array-of-task-IDs>\" [block_number]" >&2
  exit 1
fi

network="$1"
task_ids="$2"
block_number="${3:-}" # Make block_number optional

# Check if task_ids is empty
if [[ -z "$task_ids" || "$task_ids" == '""' || "$task_ids" == "''" ]]; then
  log_warning "No task IDs provided. Please specify at least one task ID to simulate."
  log_info "Usage: $0 <network> \"<array-of-task-IDs>\" [block_number]"
  log_info "Example: $0 eth \"021 022 base-003 ink-001\""
  exit 0
fi

if [[ "$network" == "sep" ]]; then
  IS_SEPOLIA=TRUE
fi

log_info "Simulating tasks for network: $network"
log_info "The \"LOGFILE\" is located in:$LOGFILE"
log_info "The \"LOGFILE_ANVIL\" is located in: $LOGFILE_ANVIL"
# Validate block number if provided
if [[ -n "$block_number" ]]; then
    if ! [[ "$block_number" =~ ^[0-9]+$ ]]; then
        error_exit "Block number must be a valid number, got: $block_number"
    fi
fi

# Determine root directory.
base_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root_dir="$base_dir/../.."
task_base_dir="${root_dir}/tasks/${network}"
# Verify task_base_dir exists.
if [[ ! -d "$task_base_dir" ]]; then
  error_exit "Task base directory '$task_base_dir' does not exist."
fi

# Process task IDs.
declare -a task_folders=()
for task_id in $task_ids; do
  matching_folders=$(find_task_folder "$task_id")
  task_folders+=("$matching_folders")
done

# Set RPC URL based on network or use environment variable if set
if [[ -n "${RPC_URL:-}" ]]; then
  # Use the RPC_URL from environment if it's set
  log_info "Using RPC_URL from environment: $RPC_URL"
else
  # Fall back to default RPC URLs based on network
  if [[ "$network" == "sep" ]]; then
    RPC_URL=https://ethereum-sepolia-rpc.publicnode.com
  elif [[ "$network" == "eth" ]]; then
    RPC_URL=https://ethereum.publicnode.com
  fi
  log_info "Using default RPC_URL for $network: $RPC_URL"
fi

unset ETH_RPC_URL
log_info "Simulating the following tasks in order:"

echo "-------------------------------------------------------"
for task_folder in "${task_folders[@]}"; do
  echo "  $(realpath "$task_folder")"
done
echo "-------------------------------------------------------"
read -p "Are the tasks above are correct? Type 'yes' to proceed with simulation: " confirmation
if [[ "${confirmation}" != "yes" ]]; then
  log_info "Simulation aborted by user."
  exit 0
fi
# Create the anvil Fork
createFork
# Disable state overrides and execute tasks.
disable_state_overrides
export SIMULATE_WITHOUT_LEDGER=1

for task_folder in "${task_folders[@]}"; do
  execution=""
  echo -e "\n---- Simulating task \"$(basename "$task_folder")\"----"
  if [[ "${task_folder}" != *"src/improvements"* ]]; then
    echo Simulating legacy task: $(basename "$task_folder")
    # Check if the .env is correct with the SAFE_NONCE_XXXX or nothing but exclude the deprecated SAFE_NONCE=.
    check_nonce_override "${task_folder}/.env"
    # nonce_from_env=$(grep -E "^SAFE_NONCE._*" "${task_folder}/.env" | awk -F'[=_ ]' '{print "Address: " $3, "Number: " $4}') || true
    # log_info "Nonce from .env file:\n$nonce_from_env"

    DisplaySafeBeforeNonces "(🟧) Before Simulation Nonce Values (🟧)" "${task_folder}/.env"
  fi

  pushd "$task_folder" >/dev/null || error_exit "Failed to navigate to '$task_folder'."
  # add the RPC_URL to the .env file
  # echo "ETH_RPC_URL=ANVIL_LOCALHOST_RPC" >> "${PWD}/.env" # Replace with the anvil fork URL
  #DisplayNonceFromEnv "(🟧) Before Simulation Nonce Values (🟧)" "${task_folder}/.env"
  if [[ -f "${task_folder}/NestedSignFromJson.s.sol" ]]; then
    check_if_task_is_3_of_3 "${task_folder}/.env"
    if [ $IS_3_OF_3 -eq 1 ]; then
        approvalchaingovernor=$(just \
        --dotenv-path "${PWD}/.env" \
        --justfile "${root_dir}/nested.just" \
        approvehash_in_anvil chain-governor)
      if [[ $approvalchaingovernor == *"GS025"* ]]; then
        log_error "Execution contains "GS025" meaning the task $task_folder failed during the chain-governor approval, please check the nonces below:"
        log_nonce_error
      exit 99
    fi

    fi
    # Handle the 2-of-2 case anyway.
    approvalhashcouncil=$(just \
      --dotenv-path "${PWD}/.env" \
      --justfile "${root_dir}/nested.just" \
      approvehash_in_anvil council)

    approvalhashfoundation=$(just \
      --dotenv-path "${PWD}/.env" \
      --justfile "${root_dir}/nested.just" \
      approvehash_in_anvil foundation)

    if [[ $approvalhashcouncil == *"GS025"* ]]; then
      log_error "Execution contains "GS025" meaning the task $task_folder failed during the council approval, please check the nonces below:"
      log_nonce_error
      exit 99
    fi
    if [[ $approvalhashfoundation == *"GS025"* ]]; then
     log_error "Execution contains "GS025" meaning the task $task_folder failed during the foundation approval, please check the nonces below:"
     log_nonce_error
     exit 99
    fi
    execution=$(just\
       --dotenv-path "${PWD}/.env" \
       --justfile "${root_dir}/nested.just" \
       execute_in_anvil 0)

  elif [[ -f "${task_folder}/SignFromJson.s.sol" ]]; then
    log_info "Task type detected: single. This is using the superchain-ops v1.0"
    simulate=$(just --dotenv-path "${PWD}/.env" --justfile "${root_dir}/single.just" approvehash_in_anvil 0)
    execution=$(just --dotenv-path "${PWD}/.env" --justfile "${root_dir}/single.just" execute_in_anvil 0)
    if [[ $execution == *"GS025"* ]]; then
     log_error "Execution contains GS025 meaning the task $task_folder failed."
     exit 99
    fi

  elif [[ -f "${task_folder}/config.toml" ]]; then
    echo Simulating superchain-ops v2.0 task: $(basename "$task_folder")

    # TODO:check if necessary in the future check_nonce_override "${task_folder}/.env"
    # nonce_from_env=$(grep -E "^SAFE_NONCE._*" "${task_folder}/.env" | awk -F'[=_ ]' '{print "Address: " $3, "Number: " $4}') || true
    # log_info "Nonce from .env file:\n$nonce_from_env"
    # pushd "$task_folder" >/dev/null || error_exit "Failed to navigate to '$task_folder'."

    #DisplaySafeBeforev20 "(🟧) Before Simulation Nonce Values (🟧)" "${task_folder}/config.toml"
    DisplaySafeBeforeNoncesv20 "(🟧) Before Simulation Nonce Values (🟧)" "${task_folder}/config.toml"
    # check if the task is nested or single:
    output=$(forge script TaskManager --sig "isNestedTask" "${task_folder}/config.toml" --rpc-url http://localhost:8545)
    read bool_value parent_multisig <<< $(echo "$output" | awk '
        /0: bool/ {bool=$3}
        /parentMultisig:/ {multisig=$3}
        END {print bool, multisig}
    ')


    cd "${task_folder}" # change the directory to the task folder to run the justfile from the task folder
    if [[ $bool_value == "true" ]]; then
    echo "parent_multisig: $parent_multisig"
    # get the child from the parent multisig
    child_safes=$(cast call $parent_multisig "getOwners()(address[])" --rpc-url $ANVIL_LOCALHOST_RPC)
    value=$(echo "$child_safes" | sed 's/[][]//g')
    IFS=',' read -a child_safes_array <<< "$value"
    log_info "This is a nested task. This is using the superchain-ops v2.0"
    echo "child_safes_array: ${child_safes_array[@]}"
    SignatureCount=0 # count the number of signatures approved for the task can be useful to debug if one of the safes didn't signed. 
    for child_safe in ${child_safes_array[@]}; do
      # get the name of the child safe from the address
      addresses_file="${root_dir}/src/improvements/addresses.toml"
      child_safe_name=$(yq ".${network} | to_entries | .[] | select(.value == \"$child_safe\") | .key" $addresses_file)

      # We iterate over the [addresses] section of the config.toml file and for each childsafe or foundation or council we execute the command.
      echo "child_safe_name: $child_safe_name"
        case $child_safe_name in
          "ChainGovernorSafe")
            set +e
            approvalhash_result=$(just \
              --justfile "${root_dir}/src/improvements/nested.just" \
              sign_and_approve_in_anvil chain-governor $parent_multisig 2>&1)
            set -e
            if [[ $approvalhash_result == *"Signature is incorrect"* || $approvalhash_result == *"revert"* ]]; then
              echo "approvalhash_result: $approvalhash_result"
              log_error "Nonce is invalid for $task_folder for chain-governor approval, please check the nonces below:"
              log_nonce_error
              exit 99
            fi
            SignatureCount=$((SignatureCount + 1))
          ;;
          "BaseOperationsSafe")
            set +e
            approvalhash_result=$(just \
              --justfile "${root_dir}/src/improvements/nested.just" \
              sign_and_approve_in_anvil base-operations $parent_multisig 2>&1)
            set -e
            if [[ $approvalhash_result == *"Signature is incorrect"* || $approvalhash_result == *"revert"* ]]; then
              echo "approvalhash_result: $approvalhash_result"
              log_error "Nonce is invalid for $task_folder for base-operations approval, please check the nonces below:"
              log_nonce_error
              exit 99
            fi
            SignatureCount=$((SignatureCount + 1))
          ;;
          "BaseNestedSafe")
            set +e
            approvalhash_result=$(just \
              --justfile "${root_dir}/src/improvements/nested.just" \
              sign_and_approve_in_anvil BaseNestedSafe $parent_multisig 2>&1)
            set -e
            if [[ $approvalhash_result == *"Signature is incorrect"* || $approvalhash_result == *"revert"* ]]; then
              echo "approvalhash_result: $approvalhash_result"
              log_error "Nonce is invalid for $task_folder for BaseNestedSafe approval, please check the nonces below:"
              log_nonce_error
              exit 99
            fi
            SignatureCount=$((SignatureCount + 1))
          ;;
          "FoundationUpgradeSafe")
            set +e
            approvalhash_result=$(just \
              --justfile "${root_dir}/src/improvements/nested.just" \
              sign_and_approve_in_anvil foundation $parent_multisig 2>&1)
            set -e
            if [[ $approvalhash_result == *"Signature is incorrect"* || $approvalhash_result == *"revert"* ]]; then
            echo "approvalhash_result: $approvalhash_result"
             log_error "Nonce is invalid for $task_folder for foundation approval, please check the nonces below:"
              log_nonce_error
              exit 99
            fi
            SignatureCount=$((SignatureCount + 1))
          ;;
          "SecurityCouncil")
            set +e
             approvalhash_result=$(just \
               --justfile "${root_dir}/src/improvements/nested.just" \
               sign_and_approve_in_anvil council $parent_multisig 2>&1)
            set -e
            if [[ $approvalhash_result == *"Signature is incorrect"* || $approvalhash_result == *"revert"* ]]; then
             echo "approvalhash_result: $approvalhash_result"
              log_error "Nonce is invalid for $task_folder for council approval, please check the nonces below:"
              log_nonce_error
              exit 99
            fi
            SignatureCount=$((SignatureCount + 1))
            ;;
          "FoundationOperationsSafe")
            set +e
            approvalhash_result=$(just \
              --justfile "${root_dir}/src/improvements/nested.just" \
              sign_and_approve_in_anvil foundation-operations $parent_multisig 2>&1)
            set -e
            if [[ $approvalhash_result == *"Signature is incorrect"* || $approvalhash_result == *"revert"* ]]; then
             echo "approvalhash_result: $approvalhash_result"
             log_error "Nonce is invalid for $task_folder for foundation-operations approval, please check the nonces below:"
              log_nonce_error
              exit 99
            fi
            SignatureCount=$((SignatureCount + 1))
        esac
      done
      if [[ $SignatureCount -gt 0 ]]; then # if the signature count is greater than 0, then we can execute the task
      execution=$(just --justfile "${root_dir}/src/improvements/nested.just" execute_in_anvil &>2)
      else
        log_warning "The task $task_folder has not been approved by all the safes and has been skipped, this can be in case of safes that we don't control or new scheme architcture this require the engineer to manually verify here."
      fi
      else
        log_info "This is a single task. This is using the superchain-ops v2.0"
        set +e
        approval=$(just \
          --justfile "${root_dir}/src/improvements/single.just" \
          sign_and_execute_in_anvil $parent_multisig 2>&1)
        set -e

        if [[ $approval == *"not enough signatures"* ]]; then
          echo "approval: $approval" # display the approval error in the CI to debug the issues.
          log_error "Nonce is invalid for $task_folder for council approval, please check the nonces below:"
          log_nonce_error
          exit 99
        fi
      fi
    fi
  set -e
  reset_nonce
  sleep 0.2
  NonceDisplayModified "(🟩) After Simulation Nonce Values (🟩)"
  echo -e "\n---- End of Simulation for task \"$(basename "$task_folder")\" ----"
  popd >/dev/null || error_exit "Failed to return to previous directory."
done

log_info "✅ All tasks has been simulated with success!! ✅"