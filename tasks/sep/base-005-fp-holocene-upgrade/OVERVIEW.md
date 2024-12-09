# Holocene Hardfork - Proof Contract Upgrades
Upgrades the `MIPS.sol`, `FaultDisputeGame.sol`, and `PermissionedDisputeGame.sol` contracts for Holocene.

The batch will be executed on chain ID `11155111`, and contains `2` transactions.

## Tx #1: Upgrade `PERMISSIONED_CANNON` game type in `DisputeGameFactory`
Upgrades the `PERMISSIONED_CANNON` game type to the new Holocene deployment, with an updated version of `op-program` as the absolute prestate hash, an updated MIPS VM, and an updated version.

**Function Signature:** `setImplementation(uint32,address)`

**To:** `0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a3000000000000000000000000000000000000000000000000000000000000000100000000000000000000000068f600e592799c16d1b096616edbf1681fb9c0de`

### Inputs
**_impl:** `0x68f600e592799c16d1b096616edbf1681fb9c0de`

**_gameType:** `1`


## Tx #2: Upgrade `CANNON` game type in `DisputeGameFactory`
Upgrades the `CANNON` game type to the new Holocene deployment, with an updated version of `op-program` as the absolute prestate hash, an updated MIPS VM, and an updated version.

**Function Signature:** `setImplementation(uint32,address)`

**To:** `0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b7fb44a61fde2b9db28a84366e168b14d1a1b103`

### Inputs
**_gameType:** `0`

**_impl:** `0xb7fb44a61fde2b9db28a84366e168b14d1a1b103`
