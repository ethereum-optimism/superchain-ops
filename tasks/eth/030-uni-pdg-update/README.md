# Holocene Hardfork Upgrade

Status: DRAFT, NOT READY TO SIGN

## Objective

Upgrades the **Unichain Mainnet** Fault Proof PDG to a new challenger and upgrades the System Config to the Holocene version.

The proposal was:

- [X] [Posted](https://gov.optimism.io/t/upgrade-proposal-11-holocene-network-upgrade/9313) on the governance forum.
- [X] [Approved](https://vote.optimism.io/proposals/20127877429053636874064552098716749508236019236440427814457915785398876262515) by Token House voting.
- [X] Not vetoed by the Citizens' house.

The governance proposal should be treated as the source of truth and used to verify the correctness of the onchain operations.

This upgrades the Fault Proof contracts in the
[op-contracts/v1.8.0](https://github.com/ethereum-optimism/optimism/releases/tag/op-contracts%2fv1.8.0) release.

This upgrade uses a custom absolute prestate created by Unichain that is not part of an official release yet:
`0x0336751a224445089ba5456c8028376a0faf2bafa81d35f43fab8730258cdf37`.

The `PermissionedDisputeGame` is redeployed with a new challenger, a 1of2 with the [Optimism Foundation challenger](https://github.com/ethereum-optimism/superchain-registry/blob/c08331ab44a3645608c08d8c94f78d9be46c13c9/validation/standard/standard-config-roles-mainnet.toml#L7) `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A` and another signer.


## Pre-deployments

- `PermissionedDisputeGame` - `TODO`
- `Challenger1of2` - `TODO`
- `SystemConfig` - `TODO`

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/eth/026-uni-holocene-fp-upgrade/NestedSignFromJson.s.sol`.
This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade
* Changes dispute game implementation of the `PERMISSIONED_CANNON` game types to update the challenger.
* Sets the `SystemConfigProxy` implementation to the Holocene version & re-initializes it.

See the `input.json` bundle for more details.

## Preparation Notes

The following notes are just for future reference on how this task was prepared.

