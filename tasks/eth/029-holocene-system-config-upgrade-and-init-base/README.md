# Holocene Hardfork Upgrade - `SystemConfig`

Status: DRAFT, NOT READY TO SIGN

## Objective

Upgrades the `SystemConfig` for the Holocene hardfork and sets the EIP1559 parameters

- This upgrades the `SystemConfig` in the
[v1.8.0-rc.4](https://github.com/ethereum-optimism/optimism/tree/v1.8.0-rc.4) release.

- Unrelated to the Holocene upgrade itself, an additional transaction is included for convenience to adjust the EIP-1559 parameters to `_denominator = 1` and `_elasticity = 4`.

## Pre-deployments

- `SystemConfig` - `0xAB9d6cB7A427c0765163A7f45BB91cAfe5f2D375`

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/eth/029-holocene-system-config-upgrade-and-init-base/NestedSignFromJson.s.sol`.
This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade
* Changes the implementation of the `SystemConfig` to hold EIP-1559 parameters.
* Initializes the EIP-1559 parameters to `_denominator = 1` and `_elasticity = 4`.

See the `input.json` bundle for more details.
