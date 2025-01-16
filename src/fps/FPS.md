# Overview

The forge proposal simulator was created to solve the problem of testing and validating governance proposals before and after they land onchain. With support for Gnosis Safes, Timelocks and Governor Bravo this tooling can be adapted to most use cases. The simulator allows developers to write tasks that simulate the state changes that would occur onchain if the proposal were to be executed. The simulator as installed in the superchain-ops repo can be run against any mainnet, sepolia, and devnet.

The goal of using FPS for the superchain ops repo is to greatly simplify task development, increase security by reducing errors, reduce sharp edges, and speed development and review of tasks. The simulation is designed to simulate task runs, with all onchain state changes being run locally.

## Task Development and Templates

Installing FPS allows developers to create tasks without writing any Solidity code as long as a predefined template is used. The templates are designed to be as flexible as possible, allowing developers to create tasks that update multiple parameters for a single or super chain.

Existing templates include:
- DisputeGameUpgrade - Dispute Game Implementation change
- GasConfigTemplate - Gas Limit Configuration
- Generic Template - Allows developers to create tasks in Solidity using FPS tooling

# Task Configuration File

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
