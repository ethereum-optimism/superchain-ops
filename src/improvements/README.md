# Overview

This new calldata simulation tooling allows developers to write tasks that simulate the state changes that would occur onchain if the task were to be executed. The simulator can be run against any mainnet, sepolia, and devnet.

The goal of using this new task tooling for the superchain ops repo is to greatly simplify task development, increase security by reducing errors, reduce sharp edges, and speed development and review of tasks. The simulation is designed to simulate task runs, with all onchain state changes being run locally.

## Task Development and Templates

Developers can now create tasks without writing any Solidity code as long as a predefined template is used. The templates are designed to be as flexible as possible, allowing developers to create tasks that update multiple parameters for a single or super chain. Templates are currently in development and will be released in a future PR.

# Task Configuration File

The template configuration file is `config.toml` which contains the network configurations to modify on L1.

### L2Chains

```toml
# L2Chains is a list of the L2 chains that the task will interact with
l2chains = [{"name": "Base", "chainId": 8453}, {"name": "Metal", "chainId": 1750}, {"name": "OP Mainnet", "chainId": 10}]
```

### Task Template Files

Task templates allow task developers to create new tasks without writing any Solidity code. The templates are designed to be as flexible as possible, allowing developers to create tasks that update multiple parameters for a single or superchain. Templates are currently in development and will be released in a future PR.

The mainnet configuration file for task template example 00 can be found here: [task-00/mainnetConfig.toml](./example/task-00/mainnetConfig.toml)

```toml
[gasConfigs]
gasLimits = [{chainId = 291, gasLimit = 100000000}, {chainId = 1750, gasLimit = 100000000}]
```

This toml configuration file allows task developers to set gas limits for the task. After the changes are applied in the simulation, validations are run to ensure that the new values are the expected values.

### Running Example Tasks

#### Template 00 to set gas configs:

```bash
forge script src/improvements/template/GasConfigTemplate.sol --sig "run(string)" test/tasks/mock/example/task-00/config.toml --rpc-url mainnet -vvv
```

#### Template 01 to set dispute game upgrade:

```bash
forge script src/improvements/template/DisputeGameUpgradeTemplate.sol --sig "run(string)" test/tasks/mock/example/task-01/config.toml --rpc-url mainnet -vvv
```

#### Template 02 to set respected game type:

```bash
forge script src/improvements/template/SetGameTypeTemplate.sol --sig "run(string)" test/tasks/mock/example/task-02/config.toml --rpc-url mainnet -vvvvv
```

#### Template 03 to set gas config:

```bash
forge script src/improvements/template/GasConfigTemplate.sol --sig "run(string)" test/tasks/mock/example/task-03/config.toml --rpc-url mainnet -vvvvv
```
