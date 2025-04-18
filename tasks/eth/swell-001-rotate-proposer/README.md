# ProxyAdminOwner - Set Dispute Game Implementation

Status: READY TO SIGN

## Objective

This task updates the PermissionedDisputeGame implementation contract for Swell Mainnet. 
This new implementation contracts has a new proposer addresses that the chain operator would like to rotate their keys to.
All other parameters on the new PermissionedDisputeGame, will match the implementation that is currently in use.

* Set implementation for game type 1 to 0x152f31030b63577096dd7abe6b096ee3fd29f5e8 in `DisputeGameFactory` 0x87690676786cDc8cCA75A472e483AF7C8F2f0F57: `setImplementation(1, 0x152f31030b63577096dd7abe6b096ee3fd29f5e8)`

## Pre-deployments

- `PermissionedDisputeGame` - [0x152f31030b63577096dd7abe6b096ee3fd29f5e8](https://etherscan.io/address/0x152f31030b63577096dd7abe6b096ee3fd29f5e8)

Information on how this contract was deployed can be found [here](https://alt-research.notion.site/Rotate-proposer-key-for-Swell-mainnet-1cfd3246cc8c806681bbd38d52a0d969).

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).

When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/swell-001-rotate-proposer/NestedSignFromJson.s.sol`. This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

Do NOT yet proceed to the "Execute the Transaction" section.

## Signing and execution

Please see the signing and execution instructions in [NESTED.md](../../../NESTED.md).

### State Validations

Please see the instructions for [validation](./VALIDATION.md).
