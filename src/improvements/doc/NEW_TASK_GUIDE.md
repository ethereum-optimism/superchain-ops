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
├── eth/    # Ethereum mainnet tasks (Task developers create tasks here)
└── sep/    # Sepolia testnet tasks (Task developers create tasks here)
```

### Task Naming Convention

Tasks MUST follow ascending lexicographical order using the format: `[network]/[###]-[descriptive-name]`.
To view the current lexicographical ordering of tasks within a network, run: `just task ls`. 
This will list all tasks for the specified network in order.

Format:
```
[network]/[###]-[descriptive-name]
```
Example:
```
eth/001-first-task
eth/002-second-task
eth/003-third-task
```

## Task Status Lifecycle

Tasks follow two different lifecycles: one for tasks scheduled for execution on a specific future date, and another for contingency tasks that may be executed later, such as pausing a contract.

For tasks that are in development for execution at a concrete future date, the statuses are as follows:

1. "DRAFT, NOT READY TO SIGN": Initial development stage, not ready to sign
2. "READY TO SIGN": Task ready for signature
3. "SIGNED": Task signed and ready for execution
4. "EXECUTED": Task completed successfully on chain

For tasks that are used for an unspecified reason in the future, such as pausing a contract, the statuses are as follows:

1. "DRAFT, NOT READY TO SIGN": Initial development stage, not ready to sign
2. "CONTINGENCY TASK, SIGN AS NEEDED": Task that may be signed based on specific conditions, such as emergency rollback
3. "EXECUTED": Task completed successfully on chain. Once executed, the README should be updated to contain a link to the execution of the transaction on chain. Example [here](https://github.com/ethereum-optimism/superchain-ops/pull/543/files).