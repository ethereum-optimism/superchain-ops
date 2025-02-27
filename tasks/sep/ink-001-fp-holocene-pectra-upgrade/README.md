# Ink Sepolia Holocene Hardfork + L1 Pectra Support Upgrade

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0xc79c08b4f417db62e1cf7561352ae2b9cd123e4573a1a4b6b62dcbb0ae5049de)

## Objective

Upgrades the Fault Proof contracts for the Holocene hardfork as per Upgrade Proposal #11.

This also utilizes the absolute prestate `0x035ac388b5cb22acf52a2063cfde108d09b1888655d21f02f595f9c3ea6cbdcd` that enables L1 pectra support, to be included in Upgrade Proposal #12.

The proposal #11 was:

- [X] [Posted](https://gov.optimism.io/t/upgrade-proposal-11-holocene-network-upgrade/9313) on the governance forum.
- [X] [Approved](https://vote.optimism.io/proposals/20127877429053636874064552098716749508236019236440427814457915785398876262515) by Token House voting.
- [X] Not vetoed by the Citizens' house.
- [X] Executed on OP Mainnet.

The governance proposal should be treated as the source of truth and used to verify the correctness of the onchain operations.

This upgrades the Fault Proof contracts in the
[op-contracts/v1.8.0-rc.4](https://github.com/ethereum-optimism/optimism/tree/op-contracts/v1.8.0-rc.4) release.

## Pre-deployments

- `MIPS` - `0x69470D6970Cd2A006b84B1d4d70179c892cFCE01`
- `FaultDisputeGame` - `0x323d727A1a147869cEC0C02dE1d4195d1b71F2eB`
- `PermissionedDisputeGame` - `0x39228E51A12662d78DE478BFa1930fc7595337D8`

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

See the `input.json` bundle for full details.

The batch will be executed on chain ID `11155111`, and contains `2` transactions.

## Tx #1: Upgrade `PERMISSIONED_CANNON` game type in `DisputeGameFactory`
Upgrades the `PERMISSIONED_CANNON` game type to the new Holocene deployment, with an updated version of `op-program` as the absolute prestate hash.

**Function Signature:** `setImplementation(uint32,address)`

## Tx #2: Upgrade `CANNON` game type in `DisputeGameFactory`
Upgrades the `CANNON` game type to the new Holocene deployment, with an updated version of `op-program` as the absolute prestate hash.

**Function Signature:** `setImplementation(uint32,address)`
