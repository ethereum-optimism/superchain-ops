# Holocene Hardfork Upgrade

Status: [EXECUTED](https://etherscan.io/tx/0x470902836f69cbd6eb541c310d5f2858d581d996643c883f39a0266c331e4905)

## Objective

Upgrades the Fault Proof contracts for the Holocene hardfork as per Upgrade Proposal #11.

This also utilizes the absolute prestate `0x03526dfe02ab00a178e0ab77f7539561aaf5b5e3b46cd3be358f1e501b06d8a9` that enables L1 pectra support, included in Standard Prestates' TOML file as defined in Upgrade Proposal #12.

The proposal #11 was:

- [x] [Posted](https://gov.optimism.io/t/upgrade-proposal-11-holocene-network-upgrade/9313) on the governance forum.
- [x] [Approved](https://vote.optimism.io/proposals/20127877429053636874064552098716749508236019236440427814457915785398876262515) by Token House voting.
- [x] Not vetoed by the Citizens' house.
- [x] Executed on OP Mainnet.

The proposal #12 was:

- [x] [Posted](https://gov.optimism.io/t/upgrade-proposal-12-l1-pectra-readiness/9706) on the governance forum.
- [x] Posted on the [governance forum](https://gov.optimism.io/t/upgrade-proposal-12-l1-pectra-readiness/9706).
- [x] Approved by [Token House voting](https://vote.optimism.io/proposals/38506287861710446593663598830868940900144818754960277981092485594195671514829).
- [x] Not vetoed by the [Citizens house](https://snapshot.box/#/s:citizenshouse.eth/proposal/0x27f06b093b34f8a8b7a23175343b051c39de4ec4726389bfcc905c14d340d936)
- [ ] Executed on OP Mainnet.

The governance proposal should be treated as the source of truth and used to verify the correctness of the onchain operations.

This upgrades the Fault Proof contracts in the
[op-contracts/v1.8.0-rc.4](https://github.com/ethereum-optimism/optimism/tree/op-contracts/v1.8.0-rc.4) release.

## Pre-deployments

- `MIPS` - `0x5fE03a12C1236F9C22Cb6479778DDAa4bce6299C`
- `FaultDisputeGame` - `0x733a80Ce3bAec1f27869b6e4C8bc0E358C121045`
- `PermissionedDisputeGame` - `0x80533687a66A1bB366094A9B622873a6CA8415a5`

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/tasks/eth/arena-z-001-fp-holocene-upgrade/NestedSignFromJson.s.sol

This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade

- Changes dispute game implementation of the `CANNON` and `PERMISSIONED_CANNON` game types to contain a `op-program` release for the Holocene hardfork, which contains
  the Holocene fork implementation as well as a `ChainConfig` and `RollupConfig` for the L2 chain being upgraded.
- Upgrades `MIPS.sol` to support the `F_GETFD` syscall, required by the golang 1.22+ runtime.

See the `input.json` bundle for full details.

The batch will be executed on chain ID `1`, and contains `2` transactions.

## Tx #1: Upgrade `PERMISSIONED_CANNON` game type in `DisputeGameFactory`

Upgrades the `PERMISSIONED_CANNON` game type to the new Holocene deployment, with an updated version of `op-program` as the absolute prestate hash.

**Function Signature:** `setImplementation(uint32,address)`

## Tx #2: Upgrade `CANNON` game type in `DisputeGameFactory`

Upgrades the `CANNON` game type to the new Holocene deployment, with an updated version of `op-program` as the absolute prestate hash.

**Function Signature:** `setImplementation(uint32,address)`
