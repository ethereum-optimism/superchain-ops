set dotenv-load

export rpcUrl := env_var_or_default('ETH_RPC_URL', 'https://ethereum.publicnode.com')
export signatures := env_var_or_default('SIGNATURES', '')
export bundleName := env_var_or_default('BUNDLE_NAME', 'input')
export taskPath := invocation_directory()

# Accounts
export councilSafe := env_var("COUNCIL_SAFE")
export foundationSafe := env_var("FOUNDATION_SAFE")
export ownerSafe := env_var('OWNER_SAFE')
export randomPersonEoa := "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"

simulate whichSafe hdPath='0':
  #!/usr/bin/env bash
  bundlePath=${taskPath}/${bundleName}.json
  script=NestedSignFromJson
  if [ -f "${taskPath}/NestedSignFromJson.s.sol" ]; then
    script="${taskPath}/NestedSignFromJson.s.sol"
    echo "Running script with assertions"
  fi
  echo "Using script ${script}"
  echo "getting signer address for {{whichSafe}}..."

  if [ "{{whichSafe}}" == "foundation" ]; then
    safe="{{foundationSafe}}"
  fi
  if [ "{{whichSafe}}" == "council" ]; then
    safe="{{councilSafe}}"
  fi
  signer=$(cast call ${safe} "getOwners()(address[])" -r ${rpcUrl} | grep -oE '0x[a-fA-F0-9]{40}' | head -n1)

  echo "signer: $signer"
  echo "safe: $safe"
  echo "Simulating call to {{whichSafe}} at ${safe}"
  if [ -z "$SIMULATE_WITHOUT_LEDGER" ]; then
    signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
    echo "Simulating with ledger account: ${signer}"
  else
      echo "Simulating without ledger using the first owner account: ${signer}"
  fi
  echo ""

  forge build
  forge script ${script} \
    --rpc-url ${rpcUrl} \
    --sender ${signer} \
    --sig "signJson(string,address)" \
    ${bundlePath} \
    "${safe}"

sign whichSafe hdPath='0':
  #!/usr/bin/env bash
  bundlePath=${taskPath}/${bundleName}.json
  script=NestedSignFromJson
  if [ -f "${taskPath}/NestedSignFromJson.s.sol" ]; then
    script="${taskPath}/NestedSignFromJson.s.sol"
    echo "Running script with assertions"
  fi
  echo "Using script ${script}"
  if [ "{{whichSafe}}" == "foundation" ]; then
    safe="{{foundationSafe}}"
    echo "Using foundation safe at ${safe}"
  fi
  if [ "{{whichSafe}}" == "council" ]; then
    safe="{{councilSafe}}"
    echo "Using council safe at ${safe}"
  fi
  echo "getting signer address..."
  signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
  echo "Signing with: ${signer}"
  echo ""

  forge build
  $(git rev-parse --show-toplevel)/bin/eip712sign --ledger --hd-paths "m/44'/60'/{{hdPath}}'/0/0" -- \
  forge script ${script} \
    --rpc-url ${rpcUrl} \
    --sig "signJson(string,address)" \
    ${bundlePath} \
    "${safe}"

approve whichSafe hdPath='0':
  #!/usr/bin/env bash
  bundlePath=${taskPath}/${bundleName}.json
  script=NestedSignFromJson
  if [ -f "${taskPath}/NestedSignFromJson.s.sol" ]; then
    script="${taskPath}/NestedSignFromJson.s.sol"
    echo "Running script with assertions"
  fi
  echo "Using script ${script}"
  if [ "{{whichSafe}}" == "foundation" ]; then
    safe="{{foundationSafe}}"
    echo "Using foundation safe at ${safe}"
  fi
  if [ "{{whichSafe}}" == "council" ]; then
    safe="{{councilSafe}}"
    echo "Using council safe at ${safe}"
  fi
  sender=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")

  forge build
  forge script ${script} \
    --fork-url ${rpcUrl} \
    --ledger --hd-paths "m/44'/60'/{{hdPath}}'/0/0" \
    --broadcast \
    --sender ${sender} \
    --sig "approveJson(string,address,bytes)" \
    ${bundlePath} \
    ${safe} \
    ${signatures}

execute hdPath='0':
  #!/usr/bin/env bash
  bundlePath=${taskPath}/${bundleName}.json
  script=NestedSignFromJson
  if [ -f "${taskPath}/NestedSignFromJson.s.sol" ]; then
    script="${taskPath}/NestedSignFromJson.s.sol"
    echo "Running script with assertions"
  fi
  echo "Using script ${script}"
  sender=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")

  forge build
  forge script ${script} \
    --fork-url ${rpcUrl} \
    --ledger --hd-paths "m/44'/60'/{{hdPath}}'/0/0" \
    --broadcast \
    --sender ${sender} \
    --sig "runJson(string)" \
    ${bundlePath}

simulated-run hdPath='0':
  #!/usr/bin/env bash
  bundlePath=${taskPath}/${bundleName}.json
  script=NestedSignFromJson
  if [ -f "${taskPath}/NestedSignFromJson.s.sol" ]; then
    script="${taskPath}/NestedSignFromJson.s.sol"
    echo "Running script with assertions"
  fi
  echo "Using script ${script}"

  forge build
  forge script ${script} \
    --fork-url ${rpcUrl} \
    --sender ${randomPersonEoa} \
    --sig "runJson(string)" \
    ${bundlePath}
