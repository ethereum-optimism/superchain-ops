# Holocene Hardfork - SystemConfig Upgrade
Upgrades the `SystemConfig.sol` contract for Holocene across multiple L2 chains.

The batch will be executed on L1 chain ID `11155111`, and contains  `3n` transactions, where `n=4` is the number of L2 chains being upgraded. The chains affected are {op,metal,mode,zora}-sepolia.

The below is a summary of the transaction bundle, see `input.json` for full details. 

## Txs #1,#4,#7,#10: ProxyAdmin.upgrade(SystemConfigProxy, StorageSetter)
Upgrades the `SystemConfigProxy` on each chain to the StorageSetter.

**Function Signature:** `upgrade(address,address)`

## Txs #2,#5,#8,#11: SystemConfigProxy.setBytes32(0,0)
Zeroes out the initialized state variable for each chain's SystemConfigProxy, to allow reinitialization.

**Function Signature:** `setBytes32(bytes32,bytes32)`

## Tx #3,#6,#9,#12: ProxyAdmin.upgradeAndCall(SystemConfigProxy, SystemConfigImplementation, Initialize())
Upgrades each chain's SystemConfig to a new implementation and initializes it.

**Function Signature:** `upgradeAndCall(address,address,bytes)`
