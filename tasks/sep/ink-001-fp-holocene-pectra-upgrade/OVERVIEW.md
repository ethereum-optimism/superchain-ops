# Holocene Hardfork - Proof Contract Upgrades
Upgrades the `MIPS.sol`, `FaultDisputeGame.sol`, and `PermissionedDisputeGame.sol` contracts for Holocene.

The batch will be executed on chain ID `11155111`, and contains `2` transactions.

## Tx #1: Upgrade `PERMISSIONED_CANNON` game type in `DisputeGameFactory`
Upgrades the `PERMISSIONED_CANNON` game type to the new Holocene deployment, with an updated version of `op-program` as the absolute prestate hash.

**Function Signature:** `setImplementation(uint32,address)`

**To:** `0x860e626c700AF381133D9f4aF31412A2d1DB3D5d`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a3000000000000000000000000000000000000000000000000000000000000000100000000000000000000000039228e51a12662d78de478bfa1930fc7595337d8`

### Inputs
**_impl:** `0x39228E51A12662d78DE478BFa1930fc7595337D8`

**_gameType:** `1`


## Tx #2: Upgrade `CANNON` game type in `DisputeGameFactory`
Upgrades the `CANNON` game type to the new Holocene deployment, with an updated version of `op-program` as the absolute prestate hash.

**Function Signature:** `setImplementation(uint32,address)`

**To:** `0x860e626c700AF381133D9f4aF31412A2d1DB3D5d`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000323d727a1a147869cec0c02de1d4195d1b71f2eb`

### Inputs
**_gameType:** `0`

**_impl:** `0x323d727A1a147869cEC0C02dE1d4195d1b71F2eB`

