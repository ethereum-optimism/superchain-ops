# 011 - DeputyPauseModule Installation - OP Mainnet

Status: [EXECUTED](https://etherscan.io/tx/0x5580a50fd248f0d4034f5eb270636202e2d957b84a6975f7bd7b8c72ff541233)

## Objective

Installs the `DeputyPauseModule` into the Optimism Foundation Operations Safe for OP Mainnet.

## Pre-deployments

- `DeputyPauseModule` - `0x62f3972c56733aB078F0764d2414DfCaa99d574c`
  - Deployed at version [`1.0.0-beta.2`](https://github.com/ethereum-optimism/optimism/blob/cf7a37b6b9f46e259b4ecf5c709f465f63a5e0fd/packages/contracts-bedrock/src/safe/DeputyPauseModule.sol#L90).

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/src/improvements/template/EnableDeputyPauseModuleTemplate.sol`.
This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade:

- Installs the `DeputyPauseModule` into the Optimism Foundation Operations Safe that is [deployed here](https://etherscan.io/address/0x126a736b18e0a64fba19d421647a530e327e112c#readContract).
