# Holocene Hardfork Upgrade - `SystemConfig`

Status: READY TO SIGN

## Objective

Upgrades the `SystemConfig` for the Holocene hardfork and sets the EIP1559 parameters

- This upgrades the `SystemConfig` in the [v1.8.0-rc.4](https://github.com/ethereum-optimism/optimism/tree/v1.8.0-rc.4) release.

- Unrelated to the Holocene upgrade itself, an additional transaction is included for convenience to adjust the EIP-1559 parameters to `_denominator = 1` and `_elasticity = 4`. While we cannot fully match mainnet in terms of gas throughput, we aim to modify the scaling factor for Sepolia ahead of mainnet. Changing `_elasticity` from `6` (currently hardcoded into the protocol) to `4`, while keeping the `_gasLimit` at 60M, corresponds to a 50% target increase, raising it from 5M to 7.5M, which we are comfortable with.


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
* Initializes the EIP-1559 parameters to `_denominator = 1` and `_elasticity = 4`.

See the `input.json` bundle for more details.
