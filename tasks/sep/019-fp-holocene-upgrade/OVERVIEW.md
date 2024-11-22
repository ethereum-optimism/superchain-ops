# Holocene Hardfork - Proof Contract Upgrades
Upgrades the `MIPS.sol`, `FaultDisputeGame.sol`, and `PermissionedDisputeGame.sol` contracts for Holocene.

The batch will be executed on chain ID `11155111`, and contains `2` transactions.

## Tx #1: Upgrade `PERMISSIONED_CANNON` game type in `DisputeGameFactory`
Upgrades the `PERMISSIONED_CANNON` game type to the new Holocene deployment, with an updated version of `op-program` as the absolute prestate hash.

**Function Signature:** `setImplementation(uint32,address)`

**To:** `0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a300000000000000000000000000000000000000000000000000000000000000010000000000000000000000004ed046e66c96600dae1a4ec39267bb0ce476e8cc`

### Inputs
**_impl:** `0x4Ed046e66c96600DaE1a4ec39267bB0cE476E8cc`

**_gameType:** `1`


## Tx #2: Upgrade `CANNON` game type in `DisputeGameFactory`
Upgrades the `CANNON` game type to the new Holocene deployment, with an updated version of `op-program` as the absolute prestate hash.

**Function Signature:** `setImplementation(uint32,address)`

**To:** `0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a300000000000000000000000000000000000000000000000000000000000000000000000000000000000000005e0877a8f6692ed470013e651c4357d0c4941e6c`

### Inputs
**_gameType:** `0`

**_impl:** `0x5e0877a8F6692eD470013e651c4357d0C4941e6C`

