# 024-enable-liveness-module2

Status: [EXAMPLE TASK]

## Objective

Enable the LivenessModule2 on the Guardian Safe and configure it with appropriate parameters for Sepolia.

The LivenessModule2 provides stronger guarantees around system liveness and improves the robustness of the protocol's fault-handling mechanisms.

## Pre-requisites

- The LivenessModule2 must be deployed at `0xBF83aCe11Fa979b90C1e914cC5565271f22C6615`
- The Guardian Safe must not already have the LivenessModule2 enabled

## Transaction Details

This task will:
1. Enable the LivenessModule2 on the Guardian Safe
2. Configure the module with:
   - Liveness response period: 30 days (2592000 seconds)
   - Fallback owner: Foundation Operations Safe (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`)

## Execution

1. Run the task:
   ```bash
   SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../../../src/improvements/justfile simulate
   ```

## Validation

The task will validate:
- The module is enabled on the Safe
- The module is properly configured with the specified parameters
- All storage writes are as expected

## Post-execution

After successful execution:
- The LivenessModule2 will be active on the Guardian Safe
- The fallback owner mechanism will be in place with a 30-day response period