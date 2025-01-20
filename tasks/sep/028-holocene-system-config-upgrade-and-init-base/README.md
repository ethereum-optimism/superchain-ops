# Holocene Hardfork Upgrade - `SystemConfig`

Status: DRAFT, NOT READY TO SIGN

## Objective

Upgrades the `SystemConfig` for the Holocene hardfork.

This upgrades the `SystemConfig` in the
[v1.8.0-rc.4](https://github.com/ethereum-optimism/optimism/tree/v1.8.0-rc.4) release.

## Pre-deployments

- `SystemConfig` - `0x33b83E4C305c908B2Fc181dDa36e230213058d7d`

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep/028-holocene-system-config-upgrade-and-init-base/SignFrom.s.sol`.
This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade
* Changes the implementation of the `SystemConfig` to hold EIP-1559 parameters.

See the [overview](./OVERVIEW.md) and `input.json` bundle for more details.
