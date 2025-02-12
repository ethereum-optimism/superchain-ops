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
├── eth/    # Ethereum mainnet tasks
├── sep/    # Sepolia testnet tasks
├── oeth/   # Optimism Ethereum tasks
└── opsep/  # Optimism Sepolia tasks
```

### Task Naming Convention

The naming convention for tasks follows a lexicographical order. To see the current lexicographical ordering of tasks in a network, you can execute just task ls. This command will list all tasks for a given network in order.

The only constraint imposed at the moment is that tasks must be in lexicographical order. However, teams can build their own naming conventions on top of this constraint.

For example, a structured format like [network]/[###]-[descriptive-name] can be used to maintain clarity and organization:
- Format: [network]/[###]-[descriptive-name]
- Example: eth/001-security-council-phase-0

Please be mindful when naming tasks to ensure consistency and readability.
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
- Attempt to create a new task that is lexicographically greater than the existing tasks
- Create a new numbered directory
- Generate README.md template
- Create config.toml template
- Set up basic structure

### 2. Configure the Task

While the `just new task` command attempts to guide users through creating a fully configured task. Users will still need to manually edit the `config.toml` file to make alertations based on the specifics of the task they are developing.

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

When a new task is created, a README.md file is generated with a template that should be filled out with the specifics of the task. TODO's are automatically placed throughout the README to guide users on what to fill in.

## Task Status Lifecycle

There are two lifecycles for tasks. One for tasks that are in development for execution at a concrete future date, and one for tasks that are used for an unspecified reason in the future, such as pausing a contract.

For tasks that are in development for execution at a concrete future date, the statuses are as follows:

1. "DRAFT, NOT READY TO SIGN": Initial development stage, not ready to sign
2. "READY TO SIGN": Task ready for signature
3. "SIGNED": Task signed and ready for execution
4. "EXECUTED": Task completed successfully on chain

For tasks that are used for an unspecified reason in the future, such as pausing a contract, the statuses are as follows:

1. "DRAFT, NOT READY TO SIGN": Initial development stage, not ready to sign
2. "CONTINGENCY TASK, SIGN AS NEEDED": Task that may be signed based on specific conditions, such as emergency rollback
3. "EXECUTED": Task completed successfully on chain. Once executed, the README should be updated to contain a link to the execution of the transaction on chain. Example [here](https://github.com/ethereum-optimism/superchain-ops/pull/543/files).