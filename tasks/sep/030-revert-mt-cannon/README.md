# ProxyAdminOwner - Set Dispute Game Implementation

Status: DRAFT, NOT READY TO SIGN

## Objective

This task updates the fault dispute system for op-sepolia: 

* Set implementation for game type 0 to 0xF3CcF0C4b51D42cFe6073F0278c19A8D1900e856 in `DisputeGameFactory` 0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1: `setImplementation(0, 0xF3CcF0C4b51D42cFe6073F0278c19A8D1900e856)`
* Set implementation for game type 1 to 0xbbDBdfe37C02439764dE0e41C906e4396B5B3914 in `DisputeGameFactory` 0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1: `setImplementation(1, 0xbbDBdfe37C02439764dE0e41C906e4396B5B3914)`
<!--NEXT TASK DESCRIPTION-->

This switches sepolia back to singlethreaded cannon, undoing the upgrade to cannon-mt (025-mt-cannon task)

### State Validations

Please see the instructions for [validation](./VALIDATION.md).
