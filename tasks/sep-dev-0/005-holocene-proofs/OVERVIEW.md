# Holocene Hardfork - Proof Contract Upgrades

Upgrades the `MIPS.sol`, `FaultDisputeGame.sol`, and `PermissionedDisputeGame.sol` contracts for Holocene.

The batch will be executed on chain ID `11155111`, and contains `2` transactions.

## Tx #1: Upgrade `PERMISSIONED_CANNON` game type in `DisputeGameFactory`

Upgrades the `PERMISSIONED_CANNON` game type to the new Holocene deployment, with an updated version of `op-program` as the absolute prestate hash.

**Function Signature:** `setImplementation(uint32,address)`

**To:** `0x2419423C72998eb1c6c15A235de2f112f8E38efF`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a300000000000000000000000000000000000000000000000000000000000000010000000000000000000000006a962628aa48564b7c48d97e1a738044ffec686f`

### Inputs

**_gameType:** `1`

**_impl:** `0x6A962628Aa48564B7C48D97E1A738044fFEc686F`


## Tx #2: Upgrade `CANNON` game type in `DisputeGameFactory`

Upgrades the `CANNON` game type to the new Holocene deployment, with an updated version of `op-program` as the absolute prestate hash.

**Function Signature:** `setImplementation(uint32,address)`

**To:** `0x2419423C72998eb1c6c15A235de2f112f8E38efF`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e5e89e67f9715ca9e6be0bd7e50ce143d177117b`

### Inputs

**_gameType:** `0`

**_impl:** `0xE5E89e67F9715Ca9e6be0Bd7e50ce143D177117B`

