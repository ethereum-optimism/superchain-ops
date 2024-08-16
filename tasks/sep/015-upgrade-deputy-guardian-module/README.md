# Sepolia Deputy Guardian Module Upgrade

Status: READY TO SIGN

## Objective

Expands the powers of the `DeputyGuardian` via an upgraded `DeputyGuardianModule`.

## Pre-Deployments (TODO)

- `DeputyGuardianModule` - [`x`](https://sepolia.etherscan.io/address/x).

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep/015-upgrade-deputy-guardian-module/SignFromJson.s.sol`.
This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade replaces the current `DeputyGuardianModule` with a new one via a safe transaction to the guardian safe.

The batch will be executed on chain ID `11155111`, and contains `2` transactions.

See the input.json bundle for more details.
