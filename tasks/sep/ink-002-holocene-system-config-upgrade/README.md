# Holocene Hardfork Upgrade - `SystemConfig`

Status: READY TO SIGN

## Objective

Upgrades the `SystemConfig` for the Holocene hardfork.

The proposal was:

- [x] [Posted](https://gov.optimism.io/t/upgrade-proposal-11-holocene-network-upgrade/9313) on the governance forum.
- [x] [Approved](https://vote.optimism.io/proposals/20127877429053636874064552098716749508236019236440427814457915785398876262515) by Token House voting.
- [x] Not vetoed by the Citizens' house.
- [x] Executed on OP Mainnet.

This upgrades the SystemConfig in the v1.8.0-rc.4 release.

The governance proposal should be treated as the source of truth and used to verify the correctness of the onchain operations.

This upgrades the `SystemConfig` in the
[v1.8.0-rc.4](https://github.com/ethereum-optimism/optimism/tree/v1.8.0-rc.4) release.

## Pre-deployments

- `SystemConfig` - `0x33b83E4C305c908B2Fc181dDa36e230213058d7d`

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/<path>/NestedSignFromJson.s.sol`.
This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade
* Changes the implementation of the `SystemConfig` to hold EIP-1559 parameters for the

See the [overview](./OVERVIEW.md) and `input.json` bundle for more details.
