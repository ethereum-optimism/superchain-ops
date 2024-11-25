# Holocene Hardfork Upgrade - OP Sepolia

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x88b0adbcb78aa77d86b0c7d02305a4e8dfcef5d50adb340c2dcd714f3678b2e0)

## Objective

Upgrades the Fault Proof contracts of OP Sepolia for the Holocene hardfork.

The proposal is soon posted to the governance forum. This is just the testnet upgrade.

This upgrades the Fault Proof contracts in the
[op-contracts/v1.8.0-rc.2](https://github.com/ethereum-optimism/optimism/tree/op-contracts/v1.8.0-rc.2) release.

## Pre-deployments

- `MIPS` - `0x69470D6970Cd2A006b84B1d4d70179c892cFCE01`
- `FaultDisputeGame` - `0x5e0877a8F6692eD470013e651c4357d0C4941e6C`
- `PermissionedDisputeGame` - `0x4Ed046e66c96600DaE1a4ec39267bB0cE476E8cc`

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/<path>/NestedSignFromJson.s.sol`.
This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade
* Changes dispute game implementation of the `CANNON` and `PERMISSIONED_CANNON` game types to contain a `op-program` release for the Holocene hardfork, which contains
  the Holocene fork implementation as well as a `ChainConfig` and `RollupConfig` for the L2 chain being upgraded.
* Upgrades `MIPS.sol` to support the `F_GETFD` syscall, required by the golang 1.22+ runtime.

See the [overview](./OVERVIEW.md) and `input.json` bundle for more details.
