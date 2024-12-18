# ProxyAdminOwner - Set Dispute Game Implementation

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0xde172a001139a891ad47146db60cfaeccde119ecc0972935e2dbd661540ffc31)

## Objective

This task updates the fault dispute system for op-sepolia: 

* Set implementation for game type 0 to 0x924D3d3B3b16E74bAb577e50d23b2a38990dD52C in `DisputeGameFactory` 0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1: `setImplementation(0, 0x924D3d3B3b16E74bAb577e50d23b2a38990dD52C)`
* Set implementation for game type 1 to 0x879e899523bA9a4Ab212a2d70cF1af73B906CbE5 in `DisputeGameFactory` 0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1: `setImplementation(1, 0x879e899523bA9a4Ab212a2d70cF1af73B906CbE5)`

Contracts upgraded are included within the
[op-contracts/v1.9.0-rc.3](https://github.com/ethereum-optimism/optimism/tree/op-contracts/v1.9.0-rc.3) release.

## Pre-deployments

- `MIPS64`  - [0xa1e470b6bd25e8eea9ffcda6a1518be5eb8ee7bb](https://sepolia.etherscan.io/address/0xa1e470b6bd25e8eea9ffcda6a1518be5eb8ee7bb)
- `FaultDisputeGame`  - [0x924d3d3b3b16e74bab577e50d23b2a38990dd52c](https://sepolia.etherscan.io/address/0x924d3d3b3b16e74bab577e50d23b2a38990dd52c)
- `PermissionedDisputeGame` - [0x879e899523bA9a4Ab212a2d70cF1af73B906CbE5](https://sepolia.etherscan.io/address/0x879e899523bA9a4Ab212a2d70cF1af73B906CbE5)
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