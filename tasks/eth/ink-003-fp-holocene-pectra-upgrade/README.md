# Holocene Hardfork Upgrade
Status: [EXECUTED](https://etherscan.io/tx/0xd80b96282ad4d71aeb29b25e0ceee2bdf0840b258fccffedc951ce0553b6800b)
## Objective

Upgrades the Fault Proof contracts for the Holocene hardfork as per Upgrade Proposal #11.


This also utilizes the absolute prestate `0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9` that enables L1 pectra support, to be included in Upgrade Proposal #12.

The proposal #11 was:

- [X] [Posted](https://gov.optimism.io/t/upgrade-proposal-11-holocene-network-upgrade/9313) on the governance forum.
- [X] [Approved](https://vote.optimism.io/proposals/20127877429053636874064552098716749508236019236440427814457915785398876262515) by Token House voting.
- [X] Not vetoed by the Citizens' house.
- [X] Executed on OP Mainnet.

The proposal #12 was:

- [X] [Posted](https://gov.optimism.io/t/upgrade-proposal-12-l1-pectra-readiness/9706) on the governance forum.
- [x] Posted on the [governance forum](https://gov.optimism.io/t/upgrade-proposal-12-l1-pectra-readiness/9706).
- [x] Approved by [Token House voting](https://vote.optimism.io/proposals/38506287861710446593663598830868940900144818754960277981092485594195671514829).
- [ ] Not vetoed by the Citizens' house.
- [ ] Executed on OP Mainnet.

The governance proposal should be treated as the source of truth and used to verify the correctness of the onchain operations.

This upgrades the Fault Proof contracts in the
[op-contracts/v1.8.0-rc.4](https://github.com/ethereum-optimism/optimism/tree/op-contracts/v1.8.0-rc.4) release.

## Pre-deployments

- `MIPS` - `0x5fE03a12C1236F9C22Cb6479778DDAa4bce6299C`
- `FaultDisputeGame` - `0x7e87B471e96b96955044328242456427A0D49694`
- `PermissionedDisputeGame` - `0x8D9faaEb46cBCf487baf2182E438Ac3D0847F637`

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/tasks/eth/ink-003-fp-holocene-pectra-upgrade/NestedSignFromJson.s.sol

This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade
* Changes dispute game implementation of the `CANNON` and `PERMISSIONED_CANNON` game types to contain a `op-program` release for the Holocene hardfork, which contains
  the Holocene fork implementation as well as a `ChainConfig` and `RollupConfig` for the L2 chain being upgraded.
* Upgrades `MIPS.sol` to support the `F_GETFD` syscall, required by the golang 1.22+ runtime.

See the `input.json` bundle for full details.

The batch will be executed on chain ID `1`, and contains `2` transactions.

## Tx #1: Upgrade `PERMISSIONED_CANNON` game type in `DisputeGameFactory`
Upgrades the `PERMISSIONED_CANNON` game type to the new Holocene deployment, with an updated version of `op-program` as the absolute prestate hash.

**Function Signature:** `setImplementation(uint32,address)`

## Tx #2: Upgrade `CANNON` game type in `DisputeGameFactory`
Upgrades the `CANNON` game type to the new Holocene deployment, with an updated version of `op-program` as the absolute prestate hash.

**Function Signature:** `setImplementation(uint32,address)`
