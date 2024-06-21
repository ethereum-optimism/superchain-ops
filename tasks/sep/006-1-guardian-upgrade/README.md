# Sepolia Guardian Changes - Foundation Runbook

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0xd62f0d4a18b8917c90eb1e9d89551448e257a46dbd08621e27da3a739e7ffa05)

## Objective

This is the sepolia playbook for reinitializing the SuperchainConfig with the Security Council as Guardian, instead of the Optimism Foundation.
This is a requirement for reaching Stage 1.

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep/006-1-guardian-upgrade/NestedSignFromJson.s.sol`.
This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown
(without the full path), something is wrong and the safety checks will not run.

Do NOT yet proceed to the "Execute the Transaction" section.

## State Validations

Please see the instructions for [validation](./VALIDATION.md).

## Execution

At this point you may resume following the execution instructions in the "Execute the Transaction" section of [NESTED.md](../../../NESTED.md).

When executing, ensure the logs say `Using script Using script /your/path/to/superchain-ops/tasks/sep/006-1-guardian-upgrade/NestedSignFromJson.s.sol`. This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.
