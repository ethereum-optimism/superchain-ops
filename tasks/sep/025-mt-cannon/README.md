# ProxyAdminOwner - Set Dispute Game Implementation

Status: DRAFT, NOT READY TO SIGN

## Objective

This task updates the fault dispute system for op-sepolia: 

* Set implementation for game type 0 to 0xd5016c6eb023fa1379f7b5777e5654d5edef20aa in `DisputeGameFactory` 0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1: `setImplementation(0, 0xd5016c6eb023fa1379f7b5777e5654d5edef20aa)`
* Set implementation for game type 1 to 0x4604A5cdD9f448F22401bFaB06A5157F053BE7cb in `DisputeGameFactory` 0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1: `setImplementation(1, 0x4604A5cdD9f448F22401bFaB06A5157F053BE7cb)`

Contracts upgraded are included within the
[op-contracts/v1.9.0-rc.3](https://github.com/ethereum-optimism/optimism/tree/op-contracts/v1.9.0-rc.3) release.

## Pre-deployments

- `MIPS64`  - [0xa1e470b6bd25e8eea9ffcda6a1518be5eb8ee7bb](https://sepolia.etherscan.io/address/0xa1e470b6bd25e8eea9ffcda6a1518be5eb8ee7bb)
- `FaultDisputeGame`  - [0xd5016c6eb023fa1379f7b5777e5654d5edef20aa](https://sepolia.etherscan.io/address/0xd5016c6eb023fa1379f7b5777e5654d5edef20aa)
- `PermissionedDisputeGame` - [0x4604a5cdd9f448f22401bfab06a5157f053be7cb](https://sepolia.etherscan.io/address/0x4604a5cdd9f448f22401bfab06a5157f053be7cb)

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/<path>/NestedSignFromJson.s.sol`.
This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

### State Validations

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade
* Updates `DisputeGameFactoryProxy` game implementations to use dispute games that run on 64-bit MTCannon:
    * Type 0 (CANNON) implementation is updated to a `FaultDisputeGame` configured with the `MIPS64` vm
    * Type 1 (PERMISSIONED_CANNON) implementation is updated to a `PermissionedDisputeGame` configured with the `MIPS64` vm

See the [overview](./OVERVIEW.md) and `input.json` bundle for more details.