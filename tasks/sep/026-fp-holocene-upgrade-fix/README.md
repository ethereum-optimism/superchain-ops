# Holocene Hardfork Upgrade

Status: READY TO SIGN

## Objective

Upgrades the Fault Proof contracts of **OP Sepolia** for Holocene, fixing an upgrade with wrongly
newly deployed `DelayedWETH` from #374, and then subsequent faulty upgrade to MIPS64-MT in #410,
which again used the wrong `DelayedWETH`.

Using a MIPS64 absolute prestate hash of `0x03b7eaa4e3cbce90381921a4b48008f4769871d64f93d113fcadca08ecee503b`.

Governance post of the upgrade can be found at https://gov.optimism.io/t/upgrade-proposal-11-holocene-network-upgrade/9313.

This upgrades the Fault Proof contracts in the
[op-contracts/v1.8.0-rc.4](https://github.com/ethereum-optimism/optimism/tree/op-contracts/v1.8.0-rc.4) release.

## Pre-deployments

- `MIPS64` - `0xa1e470b6bd25e8eea9ffcda6a1518be5eb8ee7bb`
- `FaultDisputeGame` - `0x833a817eF459f4eCdB83Fc5A4Bf04d09A4e83f3F`
- `PermissionedDisputeGame` - `0xbBD576128f71186A0f9ae2F2AAb4afb4aF2dae17`

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
