# Task Creation Guide

This guide walks through the process of creating new tasks using existing templates, including network-specific considerations and best practices.

## Quick Start

To scaffold a new task using an existing template:

```bash
cd src/improvements/
just new task
```

Follow the prompts from the justfile to create a new task directory with pre-populated README.md and config.toml files.

## Directory Structure

Tasks are organized by network in the following structure:

```
src/improvements/tasks/
├── eth/           # Ethereum mainnet tasks
├── sep/           # Sepolia testnet tasks
├── oeth/          # Optimism Ethereum tasks
├── opsep/         # Optimism Sepolia tasks
└── common/        # Shared resources and documentation
```

### Network-Specific Organization

1. Ethereum Mainnet (tasks/eth/)
   - Production tasks
   - Strict security requirements
   - Full testing required
   - Example: eth/001-security-council-phase-0/

2. Sepolia Testnet (tasks/sep/)
   - Testing and validation
   - Development tasks
   - Example: sep/001-op-extended-pause/

3. Optimism Networks
   - tasks/oeth/: Optimism Ethereum tasks
   - tasks/opsep/: Optimism Sepolia tasks
   - Network-specific configurations required

### Task Naming Convention

Tasks follow a numbered sequence within each network directory:
- Format: `[network]/[###]-[descriptive-name]`
- Example: `eth/001-security-council-phase-0`
- Numbers help track task order and dependencies
- Descriptive names should be clear and concise

## Creating a New Task

### 1. Use the Task Scaffolding Tool

```bash
cd src/improvements/
just new task
```

The tool will:
- Create a new numbered directory
- Generate README.md template
- Create config.toml template
- Set up basic structure

### 2. Configure the Task

Edit config.toml to specify:

1. Template Selection
```toml
templateName = "GasConfigTemplate"
```

2. L2 Chain Configuration
```toml
l2chains = [
    {name = "Orderly", chainId = 291},
    {name = "Metal", chainId = 1750}
]
```

3. Template-Specific Parameters
```toml
[gasConfigs]
gasLimits = [
    {chainId = 291, gasLimit = 100000000},
    {chainId = 1750, gasLimit = 100000000}
]
```

### 3. Document the Task

Update README.md with:
- Task description
- Requirements
- Expected outcomes
- Testing steps
- Validation criteria
- Status updates

## Testing and Validation

1. Local Testing
```bash
forge script <template-path> --sig "run(string)" <config-file-path> --rpc-url devnet -vvv
```

2. Testnet Validation
- Deploy to Sepolia first
- Verify state changes
- Check validation results

3. Production Deployment
- Full security review
- Comprehensive testing
- Stakeholder approval

## Common Task Types

1. Gas Configuration
```toml
templateName = "GasConfigTemplate"
[gasConfigs]
gasLimits = [...]
```

2. Dispute Game Upgrades
```toml
templateName = "DisputeGameUpgradeTemplate"
implementations = [...]
```

3. Game Type Configuration
```toml
templateName = "SetGameTypeTemplate"
respectedGameTypes = [...]
```

## Best Practices

1. Task Organization
   - Use clear, descriptive names
   - Follow network-specific conventions
   - Maintain proper documentation

2. Configuration
   - Document all parameters
   - Use consistent formatting
   - Include validation checks

3. Documentation
   - Keep README.md updated
   - Document any special requirements
   - Include validation steps
   - Track task status

## Troubleshooting

1. Configuration Issues
   - Verify TOML syntax
   - Check required fields
   - Validate chain IDs
   - Ensure proper formatting

2. Simulation Errors
   - Check RPC endpoints
   - Verify function calls

3. Network-Specific Issues
   - Verify chain configuration
   - Check network status
   - Validate addresses
   - Review `config.toml` file settings for each network

## Task Status Lifecycle

There are two lifecycles for tasks. One for tasks that are in development for execution at a concrete future date, and one for tasks that are used for an unspecified reason in the future, such as pausing a a contract.

For tasks that are in development for execution at a concrete future date, the statuses are as follows:

1. "DRAFT, NOT READY TO SIGN": Initial development stage, not ready to sign
2. "READY TO SIGN": Task ready for signature
3. "SIGNED": Task signed and ready for execution
4. "EXECUTED": Task completed successfully on chain

For tasks that are used for an unspecified reason in the future, such as pausing a contract, the statuses are as follows:

1. "DRAFT, NOT READY TO SIGN": Initial development stage, not ready to sign
2. "CONTINGENCY TASK, SIGN AS NEEDED": Task that may be signed based on specific conditions, such as emergency rollback
3. "EXECUTED": Task completed successfully on chain
