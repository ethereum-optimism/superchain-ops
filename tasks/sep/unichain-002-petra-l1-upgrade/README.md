# Unichain Sepolia L1 Petra Support Upgrade

Status: READY TO SIGN

## Objective

This task updates the fault dispute system for unichain-sepolia:

* Set implementation for game type 0 to 0x517AE9d74dbB9c7df6F3277225543BE2DCeD5a87 in DisputeGameFactory 0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b: `setImplementation(0, 0x517AE9d74dbB9c7df6F3277225543BE2DCeD5a87)`
* Set implementation for game type 1 to 0x652f0D5aB7d145C0EdB86a0B4923F2f150a5482f in DisputeGameFactory 0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b: `setImplementation(1, 0x652f0D5aB7d145C0EdB86a0B4923F2f150a5482f)`

The proposal was: 
- [ ] Posted on the governance forum.
- [ ] Approved by Token House voting.
- [ ] Not vetoed by the Citizens' house.
- [ ] Executed on OP Mainnet.

The governance proposal should be treated as the source of truth and used to verify the correctness of the onchain operations. 

This upgrades the Fault Proof contracts in the [op-contracts/v1.8.0-rc.4](https://github.com/ethereum-optimism/optimism/tree/op-contracts/v1.8.0-rc.4) release.


## Pre-deployments 
- `MIPS` - `0x69470D6970Cd2A006b84B1d4d70179c892cFCE01`
- `FaultDisputeGame` - `0x517AE9d74dbB9c7df6F3277225543BE2DCeD5a87`
- `PermissionedDisputeGame` - `0x652f0D5aB7d145C0EdB86a0B4923F2f150a5482f`

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md). 

When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/<path>/SignFromJson.s.sol`. 

This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validations

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade:

* Updates the `DisputeGameFactory` to point to the new `FaultDisputeGame` and `PermissionedDisputeGame` contracts by calling `DisputeGameFactory.setImplementation`

See the [overview](./OVERVIEW.md) and `input.json` bundle for more details.
