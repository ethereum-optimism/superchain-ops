# Holocene Hardfork - Contract Upgrades

Upgrades the `SystemConfig.sol`, `MIPS.sol`, `FaultDisputeGame.sol`, and `PermissionedDisputeGame.sol` contracts for Holocene.

The batch will be executed on chain ID `11155111`, and contains `3` transactions.

## Tx #1: Upgrade `SystemConfig` proxy

Upgrades the `SystemConfig` proxy to the new implementation, featuring configurable EIP-1559 parameters.

**Function Signature:** `upgrade(address,address)`

**To:** `0x18d890A46A3556e7F36f28C79F6157BC7a59f867`

**Value:** `0 WEI`

**Raw Input Data:** `0x99a88ec4000000000000000000000000a6b72407e2dc9ebf84b839b69a24c88929cf20f700000000000000000000000029d06ed7105c7552efd9f29f3e0d250e5df412cd`

### Inputs
**_proxy:** `0xa6b72407e2dc9EBF84b839B69A24C88929cf20F7`

**_implementation:** `0x29d06Ed7105c7552EFD9f29f3e0d250e5df412CD`


## Tx #2: Upgrade `PERMISSIONED_CANNON` game type in `DisputeGameFactory`

Upgrades the `PERMISSIONED_CANNON` game type to the new Holocene deployment, with an updated version of `op-program` as the absolute prestate hash.

**Function Signature:** `setImplementation(uint32,address)`

**To:** `0x2419423C72998eb1c6c15A235de2f112f8E38efF`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a300000000000000000000000000000000000000000000000000000000000000010000000000000000000000006a962628aa48564b7c48d97e1a738044ffec686f`

### Inputs

**_impl:** `0x6A962628Aa48564B7C48D97E1A738044fFEc686F`

**_gameType:** `1`


## Tx #3: Upgrade `CANNON` game type in `DisputeGameFactory`

Upgrades the `CANNON` game type to the new Holocene deployment, with an updated version of `op-program` as the absolute prestate hash.

**Function Signature:** `setImplementation(uint32,address)`

**To:** `0x2419423C72998eb1c6c15A235de2f112f8E38efF`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e5e89e67f9715ca9e6be0bd7e50ce143d177117b`

### Inputs
**_impl:** `0xE5E89e67F9715Ca9e6be0Bd7e50ce143D177117B`

**_gameType:** `0`

