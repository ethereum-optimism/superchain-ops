# Sepolia Guardian Changes - Foundation Runbook

Status: READY TO SIGN

## Objective

This is the sepolia playbook for:

1. Reinitializing the SuperchainConfig with the Security Council as Guardian
1. Transferring ownership of the ProxyAdmin to a new 2 of 2 safe

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script Using script /your/path/to/superchain-ops/tasks/sep/metal-001-MCP-L1/SignFromJson.s.sol`.
Thus ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown
(without the full path), something is wrong and the safety checks will not run.

Do NOT yet proceed to the "Execute the Transaction" section.

## State Validations

Please see the instructions for [validation](./VALIDATION.md).

## Execution

At this point you may resume following the execution instructions in the "Execute the Transaction" section of [SINGLE.md](../../../SINGLE.md).
