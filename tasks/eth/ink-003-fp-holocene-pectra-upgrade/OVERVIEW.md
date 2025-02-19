# Holocene Hardfork - Proof Contract Upgrades
Upgrades the `MIPS.sol`, `FaultDisputeGame.sol`, and `PermissionedDisputeGame.sol` contracts for Holocene.

The batch will be executed on chain ID `1`, and contains `2` transactions.

## Tx #1: Upgrade `PERMISSIONED_CANNON` game type in `DisputeGameFactory`
Upgrades the `PERMISSIONED_CANNON` game type to the new Holocene deployment, with an updated version of `op-program` as the absolute prestate hash.

**Function Signature:** `setImplementation(uint32,address)`

**To:** `0x10d7B35078d3baabB96Dd45a9143B94be65b12CD`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a30000000000000000000000000000000000000000000000000000000000000001000000000000000000000000f75da262a580cf9b2eab9847559c5837381ae3a3`

### Inputs
**_gameType:** `1`

**_impl:** `0xf75DA262a580cf9b2EaB9847559c5837381aE3a3`


## Tx #2: Upgrade `CANNON` game type in `DisputeGameFactory`
Upgrades the `CANNON` game type to the new Holocene deployment, with an updated version of `op-program` as the absolute prestate hash.

**Function Signature:** `setImplementation(uint32,address)`

**To:** `0x10d7B35078d3baabB96Dd45a9143B94be65b12CD`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e09185bbb538d084209ef6f1a92dc499d313ce51`

### Inputs
**_gameType:** `0`

**_impl:** `0xE09185Bbb538d084209EF6f1a92Dc499D313ce51`

