# Holocene Hardfork Upgrade - `SystemConfig`

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x8ec2a7079e14e0c5b66eac0d05613cb5e84b78b872bbcc611d0f5cbe0548e90c)

## Objective

Upgrades the `SystemConfig` contracts for the Holocene hardfork across multiple chains in the sepolia superchain.

This upgrades the `SystemConfig` in the
[v1.8.0-rc.4](https://github.com/ethereum-optimism/optimism/tree/v1.8.0-rc.4) release.

## Pre-deployments

- `SystemConfig` - `0x33b83E4C305c908B2Fc181dDa36e230213058d7d`

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [NESTED.md](../../../NESTED.md).
When simulating, ensure the logs say `Using script /your/path/to/superchain-ops/tasks/sep/028-holocene-system-config-upgrade-and-init-multi-chain/NestedSignFromJson.s.sol`.
This ensures all safety checks are run. If the default `NestedSignFromJson.s.sol` script is shown (without the full path), something is wrong and the safety checks will not run.

## State Validation

Please see the instructions for [validation](./VALIDATION.md).

## Execution

This upgrade upgrades the implementation of the `SystemConfig` implementation on multiple chains and reinitializes each of the in such a way as to preserve the semantics of all existing parameters stored in that contract.

The batch will be executed on L1 chain ID `11155111`, and contains  `3n` transactions, where `n=4` is the number of L2 chains being upgraded. The chains affected are {op,metal,mode,zora}-sepolia.

The below is a summary of the transaction bundle, see `input.json` for full details. 

### Txs #1,#4,#7,#10: ProxyAdmin.upgrade(SystemConfigProxy, StorageSetter)
Upgrades the `SystemConfigProxy` on each chain to the StorageSetter.

**Function Signature:** `upgrade(address,address)`

## Txs #2,#5,#8,#11: SystemConfigProxy.setBytes32(0,0)
Zeroes out the initialized state variable for each chain's SystemConfigProxy, to allow reinitialization.

**Function Signature:** `setBytes32(bytes32,bytes32)`

### Txs #3,#6,#9,#12: ProxyAdmin.upgradeAndCall(SystemConfigProxy, SystemConfigImplementation, Initialize())
Upgrades each chain's SystemConfig to a new implementation and initializes it.

**Function Signature:** `upgradeAndCall(address,address,bytes)`
