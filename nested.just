set dotenv-load

export rpcUrl := env_var_or_default('ETH_RPC_URL', 'https://ethereum.publicnode.com')
export signatures := env_var_or_default('SIGNATURES', '')
export bundleName := env_var_or_default('BUNDLE_NAME', 'input')
export taskPath := invocation_directory()

# Accounts
export councilSafe := "0xc2819DC788505Aac350142A7A707BF9D03E3Bd03"
export councilOwner0 := "0x07dC0893cAfbF810e3E72505041f2865726Fd073"

export foundationSafe := "0x847B5c174615B1B7fDF770882256e2D3E95b9D92"
export foundationOwner0 := "0x42d27eEA1AD6e22Af6284F609847CB3Cd56B9c64"

export ownerSafe := env_var('OWNER_SAFE')

# Prints a tenderly simulation URL for the transaction
simulate whichSafe hdPath='0':
  #!/usr/bin/env bash
  bundlePath=${taskPath}/${bundleName}.json
  echo "getting signer address..."
  if [ t"{{whichSafe}}" == t"foundation" ]; then
    safe="${foundationSafe}"
    signer="${foundationOwner0}"
    echo "signer: ${signer}"
    echo "safe: ${safe}"
  fi
  if [ t"{{whichSafe}}" == t"council" ]; then
    safe="${councilSafe}"
    signer="${councilOwner0}"
    echo "signer: ${signer}"
    echo "safe: ${safe}"
  fi
  echo "Simulating call to the {{whichSafe}} safe at ${safe}"
  if [ t"$SIMULATE_WITHOUT_LEDGER" != t1 ]; then
    signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
    echo "Simulating with ledger account: ${signer}"
    else
      echo "Simulating without ledger using the first owner account: ${signer}"
  fi
  echo ""
  forge script NestedSignFromJson \
    --rpc-url ${rpcUrl} \
    --sender ${signer} \
    --sig "signJson(string,address)" \
    ${bundlePath} \
    "${safe}"

# Signs the transaction with the nested safe
sign whichSafe hdPath='0':
  #!/usr/bin/env bash
  bundlePath=${taskPath}/${bundleName}.json
  if [ t"{{whichSafe}}" == t"foundation" ]; then
    safe="${foundationSafe}"
    echo "Using foundation safe at ${safe}"
  fi
  if [ t"{{whichSafe}}" == t"council" ]; then
    safe="${councilSafe}"
    echo "Using council safe at ${safe}"
  fi
  echo "getting signer address..."
  signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
  echo "Signing with: ${signer}"
  echo ""
  $(git rev-parse --show-toplevel)/bin/eip712sign --ledger --hd-paths "m/44'/60'/{{hdPath}}'/0/0" -- \
  forge script NestedSignFromJson \
    --rpc-url ${rpcUrl} \
    --sig "signJson(string,address)" \
    ${bundlePath} \
    "${safe}"

# Used to ensure that the signatures are valid without broadcasting them to the network
# Before running this, open a new terminal and run `anvil --fork-url $ETH_RPC_URL`
# After this script runs, you can use cast commands to manually validate that the safe nonce has been incremented.
validate-approval whichSafe:
  #!/usr/bin/env bash
  bundlePath=${taskPath}/${bundleName}.json
    if [ t"{{whichSafe}}" == t"foundation" ]; then
    safe="${foundationSafe}"
    echo "Using foundation safe at ${safe}"
  fi
  if [ t"{{whichSafe}}" == t"council" ]; then
    safe="${councilSafe}"
    echo "Using council safe at ${safe}"
  fi
  forge script --rpc-url http://127.0.0.1:8545 SignFromJson \
    --sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
    --sig "approveJson(string,address,bytes)" \
    ${bundlePath} \
    ${safe} \
    ${signatures}

# Calls the approveHash function on a nested safe to approve the transaction
approve whichSafe hdPath='0':
  #!/usr/bin/env bash
  bundlePath=${taskPath}/${bundleName}.json
  if [ t"{{whichSafe}}" == t"foundation" ]; then
    safe="${foundationSafe}"
    echo "Using foundation safe at ${safe}"
  fi
  if [ t"{{whichSafe}}" == t"council" ]; then
    safe="${councilSafe}"
    echo "Using council safe at ${safe}"
  fi
  sender=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
  forge script NestedSignFromJson \
    --rpc-url ${rpcUrl} \
    --ledger --hd-paths "m/44'/60'/{{hdPath}}'/0/0" \
    --broadcast \
    --sender ${sender} \
    --sig "approveJson(string,address,bytes)" \
    ${bundlePath} \
    ${safe} \
    ${signatures}

# Calls directly to the owner safe (not the nested safes) to execute the transaction
execute hdPath='0':
  #!/usr/bin/env bash
  bundlePath=${taskPath}/${bundleName}.json
  sender=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
  forge script NestedSignFromJson \
    --rpc-url ${rpcUrl} \
    --ledger --hd-paths "m/44'/60'/{{hdPath}}'/0/0" \
    --broadcast \
    --sender ${sender} \
    --sig "runJson(string)" \
    ${bundlePath}
