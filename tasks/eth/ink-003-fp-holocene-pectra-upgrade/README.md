# Holocene Hardfork Upgrade

Status: DRAFT, NOT READY TO SIGN

## Objective

Upgrades the Fault Proof contracts for the Holocene hardfork.

The proposal was:

- [ ] Posted on the governance forum.
- [ ] Approved by Token House voting.
- [ ] Not vetoed by the Citizens' house.
- [ ] Executed on OP Mainnet.

The governance proposal should be treated as the source of truth and used to verify the correctness of the onchain operations.

Governance post of the upgrade can be found at <placeholder>.

This upgrades the Fault Proof contracts in the
[op-contracts/v1.8.0-rc.4](https://github.com/ethereum-optimism/optimism/tree/op-contracts/v1.8.0-rc.4) release.

## Pre-deployments

- `MIPS` - `0x5fE03a12C1236F9C22Cb6479778DDAa4bce6299C`
- `FaultDisputeGame` - `0xE09185Bbb538d084209EF6f1a92Dc499D313ce51`
- `PermissionedDisputeGame` - `0xf75DA262a580cf9b2EaB9847559c5837381aE3a3`

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
