# Template Architecture Guide

This guide explains the architecture of the template system, including configuration structure, file organization, and validation requirements.

## Directory Structure

Templates are organized in the following structure:

```
src/improvements/
├── template/           # Template Solidity contracts
├── doc/               # Documentation
└── tasks/             # Network-specific tasks
     ├── eth/          # Ethereum mainnet tasks
     ├── sep/          # Sepolia testnet tasks
     ├── oeth/         # Optimism Ethereum tasks
     └── opsep/        # Optimism Sepolia tasks
```

## Template Configuration Structure

### 1. Template Location

Templates are Solidity contracts located in the `src/improvements/template/` directory. Each template is designed for a specific type of task operation.

### 2. Configuration File Architecture

Each task requires a `config.toml` file with two main components:

1. L2 Chain Configuration
2. Template-specific parameters

#### L2 Chain Configuration

Every config file must specify the L2 chains that the task will interact with:

```toml
l2chains = [
    {name = "Orderly", chainId = 291},
    {name = "Metal", chainId = 1750}
]
```

#### Template Selection

Templates are specified using the `templateName` parameter:

```toml
templateName = "GasConfigTemplate"  # Uses src/improvements/template/GasConfigTemplate.sol
```

### 3. Task Status Definitions

Tasks can have the following statuses in their README files:

- `DRAFT, NOT READY TO SIGN`: Initial development stage, not ready to sign
- `CONTINGENCY TASK, SIGN AS NEEDED`: Task that may be signed based on specific conditions, such as emergency rollback.
- `READY TO SIGN`: Task ready for signature
- `SIGNED`: Task signed and ready for execution
- `EXECUTED`: Task completed successfully
- `CANCELLED`: Execution failed or abandoned

### 4. Template-Specific Configuration

Each template type has its own configuration structure. For example:

```toml
# Gas Config Template
[gasConfigs]
gasLimits = [
    {chainId = 291, gasLimit = 100000000},
    {chainId = 1750, gasLimit = 100000000}
]

# Dispute Game Template
implementations = [{
    gameType = 0,
    implementation = "0xf691F8A6d908B58C534B624cF16495b491E633BA",
    l2ChainId = 10
}]
```

## Validation System

The template system includes built-in validation:

1. Configuration Validation
   - Verifies TOML syntax
   - Checks required fields
   - Validates chain IDs
   - Ensures parameter types match expectations

2. State Change Validation
   - Verifies changes match expected values

3. Security Checks
   - Verifies permissions
   - Validates address formats
   - Checks value ranges
   - Check that only the expected storage slots are modified

## Network Organization

Tasks are organized by network in the tasks directory:

1. Ethereum Mainnet (`eth/`)
   - Production-ready tasks
   - Strict validation requirements
   - Full security review needed

2. Sepolia Testnet (`sep/`)
   - Testing and validation
   - Development and staging
   - Less strict security requirements

3. Optimism Networks
   - `oeth/`: Optimism Ethereum tasks
   - `opsep/`: Optimism Sepolia tasks
   - Network-specific configurations

Each network directory follows a numbered sequence for tasks (e.g., 001, 002) to maintain chronological order and dependencies.

## Best Practices

1. Configuration Organization
   - Keep network-specific parameters separate
   - Use clear parameter names
   - Document all configuration options

2. Validation Rules
   - Assert all expected state changes occurred correctly
   - Assert no unexpected state changes occurred

## Common Fields Reference

Examples of some fields used in templates:

1. Chain Configuration
   ```toml
   [l2Chains]
   name = "Optimism"       # Chain name
   chainId = 10            # Chain ID
   ```

2. Transaction Parameters
   ```toml
   [gasConfigs]
   gasLimits = [{
      gasLimit = number   # Gas limit
      value = number      # Transaction value
   }]
   ```

## Error Handling

Templates should implement error handling around minimum and maximum values.
