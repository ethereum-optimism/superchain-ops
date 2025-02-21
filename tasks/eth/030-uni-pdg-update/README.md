# Holocene Hardfork Upgrade - `SystemConfig`

Status: IN REVIEW

## Objective

Upgrades the **Unichain Mainnet** Fault Proof PDG to a new challenger and upgrades the System Config to the Holocene version.

The proposal was:

- [X] [Posted](https://gov.optimism.io/t/upgrade-proposal-11-holocene-network-upgrade/9313) on the governance forum.
- [X] [Approved](https://vote.optimism.io/proposals/20127877429053636874064552098716749508236019236440427814457915785398876262515) by Token House voting.
- [X] Not vetoed by the Citizens' house.

The governance proposal should be treated as the source of truth and used to verify the correctness of the onchain operations.

This upgrades the `SystemConfig` in the [v1.8.0-rc.4](https://github.com/ethereum-optimism/optimism/tree/v1.8.0-rc.4) release.


## Pre-deployments

- `SystemConfig` - `0xAB9d6cB7A427c0765163A7f45BB91cAfe5f2D375`

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops-private/tasks/eth/030-uni-pdg-update/NestedSignFromJson.s.sol`.
This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade
* Sets the `SystemConfigProxy` implementation to the Holocene version & re-initializes it.

See the `input.json` bundle for more details.

## Preparation Notes

The following notes are just for future reference on how this task was prepared.

