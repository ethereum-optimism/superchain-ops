# DeputyPauseModule Installation - OP Sepolia

Status: READY TO SIGN

## Objective

Installs the `DeputyPauseModule` into the Optimism Foundation Operations Safe for OP Sepolia.

## Pre-deployments

- `DeputyPauseModule` - `0x62f3972c56733aB078F0764d2414DfCaa99d574c`
  - Deployed at version [`1.0.0-beta.2`](https://github.com/ethereum-optimism/optimism/blob/cf7a37b6b9f46e259b4ecf5c709f465f63a5e0fd/packages/contracts-bedrock/src/safe/DeputyPauseModule.sol#L90).

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep/029-deputy-pause-module/SignFromJson.s.sol`.
This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](../029-deputy-pause-module/VALIDATION.md).

## Execution

This upgrade:

- Installs the `DeputyPauseModule` into the Optimism Foundation Operations Safe that is [deployed here](https://sepolia.etherscan.io/address/0x62f3972c56733aB078F0764d2414DfCaa99d574c#code).
