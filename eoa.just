set dotenv-load

export rpcUrl := env_var('ETH_RPC_URL')
export bundleName := env_var_or_default('BUNDLE_NAME', 'input')
export taskPath := invocation_directory()

# Accounts
export proxyAdminOwner := env_var('PROXY_ADMIN_OWNER')

simulate hdPath='0'::
  #!/usr/bin/env bash
  bundlePath=${taskPath}/${bundleName}.json
  script="${taskPath}/EOASignFromJson.s.sol"
  echo "Using script ${script}"
  echo "Simulating with ProxyAdmin owner ${proxyAdminOwner}"

  ledgerFlags=""
  if [ "$SIMULATE_WITHOUT_LEDGER" ]; then
    derivationPath="m/44'/60'/{{hdPath}}'/0/0"
    ledgerFlags="--ledger --mnemonic-derivation-path ${derivationPath}"
  fi

  forge script ${script} \
    --rpc-url ${rpcUrl} \
    --sig "run(string)" ${bundlePath} \
    --sender ${signer} \
    ${ledgerFlags}

execute hdPath='0':
  #!/usr/bin/env bash
  bundlePath=${taskPath}/${bundleName}.json
  script="${taskPath}/EOASignFromJson.s.sol"
  echo "Using script ${script}"
  echo "Simulating with ProxyAdmin owner ${proxyAdminOwner}"

  ledgerFlags=""
  if [ "$SIMULATE_WITHOUT_LEDGER" ]; then
    derivationPath="m/44'/60'/{{hdPath}}'/0/0"
    ledgerFlags="--ledger --mnemonic-derivation-path ${derivationPath}"
  fi

  forge script ${script} \
    --rpc-url ${rpcUrl} \
    --sig "run(string)" ${bundlePath} \
    --sender ${signer} \
    ${ledgerFlags} \
    --broadcast
