# Holocene Hardfork - Proof Contract Upgrades
Upgrades the `MIPS.sol`, `FaultDisputeGame.sol`, and `PermissionedDisputeGame.sol` contracts for Holocene.

The batch will be executed on chain ID `1`, and contains `2` transactions.

## Tx #1: Upgrade `PERMISSIONED_CANNON` game type in `DisputeGameFactory`
Upgrades the `PERMISSIONED_CANNON` game type to the new Holocene deployment, with an updated version of `op-program` as the absolute prestate hash.

**Function Signature:** `setImplementation(uint32,address)`

**To:** `0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a30000000000000000000000000000000000000000000000000000000000000001000000000000000000000000683b566da8815e9fcd22d47f40b4ff0af6c14836`

### Inputs
**_gameType:** `1`

**_impl:** `0x683B566DA8815e9FCD22D47f40B4ff0aF6c14836`


## Tx #2: Upgrade `CANNON` game type in `DisputeGameFactory`
Upgrades the `CANNON` game type to the new Holocene deployment, with an updated version of `op-program` as the absolute prestate hash.

**Function Signature:** `setImplementation(uint32,address)`

**To:** `0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a300000000000000000000000000000000000000000000000000000000000000000000000000000000000000007d0fe73fe6260569bfd9a44e0fc053a24cf0cc9b`

### Inputs
**_gameType:** `0`

**_impl:** `0x7D0fE73fe6260569BFD9a44e0fC053a24cF0cc9B`

