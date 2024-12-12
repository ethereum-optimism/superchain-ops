# ProxyAdminOwner - Set Dispute Game Implementation

Status: DRAFT, NOT READY TO SIGN

## Objective

This task updates the fault dispute system for ink-mainnet: 

* Re-initialize `AnchorStateRegistry` 0xde744491BcF6b2DD2F32146364Ea1487D75E2509 with the anchor state for game types 0 set to 0x5220f9c5ebf08e84847d542576a67a3077b6fa496235d93c557d5bd5286b431a, 523052
* Set implementation for game type 0 to 0x6A8eFcba5642EB15D743CBB29545BdC44D5Ad8cD in `DisputeGameFactory` 0x10d7B35078d3baabB96Dd45a9143B94be65b12CD: `setImplementation(0, 0x6A8eFcba5642EB15D743CBB29545BdC44D5Ad8cD)`
* Set implementation for game type 1 to 0x0A780bE3eB21117b1bBCD74cf5D7624A3a482963 in `DisputeGameFactory` 0x10d7B35078d3baabB96Dd45a9143B94be65b12CD: `setImplementation(1, 0x0A780bE3eB21117b1bBCD74cf5D7624A3a482963)`
<!--NEXT TASK DESCRIPTION-->

### State Validations

Please see the instructions for [validation](./VALIDATION.md).
