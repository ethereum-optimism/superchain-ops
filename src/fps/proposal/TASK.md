# Overview

Each task will have at least 2 config files.

The first file is `taskConfig.toml` which contains the task configuration.

## Run Flags

- `doMock` - whether to run mocks
- `doBuild` - whether to build the given task
- `doSimulate` - whether to run the given task and apply its state changes to the network it is being run against
- `doValidate` - whether to run the validate function, verifying all state changes are correct
- `doPrint` - whether to print the state changes and calldata for the task to the console

## Task Fields

- `safeConfigChange` - whether the task will change the safe configuration. this does not include the owners and only includes the fallback handler, threshold, modules and the guard
- `safeOwnersChange` - whether the task will change the safe owners
- `safeAddressString` - the identifier of the safe in the task to run
- `allowedStorageAccesses` - the identifiers of the storage writes that are allowed for the task. if empty, no storage writes are allowed
- `authorizedDelegateCalls` - the identifiers of the contracts that delegate calls are allowed to for the task. if empty, no delegate calls are allowed
- `name` - the name of the task, including the number of the task
- `description` - what the task does

# Network Configuration File

The second file is `<network_name>Config.toml` which contains the network configurations to modify on L1. This file is used to configure which L2 network contracts will be used for the task on the given network. Task developers can specify up to three separate types of configuration files:

- `mainnetConfig.toml` - the mainnet configuration file, which specifies which L2 contracts will be affected on L1 mainnet
- `sepoliaConfig.toml` - the sepolia configuration file, which specifies which L2 contracts will be affected on L1 sepolia
- `devnetConfig.toml` - the devnet configuration file, which specifies which L2 contracts will be affected on L1 devnet (sepolia testnet)

## Network Fields

The network configuration file contains the following fields.

### L2Chains

```toml
# L2Chains is a list of the L2 chains that the task will interact with
l2chains = [{"name": "Orderly", "chainId": 291}, {"name": "Metal", "chainId": 1750}, {"name": OP Mainnet", "chainId": 10}]

# Nonce for the gnosis safe that will be used for the task
safeNonce = 67

# Whether the safe is nested
isNestedSafe = false
```

### Gas Configuration
If a task is updating the gas limits for a given chain, the gas configuration can be specified in the network configuration file.

```toml
# Gas configuration for the task
gasLimits = [{chainId = 291, gasLimit = 100000000}, {chainId = 1750, gasLimit = 100000000}, {chainId = 10, gasLimit = 100000000}]
```

# Usage

To run a GasConfigTemplate task, use the following command:

```bash
forge script GasConfigTemplate --sig "run(string,string)" "src/fps/example/task-00/taskConfig.toml" "src/fps/example/task-00/mainnetConfig.toml" -vvvv --rpc-url mainnet
```

When running the task on testnet, replace `mainnet` with `sepolia` or `devnet`, and the rpc-url with the appropriate testnet url.
