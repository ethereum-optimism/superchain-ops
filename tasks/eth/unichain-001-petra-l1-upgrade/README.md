# Unichain Mainnet L1 Petra Support Upgrade

Status: DRAFT, NOT READY TO SIGN

## Objective

This task updates the fault dispute system for unichain-mainnet: 

* Set implementation for game type 0 to 0x171dE4f3ea4fBbf233aA9649dCf1b1d6fD70f542 in `DisputeGameFactory` 0x2F12d621a16e2d3285929C9996f478508951dFe4: `setImplementation(0, 0x171dE4f3ea4fBbf233aA9649dCf1b1d6fD70f542)`
* Set implementation for game type 1 to 0x3aFdc7cCF8a1c0d351E3E5F220AF056ea2c07733 in `DisputeGameFactory` 0x2F12d621a16e2d3285929C9996f478508951dFe4: `setImplementation(1, 0x3aFdc7cCF8a1c0d351E3E5F220AF056ea2c07733)`
<!--NEXT TASK DESCRIPTION-->
The proposal was: 
- [ ] Posted on the governance forum.
- [ ] Approved by Token House voting.
- [ ] Not vetoed by the Citizens' house.
- [ ] Executed on OP Mainnet.

The governance proposal should be treated as the source of truth and used to verify the correctness of the onchain operations. 

This upgrades the Fault Proof contracts in the [op-contracts/v1.8.0-rc.4](https://github.com/ethereum-optimism/optimism/tree/op-contracts/v1.8.0-rc.4) release.



## Pre-deployments 
- `MIPS` - `0x5fE03a12C1236F9C22Cb6479778DDAa4bce6299C`
- `FaultDisputeGame` - `0x171dE4f3ea4fBbf233aA9649dCf1b1d6fD70f542`
- `PermissionedDisputeGame` - `0x3aFdc7cCF8a1c0d351E3E5F220AF056ea2c07733`

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md). 

When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/<path>/NestedSignFromJson.s.sol`. 

This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.


### State Validations

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade:

* Updates the `DisputeGameFactory` to point to the new `FaultDisputeGame` and `PermissionedDisputeGame` contracts by calling `DisputeGameFactory.setImplementation`

See the [overview](./OVERVIEW.md) and `input.json` bundle for more details.