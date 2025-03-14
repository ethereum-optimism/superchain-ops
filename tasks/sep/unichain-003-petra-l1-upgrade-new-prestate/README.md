# Unichain Sepolia L1 Petra Support Upgrade

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x93f183be38337a31ffcfb2c714930f131225b389bad4bf40dbd6c2e7adcf9543)

## Objective

This task updates the fault dispute system for unichain-sepolia: 

* Set implementation for game type 0 to 0x1Ca07eBBEd295C581c952Be0eB23E636aed9a2d0 in `DisputeGameFactory` 0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b: `setImplementation(0, 0x1Ca07eBBEd295C581c952Be0eB23E636aed9a2d0)`
* Set implementation for game type 1 to 0x98b3cEA8dc27f83a6b8384F25A8eca52613A7182 in `DisputeGameFactory` 0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b: `setImplementation(1, 0x98b3cEA8dc27f83a6b8384F25A8eca52613A7182)`
  
The proposal was: 
- [ ] Posted on the governance forum - NOT NECESSARY ON SEPOLIA TASK
- [ ] Approved by Token House voting. - NOT NECESSARY ON SEPOLIA TASK
- [ ] Not vetoed by the Citizens' house. - NOT NECESSARY ON SEPOLIA TASK
- [ ] Executed on Sepolia.

The governance proposal should be treated as the source of truth and used to verify the correctness of the onchain operations. 

This upgrades the Fault Proof contracts in the [op-contracts/v1.8.0-rc.4](https://github.com/ethereum-optimism/optimism/tree/op-contracts/v1.8.0-rc.4) release.


## Pre-deployments 
- `MIPS` - `0x69470D6970Cd2A006b84B1d4d70179c892cFCE01`
- `FaultDisputeGame` - `0x1Ca07eBBEd295C581c952Be0eB23E636aed9a2d0`
- `PermissionedDisputeGame` - `0x98b3cEA8dc27f83a6b8384F25A8eca52613A7182`

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md). 

When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep/unichain-003-petra-l1-upgrade-new-prestate/SignFromJson.s.sol`. 

This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validations

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade:

* Updates the `DisputeGameFactory` to point to the new `FaultDisputeGame` and `PermissionedDisputeGame` contracts by calling `DisputeGameFactory.setImplementation`
