# MTCannon Deployment
Configures new MTCannon DisputeGame implementations on the DisputeGameFactoryProxy.

The batch will be executed on chain ID `11155111`, and contains `2` transactions.

## Tx #1: Set dispute game implementation (type 0 - CANNON)
Sets the FaultDisputeGame implementation on DisputeGameFactoryProxy.

**Function Signature:** `setImplementation(uint32,address)`

**To:** `0x54416A2E28E8cbC761fbce0C7f107307991282e5`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030aca4aea0cf48bd53dca03b34e35d05b9635c7`

### Inputs
**_gameType:** `0x0`

**_impl:** `0x030aca4aea0cf48bd53dca03b34e35d05b9635c7`


## Tx #2: Set dispute game implementation (type 1 - PERMISSIONED_CANNON)
Sets the PermissionedDisputeGame implementation on DisputeGameFactoryProxy.

**Function Signature:** `setImplementation(uint32,address)`

**To:** `0x54416A2E28E8cbC761fbce0C7f107307991282e5`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a300000000000000000000000000000000000000000000000000000000000000010000000000000000000000004001542871a610a551b11dcaaea52dc5ca6fdb6a`

### Inputs
**_impl:** `0x4001542871a610a551b11dcaaea52dc5ca6fdb6a`

**_gameType:** `0x1`

