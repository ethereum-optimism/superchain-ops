# ProxyAdminOwner - Set Dispute Game Implementation

Status: READY TO SIGN

## Objective

This task updates the fault dispute system for ink-mainnet: 

* Re-initialize `AnchorStateRegistry` 0xde744491BcF6b2DD2F32146364Ea1487D75E2509 with the anchor state for game types 0 set to 0x5220f9c5ebf08e84847d542576a67a3077b6fa496235d93c557d5bd5286b431a, 523052
* Set implementation for game type 0 to 0x6A8eFcba5642EB15D743CBB29545BdC44D5Ad8cD in `DisputeGameFactory` 0x10d7B35078d3baabB96Dd45a9143B94be65b12CD: `setImplementation(0, 0x6A8eFcba5642EB15D743CBB29545BdC44D5Ad8cD)`
* Set implementation for game type 1 to 0x0A780bE3eB21117b1bBCD74cf5D7624A3a482963 in `DisputeGameFactory` 0x10d7B35078d3baabB96Dd45a9143B94be65b12CD: `setImplementation(1, 0x0A780bE3eB21117b1bBCD74cf5D7624A3a482963)`
* Sets the initial bonds in the `DisputeGameFactory` for game type 0 and 1 to 0.08 ETH. **Important: the proposer will now need to be bonded for the permissioned games.**

## Pre-deployments

- `FaultDisputeGame` - [0x6A8eFcba5642EB15D743CBB29545BdC44D5Ad8cD](https://etherscan.io/address/0x6A8eFcba5642EB15D743CBB29545BdC44D5Ad8cD)
- `PermissionedDisputeGame` - [0x0A780bE3eB21117b1bBCD74cf5D7624A3a482963](https://etherscan.io/address/0x0A780bE3eB21117b1bBCD74cf5D7624A3a482963)

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).

When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/ink-001-permissionless-proofs/NestedSignFromJson.s.sol`. This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

Do NOT yet proceed to the "Execute the Transaction" section.

## Signing and execution

Please see the signing and execution instructions in [NESTED.md](../../../NESTED.md).

### State Validations

Please see the instructions for [validation](./VALIDATION.md).
