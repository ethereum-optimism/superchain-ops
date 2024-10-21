# FP Upgrade - Base Mainnet
Upgrades the `OptimismPortal` and `SystemConfig` implementations

The batch will be executed on chain ID `1`, and contains `7` transactions.

## Tx #1: Upgrade OptimismPortal to StorageSetter
Upgrade OptimismPortal to StorageSetter and reset `initializing`

**Function Signature:** `upgradeAndCall(address,address,bytes)`

**To:** `0x0475cBCAebd9CE8AfA5025828d5b98DFb67E059E`

**Value:** `0 WEI`

**Raw Input Data:** `0x9623609d00000000000000000000000049048044d57e1c92a77f79988d21fa8faf74e97e000000000000000000000000d81f43edbcacb4c29a9ba38a13ee5d79278270cc000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000444e91db080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000`

### Inputs
**_implementation:** `0xd81f43eDBCAcb4c29a9bA38a13Ee5d79278270cC`

**_proxy:** `0x49048044D57e1C92A77f79988d21Fa8fAF74E97e`

**_data:** `0x4e91db0800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000`


## Tx #2: Reset l2Sender in OptimismPortalProxy
Pre-initialization of the OptimismPortal2

**Function Signature:** `setAddress(bytes32,address)`

**To:** `0x49048044D57e1C92A77f79988d21Fa8fAF74E97e`

**Value:** `0 WEI`

**Raw Input Data:** `0xca446dd900000000000000000000000000000000000000000000000000000000000000320000000000000000000000000000000000000000000000000000000000000000`

### Inputs
**_slot:** `0x0000000000000000000000000000000000000000000000000000000000000032`

**_address:** `0x0000000000000000000000000000000000000000`


## Tx #3: Upgrade the OptimismPortal
Upgrade and initialize the OptimismPortal to OptimismPortal2 (3.10.0)

**Function Signature:** `upgradeAndCall(address,address,bytes)`

**To:** `0x0475cBCAebd9CE8AfA5025828d5b98DFb67E059E`

**Value:** `0 WEI`

**Raw Input Data:** `0x9623609d00000000000000000000000049048044d57e1c92a77f79988d21fa8faf74e97e00000000000000000000000049048044d57e1c92a77f79988d21fa8faf74e97e00000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000014e2f826324b2faf99e513d16d266c3f80ae87832b000000000000000000000000`

### Inputs
**_data:** `0x8e819e5400000000000000000000000043edb88c4b80fdd2adff2412a7bebf9df42cb40e00000`

**_implementation:** `0xe2F826324b2faf99E513D16D266c3F80aE87832B`

**_proxy:** `0x49048044D57e1C92A77f79988d21Fa8fAF74E97e`


## Tx #4: Upgrade SystemConfig to StorageSetter
Upgrades the `SystemConfig` proxy to the `StorageSetter` contract in preparation for clearing the legacy `L2OutputOracle` storage slot and set the new `DisputeGameFactory` storage slot to contain the address of the `DisputeGameFactory` proxy.

**Function Signature:** `upgrade(address,address)`

**To:** `0x0475cBCAebd9CE8AfA5025828d5b98DFb67E059E`

**Value:** `0 WEI`

**Raw Input Data:** `0x99a88ec400000000000000000000000073a79fab69143498ed3712e519a88a918e1f4072000000000000000000000000d81f43edbcacb4c29a9ba38a13ee5d79278270cc`

### Inputs
**_implementation:** `0xd81f43eDBCAcb4c29a9bA38a13Ee5d79278270cC`

**_proxy:** `0x73a79Fab69143498Ed3712e519A88a918e1f4072`


## Tx #5: Clear SystemConfig's L2OutputOracle slot
clears the keccak(systemconfig.l2outputoracle)-1 slot

**Function Signature:** `setAddress(bytes32,address)`

**To:** `0x73a79Fab69143498Ed3712e519A88a918e1f4072`

**Value:** `0 WEI`

**Raw Input Data:** `0xca446dd9e52a667f71ec761b9b381c7b76ca9b852adf7e8905da0e0ad49986a0a68718150000000000000000000000000000000000000000000000000000000000000000`

### Inputs
**_address:** `0x0000000000000000000000000000000000000000`

**_slot:** `0xe52a667f71ec761b9b381c7b76ca9b852adf7e8905da0e0ad49986a0a6871815`


## Tx #6: Set SystemConfig's DisputeGameFactory slot
sets the keccak(systemconfig.disputegamefactory)-1 slot

**Function Signature:** `setAddress(bytes32,address)`

**To:** `0x73a79Fab69143498Ed3712e519A88a918e1f4072`

**Value:** `0 WEI`

**Raw Input Data:** `0xca446dd952322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906000000000000000000000000e5965ab5962edc7477c8520243a95517cd252fa9`

### Inputs
**_slot:** `0x52322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906`

**_address:** `0xe5965Ab5962eDc7477C8520243A95517CD252fA9`


## Tx #7: Upgrade SystemConfig to 2.2.0
Upgrade SystemConfig to 2.2.0

**Function Signature:** `upgrade(address,address)`

**To:** `0x0475cBCAebd9CE8AfA5025828d5b98DFb67E059E`

**Value:** `0 WEI`

**Raw Input Data:** `0x99a88ec400000000000000000000000073a79fab69143498ed3712e519a88a918e1f4072000000000000000000000000f56d96b2535b932656d3c04ebf51babff241d886`

### Inputs
**_proxy:** `0x73a79Fab69143498Ed3712e519A88a918e1f4072`

**_implementation:** `0xF56D96B2535B932656d3c04Ebf51baBff241D886`
