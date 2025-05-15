# ProxyAdminOwner - Set Dispute Game Implementation

Status: [EXECUTED](https://etherscan.io/tx/0x1ca79cf47edc2fa5d6feb1bfcbb81704d0709900a0fede8314d8b071300a6fee)

## Objective

Upgrades the Fault Proof contracts on Swell Mainnet for the Holocene hardfork as per Upgrade Proposal #11.

This also utilizes the absolute prestate `0x03526dfe02ab00a178e0ab77f7539561aaf5b5e3b46cd3be358f1e501b06d8a9` that enables L1 pectra support, included in Standard Prestates' TOML file as defined in Upgrade Proposal #12.

The proposal #11 was:

- [X] [Posted](https://gov.optimism.io/t/upgrade-proposal-11-holocene-network-upgrade/9313) on the governance forum.
- [X] [Approved](https://vote.optimism.io/proposals/20127877429053636874064552098716749508236019236440427814457915785398876262515) by Token House voting.
- [X] Not vetoed by the Citizens' house.
- [X] Executed on OP Mainnet.

The proposal #12 was:

- [X] [Posted](https://gov.optimism.io/t/upgrade-proposal-12-l1-pectra-readiness/9706) on the governance forum.
- [x] Posted on the [governance forum](https://gov.optimism.io/t/upgrade-proposal-12-l1-pectra-readiness/9706).
- [x] Approved by [Token House voting](https://vote.optimism.io/proposals/38506287861710446593663598830868940900144818754960277981092485594195671514829).
- [x] Not vetoed by the Citizens' house.
- [x] Executed on OP Mainnet.


This upgrade does the following: 
* Set implementation for game type 0 to 0x2DabFf87A9a634f6c769b983aFBbF4D856aDD0bF in `DisputeGameFactory` 0x87690676786cDc8cCA75A472e483AF7C8F2f0F57: `setImplementation(0, 0x2DabFf87A9a634f6c769b983aFBbF4D856aDD0bF)`
* Set implementation for game type 1 to 0x1380Cc0E11Bfe6b5b399D97995a6B3D158Ed61a6 in `DisputeGameFactory` 0x87690676786cDc8cCA75A472e483AF7C8F2f0F57: `setImplementation(1, 0x1380Cc0E11Bfe6b5b399D97995a6B3D158Ed61a6)`
* Additionally, the chain operator is rotating their proposer keys to a new address: `0xA2Acb8142b64fabda103DA19b0075aBB56d29FbD`. The new implementation contracts have been configured to use this new proposer address as part of the upgrade. See [this document](https://alt-research.notion.site/Rotate-proposer-key-for-Swell-mainnet-1cfd3246cc8c806681bbd38d52a0d969) for verification and additional context. 


## Pre-deployments

- `MIPS` - `0x5fE03a12C1236F9C22Cb6479778DDAa4bce6299C`
- `FaultDisputeGame` - `0x2DabFf87A9a634f6c769b983aFBbF4D856aDD0bF`
- `PermissionedDisputeGame` - `0x1380Cc0E11Bfe6b5b399D97995a6B3D158Ed61a6`
- New proposer address - `0xA2Acb8142b64fabda103DA19b0075aBB56d29FbD`

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/tasks/eth/arena-z-001-fp-holocene-upgrade/NestedSignFromJson.s.sol

This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validations

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade
* Changes dispute game implementation of the `CANNON` and `PERMISSIONED_CANNON` game types to contain a `op-program` release for the Holocene hardfork, which contains the Holocene fork implementation as well as a `ChainConfig` and `RollupConfig` for the L2 chain being upgraded.
* Upgrades `MIPS.sol` to support the `F_GETFD` syscall, required by the golang 1.22+ runtime.
* Rotates Swell's proposer keys to a new address: `0xA2Acb8142b64fabda103DA19b0075aBB56d29FbD`. 

See the `input.json` bundle for full details.

The batch will be executed on chain ID `1`, and contains `2` transactions.

## Tx #1: Upgrade `PERMISSIONED_CANNON` game type in `DisputeGameFactory`
Upgrades the `PERMISSIONED_CANNON` game type to the new Holocene deployment, with an updated version of `op-program` as the absolute prestate hash.

**Function Signature:** `setImplementation(uint32,address)`

## Tx #2: Upgrade `CANNON` game type in `DisputeGameFactory`
Upgrades the `CANNON` game type to the new Holocene deployment, with an updated version of `op-program` as the absolute prestate hash.

**Function Signature:** `setImplementation(uint32,address)`