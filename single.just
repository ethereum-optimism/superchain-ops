set dotenv-load

export rpcUrl := env_var('ETH_RPC_URL')
export signatures := env_var_or_default('SIGNATURES', '')
export bundleName := env_var_or_default('BUNDLE_NAME', 'input')
export taskPath := invocation_directory()
export ownerSafe := env_var('OWNER_SAFE')

simulate hdPath='0':
  #!/usr/bin/env bash
  bundlePath=${taskPath}/${bundleName}.json
  script=SignFromJson
  if [ -f "${taskPath}/SignFromJson.s.sol" ]; then
    script="${taskPath}/SignFromJson.s.sol"
  fi

  echo "Using script ${script}"
  echo "Safe address: ${ownerSafe}"
  echo "Getting signer address..."

  if [ ! -z "$SIMULATE_WITHOUT_LEDGER" ]; then
    signer=$(cast call ${ownerSafe} "getOwners()(address[])" -r ${rpcUrl} | grep -oE '0x[a-fA-F0-9]{40}' | head -n1)
  else
    signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
  fi
  echo "Simulating with: ${signer}"
  echo ""

  forge build
  forge script ${script} \
    --rpc-url ${rpcUrl} \
    --sig "signJson(string)" ${bundlePath} \
    --sender ${signer}

sign hdPath='0':
  #!/usr/bin/env bash
  bundlePath=${taskPath}/${bundleName}.json
  script=SignFromJson
  if [ -f "${taskPath}/SignFromJson.s.sol" ]; then
    script="${taskPath}/SignFromJson.s.sol"
  fi
  echo "Using script ${script}"
  echo "getting signer address..."
  signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
  echo "Signing with: ${signer}"
  echo ""

  forge build
  $(go env GOPATH)/bin/eip712sign --ledger --hd-paths "m/44'/60'/{{hdPath}}'/0/0" -- \
  forge script ${script} \
    --rpc-url ${rpcUrl} \
    --sig "signJson(string)" \
    ${bundlePath}

execute hdPath='0':
  #!/usr/bin/env bash
  bundlePath=${taskPath}/${bundleName}.json
  script=SignFromJson
  if [ -f "${taskPath}/SignFromJson.s.sol" ]; then
    script="${taskPath}/SignFromJson.s.sol"
  fi
  echo "Using script ${script}"
  sender=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")

  forge build
  forge script --fork-url ${ETH_RPC_URL} ${script} \
    --sig "runJson(string,bytes)" ${bundlePath} ${SIGNATURES} \
    --ledger --hd-paths "m/44'/60'/{{hdPath}}'/0/0" --broadcast \
    --sender ${sender}
