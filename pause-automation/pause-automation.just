set dotenv-load

pause:
  #!/usr/bin/env bash
  NETWORK='''🧪sepolia\n🔴mainnet\n🛠️localhost(Debug Test)'''

  NETWORK_SELECTED=$(printf $NETWORK | fzf --prompt "Select the network to pause the Superchain using arrows keys:⬆️⬇️")
  SLASH="/"
  if [[ "$NETWORK_SELECTED" == "sepolia" ]]; then
    echo "You selected the Sepolia network.✅"
    VAULTNAME="Sepolia"
    RPC_URL="https://ethereum-sepolia.publicnode.com" # TODO: Not using the ETH_RPC_URL to avoid confusion an make sure every network is correctly documented.
    RPC_URL="http://localhost:8545"
  elif [[ "$NETWORK_SELECTED" == "mainnet" ]]; then
    echo "You selected the Ethereum Mainnet network.✅"
    VAULTNAME="Mainnet"
    EXPLORER="https://etherscan.io/"
    RPC_URL="https://ethereum.publicnode.com"
  elif [[ "$NETWORK_SELECTED" == "localhost" ]]; then
    echo "You selected the *localhost* network that is a fork of Sepolia ✅"
    echo "Please make sure the node is running with the fork of the Sepolia on port 8545 -> (example: 'anvil -f https://ethereum-sepolia.publicnode.com')" 
    VAULTNAME="Sepolia"
    EXPLORER="https://sepolia.etherscan.io/"
    RPC_URL="http://localhost:8545"
  else
    echo "ERROR: Unable to determine vault from network: $NETWORK_SELECTED, Please specify a valid network for the the vault name Ex: sepolia, mainnet"
    exit 1
  fi
  # Ask for user confirmation TODO: Add the timestamp to all the messages (create a function for that in the future).
  echo "==================================================================================================="
  echo "| ⚠️ PLEASE READ CAREFULLY HERE: Are you SURE you want to PAUSE the Superchain on $NETWORK_SELECTED? ⚠️     |"
  echo "|       To confirm, type 'yes' and press Enter. To cancel, press Ctrl+C.                          |" 
  echo "==================================================================================================="
  echo -ne "(yes/no):"
  read -r user_input
  if [[ "$user_input" == "yes" ]]; then
      echo "yes selected, proceeding with the request..."
  else
      echo "Request cancelled."
      exit 1
  fi
  # Check if there is one-password cli installed on the system. TODO: check that need to improve probably in the future.
  if which op >/dev/null 2>&1; then
     echo "op (one-password cli) is installed. We can proceed..."
  else
     echo "op is not installed, please install op (one-password cli) using homebrew. Using brew install --cask 1password-cli"
     exit 1
  fi

  # Check if the user input is yes or no (TODO: but need to check that no other input can trigger the workflow!)
  item=$(op item get "DeputyPauseModulePrivateKey" --vault $VAULTNAME --format json | jq -r '"\(.fields.[1].value), \(.fields.[0].value)"') # Get the privatekey + pubkey into a variable called `item`.
  read address privatekey <<< $(echo "$item" | awk -F ',' '{print $1, $2}') # Get the address and private key from the JSON created by `jq`. 
  if [[ -z "$address" ]] || [[ -z "$privatekey" ]]; then
    echo "ERROR: Unable to get the address or private key from the vault. Please check the vault and ensure the item is in the vault: `$VAULTNAME` and try again."
    exit 1
  fi

  echo "🌏The address that will initiate the onchain call: $EXPLORER""address/$address"
  echo "⚖️The balance of the address: $address is: $(cast balance -e $address --rpc-url $RPC_URL) ETH."
  export PRIVATE_KEY=$privatekey
  forge script --tc SignPauseMessage script/SignPauseMessage.s.sol --sig "signAndBrodcast(string)" $NETWORK_SELECTED $NETWORK --rpc-url $RPC_URL -vvvvv --broadcast
  # cat /tmp/pause.log | sed -n 's/.*Hash: \(\0x[a-fA-F0-9]\{64\}\).*/\1/p'
  # echo "The Superchain has been paused on $NETWORK_SELECTED.🔒"
  # echo "Execution on of the signature onchain, using the cast send --rpc-url $RPC_URL --to $address with the signature from any address this is permissionless 🔥"
  # cast send $DEPUTYPAUSEMODULE "pause(bytes32, bytes32)" --rpc-url $RPC_URL  



  # 1. With eip712 we can sign the message with the private key and send the tx to the network.

  # 2. Broadcast the signature to the network to the `DeputyPauseModule` contract.
  




  # TODO: cast send the tx on the network.

 





