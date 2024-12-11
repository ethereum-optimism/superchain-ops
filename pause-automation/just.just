set dotenv-load
export rpcUrl := env_var('ETH_RPC_URL')

# By default we choose sepolia network (if there is a mistake we not pausing mainnet). 
pause network='sepolia':
  #!/usr/bin/env bash
  if [[ "${network}" == "sepolia" ]]; then
    VAULTNAME="Pre-signed Pause OP Sepolia"
  elif [[ "${network}" == "mainnet" ]]; then
    VAULTNAME="Pre-signed Pause OP Mainnet"
  else
    echo "ERROR: Unable to determine vault from network: ${network}, Please specify a valid network for the the vault name Ex: sepolia, mainnet"
    exit 1
  fi
  # Ask for user confirmation TODO: Add the timestamp to all the messages (create a function for that in the future).
  echo "===================================================================================="
  echo "| ⚠️ PLEASE READ CAREFULLY HERE: Are you SURE you want to PAUSE the Superchain on ${network}? ⚠️ |"
  echo "|       To confirm, type 'yes' and press Enter. To cancel, press Ctrl+C.           |" 
  echo "===================================================================================="
  echo -ne "(yes/no):"
  read -r user_input
  echo "You are about to Pause \"${network}\" network."
  # Check if there is one-password cli installed on the system. TODO: check that need to improve probably in the future.
  if which op >/dev/null 2>&1; then
     echo "op (one-password cli) is installed. We can proceed..."
  else
     echo "op is not installed, please install op (one-password cli) using homebrew. Using brew install --cask 1password-cli"
     exit
  fi

  # Check if the user input is yes or no (TODO: but need to check that no other input can trigger the workflow!)
  if [[ "$user_input" == "yes" ]]; then
      echo "Request sent successfully."
  else
      echo "Request cancelled."
  fi
  op item get "DeputyPauseModulePrivateKey" --vault Sepolia --format json | jq ".fields.[0].value"
  # TODO: cast send the tx on the network.
