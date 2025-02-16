# sim-sequence.sh

A utility script for simulating a sequence of tasks against an Anvil fork with state overrides disabled.
This script will lookup for the tasks in the tasks directory and simulate them in the order of the array of task IDs.


[Demo Sim-sequence.sh](https://github.com/user-attachments/assets/50e85b69-f7dc-40fe-b689-aa1e58394400)



## Synopsis

```bash
./script/utils/sim-sequence.sh <network> "<array-of-task-IDs>" [block_number]
```

## Description

The script simulates a sequence of tasks against an Anvil fork with state overrides disabled.
This script simulates a sequence of tasks for a given network by running them against an Anvil fork. It's designed to verify task execution order and catch potential issues before actual deployment.

## Arguments

- `<network>` (required): The network to simulate against (e.g., eth, base)
- `"<array-of-task-IDs>"` (required): Space-separated list of task IDs to simulate in order
- `[block_number]` (optional): Specific block number to fork from

## Options

The script uses several environment variables that can be configured:

- `ANVIL_LOCALHOST_RPC`: Default is "http://localhost:8545"
- `DESTROY_ANIVIL_AFTER_EXECUTION`: Controls whether to destroy the Anvil instance after execution.

## Examples
Execution with tasks example: 
```bash
# Simulate multiple tasks on Ethereum
./script/utils/sim-sequence.sh eth "021 022 base-003 ink-001"

# Simulate tasks with specific block number
./script/utils/sim-sequence.sh eth "021 022" 18000000

# Simulate single task
./script/utils/sim-sequence.sh eth "021"


## Exit Codes

- `0`: Successful execution
- `1`: General error (invalid arguments, directory not found, etc.)
- `99`: Simulation failure (nonce errors, task execution failures)

## Dependencies

- `anvil`: For creating local network fork
- `cast`: For interacting with smart contracts
- `just`: For task execution
- Standard Unix utilities (find, awk, etc.)

## Notes

- The script will detect if an Anvil instance is already running on port 8545
- State overrides are disabled during simulation
- Tasks can be either nested or single type
- Each task must have a valid .env file
- Task folders must exist in the `tasks/<network>` directory
