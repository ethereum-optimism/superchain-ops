# ProxyAdminOwner - Set Dispute Game Implementation

Status: DRAFT, NOT READY TO SIGN

## Objective

This task updates the fault dispute system for Swell Mainnet: 

* Set implementation for game type 0 to 0x2DabFf87A9a634f6c769b983aFBbF4D856aDD0bF in `DisputeGameFactory` 0x87690676786cDc8cCA75A472e483AF7C8F2f0F57: `setImplementation(0, 0x2DabFf87A9a634f6c769b983aFBbF4D856aDD0bF)`
* Set implementation for game type 1 to 0x1380Cc0E11Bfe6b5b399D97995a6B3D158Ed61a6 in `DisputeGameFactory` 0x87690676786cDc8cCA75A472e483AF7C8F2f0F57: `setImplementation(1, 0x1380Cc0E11Bfe6b5b399D97995a6B3D158Ed61a6)`

Additionally, the chain operator is rotating their proposer keys to a new address: `0xA2Acb8142b64fabda103DA19b0075aBB56d29FbD`. The new implementation contracts have been configured to use this new proposer address as part of the upgrade. See [this document](https://alt-research.notion.site/Rotate-proposer-key-for-Swell-mainnet-1cfd3246cc8c806681bbd38d52a0d969) for verification and additional context. 

The proposal was: 
- [x] Posted on the [governance forum](https://gov.optimism.io/t/upgrade-proposal-11-holocene-network-upgrade/9313).
- [x] Approved by Token House voting.
- [x] Not vetoed by the Citizens' house.

## Pre-deployments

- `MIPS` - `0x5fE03a12C1236F9C22Cb6479778DDAa4bce6299C`
- `FaultDisputeGame` - `0x2DabFf87A9a634f6c769b983aFBbF4D856aDD0bF`
- `PermissionedDisputeGame` - `0x1380Cc0E11Bfe6b5b399D97995a6B3D158Ed61a6`

### State Validations

Please see the instructions for [validation](./VALIDATION.md).
