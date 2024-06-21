# Execution

This section describes the transactions used to execute the upgrade. The upgrade is a batch of `2` transactions executed on chain ID `1`.

## Tx #1: Upgrade FaultDisputeGame implementation in DisputeGameFactoryProxy


**Function Signature:** `setImplementation(uint32,address)`

**To:** `0xe5965Ab5962eDc7477C8520243A95517CD252fA9`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f691f8a6d908b58c534b624cf16495b491e633ba`

### Inputs
**_impl:** `0xf691F8A6d908B58C534B624cF16495b491E633BA`

**_gameType:** `0`


## Tx #2: Upgrade PermissionedDisputeGame implementation in DisputeGameFactoryProxy


**Function Signature:** `setImplementation(uint32,address)`

**To:** `0xe5965Ab5962eDc7477C8520243A95517CD252fA9`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a30000000000000000000000000000000000000000000000000000000000000001000000000000000000000000c307e93a7c530a184c98eade4545a412b857b62f`

### Inputs
**_gameType:** `1`

**_impl:** `0xc307e93a7C530a184c98EaDe4545a412b857b62f`

