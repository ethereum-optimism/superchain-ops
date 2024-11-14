# Holocene Hardfork - Proof Contract Upgrades

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0xabdc7a65709c9d15b2b7b7e346ccd71b3be3d6abab665ba7f2d3a448be25033d)

## Objective

Upgrades the `FaultDisputeGame`, `PermissionedDisputeGame`, and `MIPS` contracts for the Holocene hardfork.

Contracts upgraded are included within the
[op-contracts/v1.8.0-rc.1](https://github.com/ethereum-optimism/optimism/tree/op-contracts/v1.8.0-rc.1) release.

## Pre-deployments

- `MIPS` - `0x6f86b56d26F60a86Ccd13048993C1cE410565DC1`
- `FaultDisputeGame` - `0xE5E89e67F9715Ca9e6be0Bd7e50ce143D177117B`
- `PermissionedDisputeGame` - `0x6A962628Aa48564B7C48D97E1A738044fFEc686F`

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep-dev-0/005-holocene-proofs/SignFromJson.s.sol`.
This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade
* Changes dispute game implementation of the `CANNON` and `PERMISSIONED_CANNON` game types to contain a `op-program` release for the Holocene hardfork, which contains
  the Holocene fork implementation as well as a `ChainConfig` and `RollupConfig` for the L2 chain being upgraded.
* Upgrades `MIPS.sol` to support the `F_GETFD` syscall, required by the golang 1.22+ runtime.

See the [overview](./OVERVIEW.md) and `input.json` bundle for more details.
