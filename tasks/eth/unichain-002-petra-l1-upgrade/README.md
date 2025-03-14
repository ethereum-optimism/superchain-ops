# Unichain Mainnet L1 Petra Support Upgrade

Status: DRAFT, NOT READY TO SIGN

## Objective

This task updates the fault dispute system for unichain-mainnet: 

* Set implementation for game type 0 to 0x77034d8F7C0c9B01065514b15ba8b2F13AbE5e43 in `DisputeGameFactory` 0x2F12d621a16e2d3285929C9996f478508951dFe4: `setImplementation(0, 0x77034d8F7C0c9B01065514b15ba8b2F13AbE5e43)`
* Set implementation for game type 1 to 0x9D254e2b925516bD201d726189dfd0eeA6786c58 in `DisputeGameFactory` 0x2F12d621a16e2d3285929C9996f478508951dFe4: `setImplementation(1, 0x9D254e2b925516bD201d726189dfd0eeA6786c58)`

The proposal was: 
- [x] Posted on the [governance forum](https://gov.optimism.io/t/upgrade-proposal-12-l1-pectra-readiness/9706).
- [x] Approved by [Token House voting](https://vote.optimism.io/proposals/38506287861710446593663598830868940900144818754960277981092485594195671514829).
- [x] Not vetoed by the Citizens' house.
- [ ] Executed on OP Mainnet.

The governance proposal should be treated as the source of truth and used to verify the correctness of the onchain operations. 

This upgrades the Fault Proof contracts in the [op-contracts/v1.8.0-rc.4](https://github.com/ethereum-optimism/optimism/tree/op-contracts/v1.8.0-rc.4) release.



## Pre-deployments 
- `MIPS` - `0x5fE03a12C1236F9C22Cb6479778DDAa4bce6299C`
- `FaultDisputeGame` - `0x77034d8F7C0c9B01065514b15ba8b2F13AbE5e43`
- `PermissionedDisputeGame` - `0x9D254e2b925516bD201d726189dfd0eeA6786c58`

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md). 

When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/eth/unichain-002-petra-l1-upgrade/NestedSignFromJson.s.sol`. 

This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.


### State Validations

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade:

* Updates the `DisputeGameFactory` to point to the new `FaultDisputeGame` and `PermissionedDisputeGame` contracts by calling `DisputeGameFactory.setImplementation`

See the `input.json` for the bundle transaction and more details.