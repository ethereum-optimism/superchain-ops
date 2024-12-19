# Holocene Hardfork - Proof Contract Upgrades
Upgrades the `MIPS.sol`, `FaultDisputeGame.sol`, and `PermissionedDisputeGame.sol` contracts for Holocene.

The batch will be executed on chain ID `1`, and contains `2` transactions.

## Tx #1: Upgrade `PERMISSIONED_CANNON` game type in `DisputeGameFactory`
Upgrades the `PERMISSIONED_CANNON` game type to the new Holocene deployment, with an updated version of `op-program` as the absolute prestate hash.

**Function Signature:** `setImplementation(uint32,address)`

**To:** `0xe5965Ab5962eDc7477C8520243A95517CD252fA9`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a3000000000000000000000000000000000000000000000000000000000000000100000000000000000000000091a661891248d8c4916fb4a1508492a5e2cbcb87`

### Inputs
**_impl:** `0x91a661891248d8C4916FB4a1508492a5e2CBcb87`

**_gameType:** `1`


## Tx #2: Upgrade `CANNON` game type in `DisputeGameFactory`
Upgrades the `CANNON` game type to the new Holocene deployment, with an updated version of `op-program` as the absolute prestate hash.

**Function Signature:** `setImplementation(uint32,address)`

**To:** `0xe5965Ab5962eDc7477C8520243A95517CD252fA9`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000027b81db41f586016694632193b99e45b1a27b8f8`

### Inputs
**_impl:** `0x27B81db41F586016694632193b99E45b1a27B8f8`

**_gameType:** `0`

