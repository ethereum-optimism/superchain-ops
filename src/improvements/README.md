# Superchain Task System

A powerful simulation tooling system that allows developers to write and test tasks that simulate onchain state changes before execution. The system supports mainnet, sepolia, and devnet environments.

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
  * Template configuration structure
  * TOML file layout
  * Task status definitions
  * Validation system
- [Task Creation Guide](./doc/TASK_CREATION_GUIDE.md)
  * Step-by-step task creation
  * Using the justfile scaffolding
  * Best practices and troubleshooting
- [New Template Guide](./doc/NEW_TEMPLATE_GUIDE.md)
  * Creating Solidity templates
  * Required implementations
  * Testing requirements
- [Address Registry](./doc/ADDRESS_REGISTRY.md)
  * Network addresses
  * Contract deployments
  * Configuration references

## Key Features

- **Template-Based Development**: Create tasks without writing Solidity code using predefined templates
- **Cross-Network Support**: Test and deploy tasks across multiple networks
- **Built-in Validation**: Automated checks for state changes and security
- **Simulation First**: Test all changes locally before deployment

## Repository Structure

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

## Network Organization

Tasks are organized by network to maintain clear separation and specific requirements:

1. **Ethereum Mainnet** (`tasks/eth/`)
   - Production-ready tasks
   - Example: eth/001-security-council-phase-0

2. **Sepolia Testnet** (`tasks/sep/`)
   - Testing and validation
   - Development environment
   - Example: sep/001-op-extended-pause

3. **Optimism Networks**
   - `tasks/oeth/`: Optimism Ethereum tasks
   - `tasks/opsep/`: Optimism Sepolia tasks
   - Network-specific configurations

## Quick Start

1. Create a new task:
```bash
cd src/improvements/
just new task
```

2. Configure the task in `config.toml`:
```toml
templateName = "GasConfigTemplate"
l2chains = [{name = "Chain1", chainId = 123}]
```

3. Test the task:
```bash
forge script <template-path> --sig "run(string)" <config-path> --rpc-url devnet -vvv
```

## Available Templates

1. **Gas Config Template**
   - Set gas limits for L2 chains
   - Configure transaction parameters
   - Example: [Gas Config Example](#gas-config-example)

2. **Dispute Game Template**
   - Configure dispute game implementations
   - Set game parameters
   - Example: [Dispute Game Example](#dispute-game-example)

3. **Game Type Template**
   - Set respected game types
   - Configure chain permissions
   - Example: [Game Type Example](#game-type-example)

## Documentation

### Core Concepts
- [Template Architecture Guide](./doc/TEMPLATE_ARCHITECTURE.md)
  * Template configuration structure
  * TOML file architecture
  * Task status definitions
  * Validation system

- [Task Creation Guide](./doc/TASK_CREATION_GUIDE.md)
  * Step-by-step task creation
  * Using the justfile scaffolding
  * Best practices
  * Troubleshooting

- [New Template Guide](./doc/NEW_TEMPLATE_GUIDE.md)
  * Creating Solidity templates
  * Required implementations
  * Testing requirements
  * Example walkthrough

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

### Dispute Game Example
```toml
templateName = "DisputeGameUpgradeTemplate"
l2chains = [{name = "OP Mainnet", chainId = 10}]

implementations = [{
    gameType = 0,
    implementation = "0xf691F8A6d908B58C534B624cF16495b491E633BA",
    l2ChainId = 10
}]
```

### Game Type Example
```toml
templateName = "SetGameTypeTemplate"
l2chains = [{name = "OP Mainnet", chainId = 10}]

respectedGameTypes = [{
    deputyGuardian = "0xc6901F65369FC59fC1B4D6D6bE7A2318Ff38dB5B",
    gameType = 1,
    l2ChainId = 10,
    portal = "OptimismPortalProxy"
}]
```

## Best Practices

1. **Task Development**
   - Start with devnet testing
   - Move to testnet validation
   - Document all parameters
   - Include validation steps

2. **Network Handling**
   - Use appropriate network directories
   - Follow naming conventions
   - Include network-specific configs
   - Test across networks

3. **Documentation**
   - Keep README files updated
   - Document special requirements
   - Include validation steps
   - Track task status

## Task Validation

The system allows adding validations for each task:
1. Configuration validation
2. State change verification
3. Any additional security checks you can dream up

Properly implemented validation functions, cause tasks to revert on failure, ensuring safety.
