# Holocene Hardfork Upgrade

Status: READY TO SIGN

## Objective

Upgrades the Fault Proof contracts of **OP Sepolia** for Holocene, fixing an upgrade with wrongly newly deployed `DelayedWETH` from #374.

Governance post of the upgrade can be found at https://gov.optimism.io/t/upgrade-proposal-11-holocene-network-upgrade/9313.

This upgrades the Fault Proof contracts in the
[op-contracts/v1.8.0-rc.4](https://github.com/ethereum-optimism/optimism/tree/op-contracts/v1.8.0-rc.4) release.

## Pre-deployments

- `MIPS` - `0x69470D6970Cd2A006b84B1d4d70179c892cFCE01`
- `FaultDisputeGame` - `0xe591Ebbc2Ba0EAd3db6a0867cC132Fe1c123F448`
- `PermissionedDisputeGame` - `0xb51baD2d9Da9f94d6A4A5A493Ae6469005611B68`

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep/025-fp-holocene-upgrade-fix/NestedSignFromJson.s.sol`.
This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade
* Changes dispute game implementation of the `CANNON` and `PERMISSIONED_CANNON` game types to contain a `op-program` release for the Holocene hardfork, which contains
  the Holocene fork implementation as well as a `ChainConfig` and `RollupConfig` for the L2 chain being upgraded.
* Upgrades `MIPS.sol` to support the `F_GETFD` syscall, required by the golang 1.22+ runtime.

See the [overview](./OVERVIEW.md) and `input.json` bundle for more details.
