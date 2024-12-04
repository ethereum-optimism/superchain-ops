# Holocene Hardfork Upgrade - Base Sepolia

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x3ab5ff5700afe57b89d7d23c0ad9e535f38a68b55c571e66c642719d85bcb888)

## Objective

Upgrades the Fault Proof contracts of Base Sepolia for the Holocene hardfork.

This upgrades the Fault Proof contracts in the
[op-contracts/v1.8.0-rc.2](https://github.com/ethereum-optimism/optimism/tree/op-contracts/v1.8.0-rc.2) release.

## Pre-deployments

- `MIPS` - `0x69470D6970Cd2A006b84B1d4d70179c892cFCE01`
- `FaultDisputeGame` - `0xB7fB44a61fdE2b9DB28a84366e168b14D1a1b103`
- `PermissionedDisputeGame` - `0x68f600e592799c16D1b096616eDbf1681FB9c0De`

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep/base-005-fp-holocene-upgrade/SignFromJson.s.sol`.
This ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade
* Changes dispute game implementation of the `CANNON` and `PERMISSIONED_CANNON` game types to contain a `op-program` release for the Holocene hardfork, which contains
  the Holocene fork implementation as well as a `ChainConfig` and `RollupConfig` for the L2 chain being upgraded.
* Upgrades `MIPS.sol` to support the `F_GETFD` syscall, required by the golang 1.22+ runtime.

See the [overview](./OVERVIEW.md) and `input.json` bundle for more details.
