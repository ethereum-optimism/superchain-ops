# MTCannon Deployment

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x5002821d69ec13dcf913e6f53224141388dd96242b559ff1cc44c3bef46d48ef)

## Objective

Configures new MTCannon DisputeGame implementations on the DisputeGameFactoryProxy.

Contracts upgraded are included within the
[op-contracts/v1.9.0-rc.3](https://github.com/ethereum-optimism/optimism/tree/op-contracts/v1.9.0-rc.3) release.

## Pre-deployments

- `MIPS64`  - [0x2b82752b3809a6b7f1662536af72c519000610e3](https://sepolia.etherscan.io/address/0x2b82752b3809a6b7f1662536af72c519000610e3)
- `FaultDisputeGame`  - [0x030aca4aea0cf48bd53dca03b34e35d05b9635c7](https://sepolia.etherscan.io/address/0x030aca4aea0cf48bd53dca03b34e35d05b9635c7)
- `PermissionedDisputeGame` - [0x4001542871a610a551b11dcaaea52dc5ca6fdb6a](https://sepolia.etherscan.io/address/0x4001542871a610a551b11dcaaea52dc5ca6fdb6a)
- `PermissionedDelayedWETHProxy` - [0x81b05ce22ec8e79078d58df7de44957bd3c93125](https://sepolia.etherscan.io/address/0x81b05ce22ec8e79078d58df7de44957bd3c93125)

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep-dev-0/007-mt-cannon/SignFromJson.s.sol`.
This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade
* Updates `DisputeGameFactoryProxy` game implementations to use Cannon dispute games that run on 64-bit MTCannon:
  * Type 0 (CANNON) implementation is updated to a `FaultDisputeGame` configured with the `MIPS64` vm
  * Type 1 (PERMISSIONED_CANNON) implementation is updated to a `PermissionedDisputeGame` configured with the `MIPS64` vm

See the [overview](./OVERVIEW.md) and `input.json` bundle for more details.
