set dotenv-load

export rpcUrl := env_var('ETH_RPC_URL')
export signatures := env_var_or_default('SIGNATURES', '')
export bundleName := env_var_or_default('BUNDLE_NAME', 'input')
export taskPath := invocation_directory()

# Accounts
export OWNER_SAFE := env_var_or_default('FOUNDATION_SAFE', '0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A')
export foundationOwner0 := "0x42d27eEA1AD6e22Af6284F609847CB3Cd56B9c64"
export randomPersonEoa := "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"

# Prints a tenderly simulation URL for the transaction
simulate hdPath='0':
  #!/usr/bin/env bash
  bundlePath=${taskPath}/${bundleName}.json
  echo "getting signer address..."
  if [ t"$SIMULATE_WITHOUT_LEDGER" == t1 ]
  then
    signer=${foundationOwner0}
  else
    signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
  fi
  echo "Simulating with: ${signer}"
  echo ""
  forge build
  forge script SignFromJson \
    --rpc-url ${rpcUrl} \
    --sig "signJson(string)" ${bundlePath} \
    --sender ${signer}

# Signs the transaction with the nested safe
sign hdPath='0':
  #!/usr/bin/env bash
  bundlePath=${taskPath}/${bundleName}.json
  echo "getting signer address..."
  signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
  echo "Signing with: ${signer}"
  echo ""
  forge build
  $(git rev-parse --show-toplevel)/bin/eip712sign --ledger --hd-paths "m/44'/60'/{{hdPath}}'/0/0" -- \
  forge script SignFromJson \
    --rpc-url ${rpcUrl} \
    --sig "signJson(string)" \
    ${bundlePath}

# Used to ensure that the signatures are valid without broadcasting them to the network
# Before running this, open a new terminal and run `anvil --fork-url $ETH_RPC_URL`
# After this script runs, you can use cast commands to manually validate the state diff.
validate:
  #!/usr/bin/env bash
  bundlePath=${taskPath}/${bundleName}.json
  forge build
  forge script --rpc-url http://127.0.0.1:8545 SignFromJson \
    --sig "runJson(string,bytes)" ${bundlePath} ${SIGNATURES} \
    --sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Submits signatures and executes the transaction
execute hdPath='0':
  #!/usr/bin/env bash
  bundlePath=${taskPath}/${bundleName}.json
  sender=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
  forge build
  forge script --rpc-url ${ETH_RPC_URL} SignFromJson \
    --sig "runJson(string,bytes)" ${bundlePath} ${SIGNATURES} \
    --ledger --hd-paths "m/44'/60'/{{hdPath}}'/0/0" --broadcast \
    --sender ${sender}
