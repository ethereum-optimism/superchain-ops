set dotenv-load

# Common variables used across multiple recipes
# Export variables in uppercase for shell script usage
export TASK_PATH := invocation_directory()
export SCRIPT_PATH := justfile_directory()

# Get RPC URL based on task path
rpc_cmd := SCRIPT_PATH + "/get-rpc-url.sh \"" + TASK_PATH + "\""
export rpcUrl := shell(rpc_cmd)

# Fetch the template name from the config.toml file
cmd := "sed -n 's/^[[:space:]]*templateName[[:space:]]*=[[:space:]]*\\\"\\([^\\\"]*\\)\\\".*/\\1/p' " + TASK_PATH + "/config.toml"
export SCRIPT_NAME := shell(cmd)
export signatures := env_var_or_default('SIGNATURES', '')
randomPersonEoa := "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"

simulate whichSafe hdPath='0':
  #!/usr/bin/env bash
  # Get the appropriate safe address based on whichSafe
  if [ "{{whichSafe}}" == "foundation" ]; then
    if [ -z "$FOUNDATION_SAFE" ]; then
      echo "Error: FOUNDATION_SAFE is required for foundation simulation" >&2
      exit 1
    fi
    safe="$FOUNDATION_SAFE"
  elif [ "{{whichSafe}}" == "council" ]; then
    if [ -z "$COUNCIL_SAFE" ]; then
      echo "Error: COUNCIL_SAFE is required for council simulation" >&2
      exit 1
    fi
    safe="$COUNCIL_SAFE"
  elif [ "{{whichSafe}}" == "chain-governor" ]; then
    if [ -z "$CHAIN_GOVERNOR_SAFE" ]; then
      echo "Error: CHAIN_GOVERNOR_SAFE is required for chain-governor simulation" >&2
      exit 1
    fi
    safe="$CHAIN_GOVERNOR_SAFE"
  else
    echo "Error: Invalid safe type {{whichSafe}}" >&2
    exit 1
  fi

  config=${TASK_PATH}/config.toml
  script=${SCRIPT_PATH}/template/${SCRIPT_NAME}.sol

  echo "Using script ${script}"
  echo "getting signer address for {{whichSafe}}..."
  signer=$(cast call ${safe} "getOwners()(address[])" -r ${rpcUrl} | grep -oE '0x[a-fA-F0-9]{40}' | head -n1)

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
    --sig "signFromChildMultisig(string,address)" \
    ${config} \
    ${safe}

sign whichSafe hdPath='0':
  #!/usr/bin/env bash
  # Get the appropriate safe address based on whichSafe
  if [ "{{whichSafe}}" == "foundation" ]; then
    if [ -z "$FOUNDATION_SAFE" ]; then
      echo "Error: FOUNDATION_SAFE is required for foundation signing" >&2
      exit 1
    fi
    safe="$FOUNDATION_SAFE"
    echo "Using foundation safe at ${safe}"
  elif [ "{{whichSafe}}" == "council" ]; then
    if [ -z "$COUNCIL_SAFE" ]; then
      echo "Error: COUNCIL_SAFE is required for council signing" >&2
      exit 1
    fi
    safe="$COUNCIL_SAFE"
    echo "Using council safe at ${safe}"
  elif [ "{{whichSafe}}" == "chain-governor" ]; then
    if [ -z "$CHAIN_GOVERNOR_SAFE" ]; then
      echo "Error: CHAIN_GOVERNOR_SAFE is required for chain-governor signing" >&2
      exit 1
    fi
    safe="$CHAIN_GOVERNOR_SAFE"
  else
    echo "Error: Invalid safe type {{whichSafe}}" >&2
    exit 1
  fi

  config=${TASK_PATH}/config.toml
  script=${SCRIPT_PATH}/template/${SCRIPT_NAME}.sol
  echo "getting signer address..."
  signer=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
  echo "Signing with: ${signer}"
  echo ""

  forge build
  # Using the eip712sign within the repo folder since eip712sign was installed there in ./justfile.
  $(git rev-parse --show-toplevel)/bin/eip712sign --ledger --hd-paths "m/44'/60'/{{hdPath}}'/0/0" -- \
  forge script ${script} \
    --rpc-url ${rpcUrl} \
    --sig "signFromChildMultisig(string,address)" \
    ${config} \
    "${safe}"

approve whichSafe hdPath='0':
  #!/usr/bin/env bash
  # Get the appropriate safe address based on whichSafe
  if [ "{{whichSafe}}" == "foundation" ]; then
    if [ -z "$FOUNDATION_SAFE" ]; then
      echo "Error: FOUNDATION_SAFE is required for foundation approval" >&2
      exit 1
    fi
    safe="$FOUNDATION_SAFE"
    echo "Using foundation safe at ${safe}"
  elif [ "{{whichSafe}}" == "council" ]; then
    if [ -z "$COUNCIL_SAFE" ]; then
      echo "Error: COUNCIL_SAFE is required for council approval" >&2
      exit 1
    fi
    safe="$COUNCIL_SAFE"
    echo "Using council safe at ${safe}"
  elif [ "{{whichSafe}}" == "chain-governor" ]; then
    if [ -z "$CHAIN_GOVERNOR_SAFE" ]; then
      echo "Error: CHAIN_GOVERNOR_SAFE is required for chain-governor approval" >&2
      exit 1
    fi
    safe="$CHAIN_GOVERNOR_SAFE"
  else
    echo "Error: Invalid safe type {{whichSafe}}" >&2
    exit 1
  fi

  config=${TASK_PATH}/config.toml
  script=${SCRIPT_PATH}/template/${SCRIPT_NAME}.sol
  sender=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")

  forge build
  forge script ${script} \
    --fork-url ${rpcUrl} \
    --ledger --hd-paths "m/44'/60'/{{hdPath}}'/0/0" \
    --broadcast \
    --sender ${sender} \
    --sig "approveFromChildMultisig(string,address,bytes)" \
    ${config} \
    ${safe} \
    ${signatures}

simulate-approve whichSafe hdPath='0':
  #!/usr/bin/env bash
  # Get the appropriate safe address based on whichSafe
  if [ "{{whichSafe}}" == "foundation" ]; then
    if [ -z "$FOUNDATION_SAFE" ]; then
      echo "Error: FOUNDATION_SAFE is required for foundation simulate-approve" >&2
      exit 1
    fi
    safe="$FOUNDATION_SAFE"
    echo "Using foundation safe at ${safe}"
  elif [ "{{whichSafe}}" == "council" ]; then
    if [ -z "$COUNCIL_SAFE" ]; then
      echo "Error: COUNCIL_SAFE is required for council simulate-approve" >&2
      exit 1
    fi
    safe="$COUNCIL_SAFE"
    echo "Using council safe at ${safe}"
  elif [ "{{whichSafe}}" == "chain-governor" ]; then
    if [ -z "$CHAIN_GOVERNOR_SAFE" ]; then
      echo "Error: CHAIN_GOVERNOR_SAFE is required for chain-governor simulate-approve" >&2
      exit 1
    fi
    safe="$CHAIN_GOVERNOR_SAFE"
  else
    echo "Error: Invalid safe type {{whichSafe}}" >&2
    exit 1
  fi

  config=${TASK_PATH}/config.toml
  script=${SCRIPT_PATH}/template/${SCRIPT_NAME}.sol

  if [ ! -z "$SIMULATE_WITHOUT_LEDGER" ]; then
    sender=$(cast call ${safe} "getOwners()(address[])" -r ${rpcUrl} | grep -oE '0x[a-fA-F0-9]{40}' | head -n1)
  else
    sender=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")
  fi

  forge build
  forge script ${script} \
    --fork-url ${rpcUrl} \
    --sender ${sender} \
    --sig "approveFromChildMultisig(string,address,bytes)" \
    ${config} \
    ${safe} \
    ${signatures}

execute hdPath='0':
  #!/usr/bin/env bash
  config=${TASK_PATH}/config.toml
  script=${SCRIPT_PATH}/template/${SCRIPT_NAME}.sol

  echo "Using script ${script}"
  sender=$(cast wallet address --ledger --mnemonic-derivation-path "m/44'/60'/{{hdPath}}'/0/0")

  forge build
  forge script ${script} \
    --fork-url ${rpcUrl} \
    --ledger --hd-paths "m/44'/60'/{{hdPath}}'/0/0" \
    --broadcast \
    --sender ${sender} \
    --sig "executeRun(string,bytes)" \
    ${config} \
    "0x"

simulated-run hdPath='0':
  #!/usr/bin/env bash
  config=${TASK_PATH}/config.toml
  script=${SCRIPT_PATH}/template/${SCRIPT_NAME}.sol

  echo "Using script ${script}"

  forge build
  forge script ${script} \
    --fork-url ${rpcUrl} \
    --sender ${randomPersonEoa} \
    --sig "executeRun(string,bytes)" \
    ${config} \
    "0x"
