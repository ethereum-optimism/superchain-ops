# DeputyPauseModule Installation - OP Sepolia

Status: DRAFT, NOT READY TO SIGN

## Objective

Installs the `DeputyPauseModule` into the Optimism Foundation Operations Safe for OP Sepolia.

## Pre-deployments

- `DeputyPauseModule` - `0x62f3972c56733aB078F0764d2414DfCaa99d574c`

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep/029-deputy-pause-module/SignFromJson.s.sol`.
This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](../base-005-fp-holocene-upgrade/VALIDATION.md).

## Execution

This upgrade:

- Installs the `DeputyPauseModule` into the Optimism Foundation Operations Safe.