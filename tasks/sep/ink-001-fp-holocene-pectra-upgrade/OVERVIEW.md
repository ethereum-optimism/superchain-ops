# Holocene Hardfork - Proof Contract Upgrades
Upgrades the `MIPS.sol`, `FaultDisputeGame.sol`, and `PermissionedDisputeGame.sol` contracts for Holocene.

The batch will be executed on chain ID `11155111`, and contains `2` transactions.

## Tx #1: Upgrade `PERMISSIONED_CANNON` game type in `DisputeGameFactory`
Upgrades the `PERMISSIONED_CANNON` game type to the new Holocene deployment, with an updated version of `op-program` as the absolute prestate hash.

**Function Signature:** `setImplementation(uint32,address)`

**To:** `0x860e626c700AF381133D9f4aF31412A2d1DB3D5d`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a300000000000000000000000000000000000000000000000000000000000000010000000000000000000000004a0973e21274c4d939c84ac8b98d4308b7c9e249`

### Inputs
**_gameType:** `1`

**_impl:** `0x4A0973E21274c4d939c84ac8B98D4308b7c9E249`


## Tx #2: Upgrade `CANNON` game type in `DisputeGameFactory`
Upgrades the `CANNON` game type to the new Holocene deployment, with an updated version of `op-program` as the absolute prestate hash.

**Function Signature:** `setImplementation(uint32,address)`

**To:** `0x860e626c700AF381133D9f4aF31412A2d1DB3D5d`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e562e81d08cd5e212661ef961b4069456e426c56`

### Inputs
**_gameType:** `0`

**_impl:** `0xe562e81d08cD5e212661EF961B4069456e426C56`

