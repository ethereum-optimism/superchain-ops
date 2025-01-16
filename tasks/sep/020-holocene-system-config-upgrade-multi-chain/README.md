# Holocene Hardfork Upgrade - `SystemConfig`

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x88bd1d85740af3741e2ed96d6fd07f2abb4541afc667625480bf6a28451c4d6d)

> ⚠️ **Warning:** This task is incorrect and is superseded by [Task 028](../028-holocene-system-config-upgrade-and-init-multi-chain/)

## Objective

Upgrades the `SystemConfig` for the Holocene hardfork for Sepolia/{OP,Mode,Metal,Zora,Base}.

The proposal was:

- [ ] ~~Posted on the governance forum.~~ (Not applicable, as this is a set of testnet upgrades)
- [ ] ~~Approved by Token House voting.~~ (Not applicable, as this is a set of testnet upgrades)
- [ ] ~~Not vetoed by the Citizens' house.~~ (Not applicable, as this is a set of testnet upgrades)
- [x] Executed on Sepolia.

This upgrades the [`SystemConfig`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.8.0-rc.3/packages/contracts-bedrock/src/L1/SystemConfig.sol) in the
[op-contracts/v1.8.0](https://github.com/ethereum-optimism/optimism/tree/op-contracts/v1.8.0-rc.1) release.

## Pre-deployments

- `SystemConfig` - `0x33b83E4C305c908B2Fc181dDa36e230213058d7d`

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep/020-holocene-system-config-upgrade-multi-chain/NestedSignFromJson.s.sol`.
This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

The SystemConfig L1 contract will get upgraded to version 2.3.0, which is part of the OP Contracts v1.8.0-rc.3 release. The upgrade will happen after the Holocene activation. The upgraded SystemConfig enables chain operators to update the EIP-1559 parameters via a new function setEIP1559Params.

See the `input.json` bundle for more details.
