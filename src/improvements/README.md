# Superchain Task System

A powerful simulation tooling system that enables developers to write and test tasks that simulate onchain state changes before execution. The system supports mainnet, sepolia, and devnet environments.

## Table of Contents

- [Key Features](#key-features)
- [Repository Structure](#repository-structure)
- [Network Organization](#network-organization)
- [Quick Start](#quick-start)
- [Available Templates](#available-templates)
  * [Gas Config Example](#gas-config-example)
  * [Dispute Game Example](#dispute-game-example)
  * [Game Type Example](#game-type-example)
- [Best Practices](#best-practices)
- [Validation](#validation)

### Detailed Documentation
- [Template Architecture Guide](./doc/TEMPLATE_ARCHITECTURE.md)
- [Task Creation Guide](./doc/TASK_CREATION_GUIDE.md)
- [New Template Guide](./doc/NEW_TEMPLATE_GUIDE.md)
- [Address Registry](./doc/ADDRESS_REGISTRY.md)

## Key Features

- Create tasks without writing Solidity code using predefined templates.
- Configure tasks for multiple networks as long as they are all part of a single Superchain instance.
- Perform automated checks for state changes and security.
- Test all changes locally before executing tasks on-chain.

## Repository Structure
The template configuration file is called `config.toml` which contains the network configurations for modifying L1.

```
superchain-ops/
└── src/
    └── improvements/
       ├── template/     # Solidity template contracts
       └── doc/          # Detailed documentation
       └── tasks/        # Network-specific tasks
            ├── eth/     # Ethereum mainnet tasks
            ├── sep/     # Sepolia testnet tasks
            ├── oeth/    # Optimism Ethereum tasks
            └── opsep/   # Optimism Sepolia tasks
```

## Quick Start

1. Create a new task:
```bash
cd src/improvements/
just new task
```

2. Configure the task in `config.toml`:
```toml
templateName = "GasConfigTemplate"
l2chains = [{"name": "OP Mainnet", "chainId": 10}]
```

3. Test the task:
```bash
forge script <template-path> --sig "run(string)" <config-path> --rpc-url devnet -vvv
```

## Available Templates

All available templates can be found in the [template](./template/) directory. 

## Example Configurations

### Gas Config Example
```toml
templateName = "GasConfigTemplate"
l2chains = [{name = "Orderly", chainId = 291}]

[gasConfigs]
gasLimits = [
    {chainId = 291, gasLimit = 100000000}
]
```

Other existing templates include [`DisputeGameUpgradeTemplate`](./template/DisputeGameUpgradeTemplate.sol) and [`SetGameTypeTemplate`](./template/SetGameTypeTemplate.sol).