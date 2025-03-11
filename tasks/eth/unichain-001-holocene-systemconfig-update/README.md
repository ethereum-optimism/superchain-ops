# Holocene Hardfork Upgrade - `SystemConfig`

Status: READY TO SIGN

## Objective

Upgrades **Unichain Mainnet** System Config to the Holocene version. In addition to upgrading the standard SystemConfig contract, this upgrade also adjusts the (blob) base fee scalar value in the SystemConfig contract to match what is used on L2 already. See the [validation file](./VALIDATION.md). for more details. 

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

The batch will be executed on chain ID `1`, and contains `3` transactions.

### Tx #1: ProxyAdmin.upgrade(SystemConfigProxy, StorageSetter)

Upgrades the `SystemConfigProxy`to the StorageSetter.

**Function Signature:** `upgrade(address,address)`

### Tx #2: SystemConfigProxy.setBytes32(0,0)

Zeroes out the initialized state variable to allow reinitialization.

**Function Signature:** `setBytes32(bytes32,bytes32)`

#### Tx #3: ProxyAdmin.upgradeAndCall(SystemConfigProxy, SystemConfigImplementation, Initialize())

Upgrades the SystemConfig to a new implementation and initializes it.

**Function Signature:** `upgradeAndCall(address,address,bytes)`

## Preparation Notes

The following notes are just for future reference on how this task was prepared.

