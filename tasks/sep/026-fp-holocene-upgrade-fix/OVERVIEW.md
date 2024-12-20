# Holocene Hardfork - Proof Contract Upgrades
Upgrades the `MIPS.sol`, `FaultDisputeGame.sol`, and `PermissionedDisputeGame.sol` contracts for Holocene.

The batch will be executed on chain ID `11155111`, and contains `2` transactions.

## Tx #1: Upgrade `PERMISSIONED_CANNON` game type in `DisputeGameFactory`
Upgrades the `PERMISSIONED_CANNON` game type to the new Holocene deployment, with an updated version of `op-program` as the absolute prestate hash.

**Function Signature:** `setImplementation(uint32,address)`

**To:** `0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a30000000000000000000000000000000000000000000000000000000000000001000000000000000000000000bbd576128f71186a0f9ae2f2aab4afb4af2dae17`

### Inputs
**_gameType:** `1`

**_impl:** `0xbBD576128f71186A0f9ae2F2AAb4afb4aF2dae17`


## Tx #2: Upgrade `CANNON` game type in `DisputeGameFactory`
Upgrades the `CANNON` game type to the new Holocene deployment, with an updated version of `op-program` as the absolute prestate hash.

**Function Signature:** `setImplementation(uint32,address)`

**To:** `0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000833a817ef459f4ecdb83fc5a4bf04d09a4e83f3f`

### Inputs
**_gameType:** `0`

**_impl:** `0x833a817eF459f4eCdB83Fc5A4Bf04d09A4e83f3F`
