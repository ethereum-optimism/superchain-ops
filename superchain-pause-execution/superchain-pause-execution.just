set dotenv-load
set positional-arguments

pause *args='':
  #!/usr/bin/env bash
  dangerous_flag="false"
  network_arg=""

  # Parse arguments
  for arg in "$@"; do
    case "$arg" in
      --dangerous)
        dangerous_flag="true"
        echo "⚠️ Dangerous mode enabled - all networks will be visible"
        ;;
      --network=*)
        network_arg="${arg#*=}"
        ;;
      *)
        echo "ERROR: Unknown argument: $arg"
        echo "Usage: just pause --network=<network> [--dangerous]"
        exit 1
        ;;
    esac
  done

  # Must have network flag
  if [ -z "$network_arg" ]; then
    echo "ERROR: --network flag is required. Please specify a network (e.g. --network=sepolia)"
    exit 1
  fi

  # Must provide a private key with the PAUSE_EXECUTOR_PRIVATE_KEY environment variable
  if [ -z "$PAUSE_EXECUTOR_PRIVATE_KEY" ]; then
    echo "ERROR: PAUSE_EXECUTOR_PRIVATE_KEY environment variable is required"
    exit 1
  fi

  # Check if op (1password CLI) is installed
  if ! command -v op &> /dev/null; then
    echo "ERROR: 1Password CLI (op) is not installed"
    echo "Please install it!"
    exit 1
  fi

  NETWORK_SELECTED="$network_arg"
  echo $NETWORK_SELECTED
  if [[ "$NETWORK_SELECTED" =~ "sepolia" ]]; then
    echo "🚨 You selected the ETHEREUM SEPOLIA network 🚨"
    echo "🚨       This is a PRODUCTION network        🚨"
    VAULTNAME="sepolia [shared]"
    EXPLORER="https://sepolia.etherscan.io/"
    RPC_URL="https://ethereum-sepolia.publicnode.com"
    NETWORK_SELECTED="sepolia"
    DEPUTY_PAUSE_MODULE_ADDRESS="0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B"
  elif [[ "$NETWORK_SELECTED" =~ "mainnet" ]]; then
    echo "🚨 You selected the ETHEREUM MAINNET network 🚨"
    echo "🚨       This is a PRODUCTION network        🚨"
    VAULTNAME="mainnet [shared]"
    EXPLORER="https://etherscan.io/"
    RPC_URL="https://ethereum.publicnode.com"
    NETWORK_SELECTED="mainnet"
    DEPUTY_PAUSE_MODULE_ADDRESS="0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B"
  elif [[ "$NETWORK_SELECTED" =~ "simulate" ]]; then
    echo "⚠️ You selected the SIMULATE network ⚠️"
    echo "⚠️  This DOES NOT trigger the pause  ⚠️"
    VAULTNAME="sepolia [shared]"
    EXPLORER="https://sepolia.etherscan.io/"
    RPC_URL="https://ethereum-sepolia.publicnode.com"
    NETWORK_SELECTED="simulate"
    DEPUTY_PAUSE_MODULE_ADDRESS="0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B"
  else
    echo "ERROR: Unable to determine vault from network:\"$NETWORK_SELECTED\", Please specify a valid network (Ex: sepolia, mainnet, simulate)."
    exit 1
  fi

  # Ask for user confirmation
  echo "==================================================================================================="
  echo "| ⚠️ PLEASE READ CAREFULLY HERE: Are you SURE you want to PAUSE the Superchain on $NETWORK_SELECTED? ⚠️     |"
  echo "|       To confirm, type 'yes' and press Enter. To cancel, press Ctrl+C.                          |" 
  echo "==================================================================================================="
  echo -ne "(yes/no):"
  read -r user_input
  if [[ "$user_input" == "yes" ]]; then
      echo "yes selected, proceeding with the request..."
  else
      echo "request cancelled"
      exit 1
  fi

  # Grab the executor address from the given private key
  executor_address=$(cast wallet address --private-key $PAUSE_EXECUTOR_PRIVATE_KEY)

  # Extract Pause Deputy private key and address from vault
  item=$(op item get "DeputyPauseModulePrivateKey" --vault "$VAULTNAME" --format json | jq -r '"\(.fields.[1].value), \(.fields.[0].value)"') 
  read address pause_deputy_privatekey <<< $(echo "$item" | awk -F ',' '{print $1, $2}') 
  if [[ -z "$address" ]] || [[ -z "$pause_deputy_privatekey" ]]; then
    echo "ERROR: Unable to get the address or private key from the vault. Please check the vault and ensure the item is in the vault: $VAULTNAME and try again."
    exit 1
  fi

  echo "🌏 Address that will execute the onchain call: $EXPLORER""address/$executor_address"
  echo "🏦 Balance of the executing address: $(cast balance -e $executor_address --rpc-url $RPC_URL) ETH"

  # Generate JSON file with the EIP712 structured data to sign
  temp_json_file=$(mktemp)
  nonce=$(date +%s) # Using timestamp as nonce
  nonce=0x$(printf '%064x' $nonce)
  cat > "$temp_json_file" << EOF
  {
    "types": {
      "EIP712Domain": [
        { "name": "name", "type": "string" },
        { "name": "version", "type": "string" },
        { "name": "chainId", "type": "uint256" },
        { "name": "verifyingContract", "type": "address" }
      ],
      "PauseMessage": [
        { "name": "nonce", "type": "bytes32" }
      ]
    },
    "primaryType": "PauseMessage",
    "domain": {
      "name": "DeputyPauseModule",
      "version": "1",
      "chainId": $(cast chain-id --rpc-url $RPC_URL),
      "verifyingContract": "$DEPUTY_PAUSE_MODULE_ADDRESS"
    },
    "message": {
      "nonce": "$nonce"
    }
  }
  EOF

  echo "📝 Generated EIP712 structured data at: $temp_json_file"
  signature=$(cast wallet sign --data --from-file $temp_json_file --private-key $pause_deputy_privatekey)
  echo "📝 Nonce: $nonce"
  echo "📝 Signature: $signature"

  # Broadcast the signature to the network
  cast send $DEPUTY_PAUSE_MODULE_ADDRESS "pause(bytes32,bytes)" $nonce $signature --rpc-url $RPC_URL

auth *args='':
  #!/usr/bin/env bash
  network_arg=""
  creator_arg=""
  module_arg=""

  # Parse arguments
  for arg in "$@"; do
    case "$arg" in
      --network=*)
        network_arg="${arg#*=}"
        ;;
      --creator=*)
        creator_arg="${arg#*=}"
        ;;
      --module=*)
        module_arg="${arg#*=}"
        ;;
      *)
        echo "ERROR: Unknown argument: $arg"
        echo "Usage: just auth --network=<network> [--creator=<address>] [--module=<address>]"
        exit 1
        ;;
    esac
  done

  # Must have network flag
  if [ -z "$network_arg" ]; then
    echo "ERROR: --network flag is required. Please specify a network (e.g. --network=sepolia)"
    exit 1
  fi

  NETWORK_SELECTED="$network_arg"
  if [[ "$NETWORK_SELECTED" =~ "sepolia" ]]; then
    echo "🚨 You selected the ETHEREUM SEPOLIA network 🚨"
    echo "🚨       This is a PRODUCTION network        🚨"
    VAULTNAME="sepolia [shared]"
    EXPLORER="https://sepolia.etherscan.io/"
    RPC_URL="https://ethereum-sepolia.publicnode.com"
    NETWORK_SELECTED="sepolia"
  elif [[ "$NETWORK_SELECTED" =~ "mainnet" ]]; then
    echo "🚨 You selected the ETHEREUM MAINNET network 🚨"
    echo "🚨       This is a PRODUCTION network        🚨"
    VAULTNAME="mainnet [shared]"
    EXPLORER="https://etherscan.io/"
    RPC_URL="https://ethereum.publicnode.com"
    NETWORK_SELECTED="mainnet"
  elif [[ "$NETWORK_SELECTED" =~ "simulate" ]]; then
    echo "⚠️ You selected the SIMULATE network ⚠️"
    echo "⚠️  This is a SIMULATION only  ⚠️"
    VAULTNAME="sepolia [shared]"
    EXPLORER="https://sepolia.etherscan.io/"
    RPC_URL="https://ethereum-sepolia.publicnode.com"
    NETWORK_SELECTED="simulate"
  else
    echo "ERROR: Unable to determine vault from network:\"$NETWORK_SELECTED\", Please specify a valid network (Ex: sepolia, mainnet, simulate)."
    exit 1
  fi

  # Process optional arguments
  if [ -n "$creator_arg" ]; then
    echo "Creator address: $creator_arg"
  fi

  if [ -n "$module_arg" ]; then
    echo "Module address: $module_arg"
  fi

  # Add your authentication logic here
  echo "Authentication process for network: $NETWORK_SELECTED"
  
