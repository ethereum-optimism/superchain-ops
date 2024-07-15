# Execution

This section describes the transactions used to execute the upgrade. The upgrade is a batch of `6` transactions executed on chain ID `11155111`.

## Tx #1: Upgrade OptimismPortalProxy to StorageSetter and reset initializing storage slot

This transaction initiates an `upgradeAndCall` on the `ProxyAdmin`, targeting the `OptimismPortalProxy` contract where the implementation used in the upgrade
is `StorageSetter`. Once the new implementation is set, the function `setBytes32` is called on `OptimismPortalProxy`.

**Function Signature:** `upgradeAndCall(address,address,bytes)`

**To:** `0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3`

**Value:** `0 WEI`

**Raw Input Data:** `0x9623609d00000000000000000000000049f53e41452c74589e85ca1677426ba426459e8500000000000000000000000054f8076f4027e21a010b4b3900c86211dd2c2deb000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000444e91db080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000`

### Inputs

**_proxy:** `0x49f53e41452C74589E85cA1677426Ba426459e85`

**_implementation:** `0x54F8076f4027e21A010b4B3900C86211Dd2C2DEB`

**_data:** `0x4e91db0800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000`

### Commands

Command to create the internal calldata for the `setBytes32` call in `upgradeAndCall`:

```bash
cast calldata "setBytes32(bytes32,bytes32)" "0x0000000000000000000000000000000000000000000000000000000000000000" "0x0000000000000000000000000000000000000000000000000000000000000000"
```

Command to create the `upgradeAndCall` transaction and add to `input.json`:

```bash
just add-transaction tasks/sep/base-002-fp-upgrade/input.json 0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3 "upgradeAndCall(address,address,bytes)" "0x49f53e41452C74589E85cA1677426Ba426459e85" "0x54F8076f4027e21A010b4B3900C86211Dd2C2DEB" "0x4e91db0800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
```

## Tx #2: Reset l2Sender

This transaction calls `setAddress` on the `OptimismPortalProxy`. This is another pre-requisite step in order to upgrade and re-initialize the `OptimismPortalProxy`
with the `OptimismPortal2` implementation.

**Function Signature:** `setAddress(bytes32,address)`

**To:** `0x49f53e41452C74589E85cA1677426Ba426459e85`

**Value:** `0 WEI`

**Raw Input Data:** `0xca446dd900000000000000000000000000000000000000000000000000000000000000320000000000000000000000000000000000000000000000000000000000000000`

### Inputs

**_slot:** `0x0000000000000000000000000000000000000000000000000000000000000032`

**_address:** `0x0000000000000000000000000000000000000000`

### Commands

Command to create the `setAddress` transaction and add to `input.json`:

```bash
just add-transaction tasks/sep/base-002-fp-upgrade/input.json 0x49f53e41452C74589E85cA1677426Ba426459e85 "setAddress(bytes32,address)" "0x0000000000000000000000000000000000000000000000000000000000000032" "0x0000000000000000000000000000000000000000"
```

## Tx #3: Upgrade OptimismPortalProxy to implementation OptimismPortal2

This transactions initiates an `upgradeAndCall` on the `ProxyAdmin`, targeting the `OptimismPortalProxy` contract where the implementation used in the upgrade
is `OptimismPortal2`. Once the new implementation is set, `initialize` is called on `OptimismPortalProxy`.

**Function Signature:** `upgradeAndCall(address,address,bytes)`

**To:** `0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3`

**Value:** `0 WEI`

**Raw Input Data:** `0x9623609d00000000000000000000000049f53e41452c74589e85ca1677426ba426459e8500000000000000000000000035028bae87d71cbc192d545d38f960ba30b4b233000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000848e819e54000000000000000000000000d6e6dbf4f7ea0ac412fd8b65ed297e64bb7a06e1000000000000000000000000f272670eb55e895584501d564afeb048bed26194000000000000000000000000c2be75506d5724086deb7245bd260cc9753911be000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000`

### Inputs

**_proxy:** `0x49f53e41452C74589E85cA1677426Ba426459e85`

**_implementation:** `0x35028bAe87D71cbC192d545d38F960BA30B4B233`

**_data:** `0x8e819e54000000000000000000000000d6e6dbf4f7ea0ac412fd8b65ed297e64bb7a06e1000000000000000000000000f272670eb55e895584501d564afeb048bed26194000000000000000000000000c2be75506d5724086deb7245bd260cc9753911be0000000000000000000000000000000000000000000000000000000000000000`

### Commands

Command to create the internal calldata for the `initialize` call in `upgradeAndCall`:

```bash
cast calldata "initialize(address,address,address,uint32)" "0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1" "0xf272670eb55e895584501d564AfEB048bEd26194" "0xC2Be75506d5724086DEB7245bd260Cc9753911Be" 0
```

Command to create the `upgradeAndCall` transaction and add to `input.json`:

```bash
just add-transaction tasks/sep/base-002-fp-upgrade/input.json 0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3 "upgradeAndCall(address,address,bytes)" "0x49f53e41452C74589E85cA1677426Ba426459e85" "0x35028bAe87D71cbC192d545d38F960BA30B4B233" "0x8e819e54000000000000000000000000d6e6dbf4f7ea0ac412fd8b65ed297e64bb7a06e1000000000000000000000000f272670eb55e895584501d564afeb048bed26194000000000000000000000000c2be75506d5724086deb7245bd260cc9753911be0000000000000000000000000000000000000000000000000000000000000000"
```

## Tx #4: Upgrade SystemConfig to StorageSetter and clear L2OutputOracle storage slot

This transaction initiates an `upgradeAndCall` on the `ProxyAdmin`, targeting the `SystemConfig` contract where the implementation used in the upgrade
is `StorageSetter`. Once the new implementation is set, `setAddress` is called on `SystemConfig`.

**Function Signature:** `upgradeAndCall(address,address,bytes)`

**To:** `0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3`

**Value:** `0 WEI`

**Raw Input Data:** `0x9623609d000000000000000000000000f272670eb55e895584501d564afeb048bed2619400000000000000000000000054f8076f4027e21a010b4b3900c86211dd2c2deb00000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000044ca446dd9e52a667f71ec761b9b381c7b76ca9b852adf7e8905da0e0ad49986a0a6871815000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000`

### Inputs

**_proxy:** `0xf272670eb55e895584501d564AfEB048bEd26194`

**_implementation:** `0x54F8076f4027e21A010b4B3900C86211Dd2C2DEB`

**_data:** `0xca446dd9e52a667f71ec761b9b381c7b76ca9b852adf7e8905da0e0ad49986a0a68718150000000000000000000000000000000000000000000000000000000000000000`

### Commands

Command to create the internal calldata for the `setAddress` call in `upgradeAndCall`:

```bash
cast calldata "setAddress(bytes32,address)" "0xe52a667f71ec761b9b381c7b76ca9b852adf7e8905da0e0ad49986a0a6871815" "0x0000000000000000000000000000000000000000"
```

Command to create the `upgradeAndCall` transaction and add to `input.json`:

```bash
just add-transaction tasks/sep/base-002-fp-upgrade/input.json 0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3 "upgradeAndCall(address,address,bytes)" "0xf272670eb55e895584501d564AfEB048bEd26194" "0x54F8076f4027e21A010b4B3900C86211Dd2C2DEB" "0xca446dd9e52a667f71ec761b9b381c7b76ca9b852adf7e8905da0e0ad49986a0a68718150000000000000000000000000000000000000000000000000000000000000000"
```

## Tx #5: Clear storage variable at keccak256(systemconfig.disputegamefactory)-1 in SystemConfig

This transaction calls `setAddress` on the `SystemConfig` contract. Calling `setAddress` directly using the `StorageSetter` allows the new
`disputeGameFactory` address to be set in the `SystemConfig` contract without having to go through the steps to re-initialize `SystemConfig`.

**Function Signature:** `setAddress(bytes32,address)`

**To:** `0xf272670eb55e895584501d564AfEB048bEd26194`

**Value:** `0 WEI`

**Raw Input Data:** `0xca446dd952322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906000000000000000000000000d6e6dbf4f7ea0ac412fd8b65ed297e64bb7a06e1`

### Inputs

**_slot:** `0x52322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906`

**_address:** `0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1`

### Commands

Command to create the `setAddress` transaction and add to `input.json`:

```bash
just add-transaction tasks/sep/base-002-fp-upgrade/input.json 0xf272670eb55e895584501d564AfEB048bEd26194 "setAddress(bytes32,address)" "0x52322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906" "0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1"
```

## Tx #6: Upgrade SystemConfig to version 2.2.0

This transaction on `upgrade` call on the `ProxyAdmin`, targeting the `SystemConfig` contract where the implementation used in the upgrade
is `SystemConfig` version `2.2.0`. Note there is no additional call, therefore the `SystemConfig` contract is no re-initialized.

**Function Signature:** `upgrade(address,address)`

**To:** `0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3`

**Value:** `0 WEI`

**Raw Input Data:** `0x99a88ec4000000000000000000000000f272670eb55e895584501d564afeb048bed26194000000000000000000000000ccdd86d581e40fb5a1c77582247bc493b6c8b169`

### Inputs

**_proxy:** `0xf272670eb55e895584501d564AfEB048bEd26194`

**_implementation:** `0xCcdd86d581e40fb5a1C77582247BC493b6c8B169`

### Commands

Command to create the `upgrade` transaction and add to `input.json`:

```bash
just add-transaction tasks/sep/base-002-fp-upgrade/input.json 0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3 "upgrade(address,address)" "0xf272670eb55e895584501d564AfEB048bEd26194" "0xCcdd86d581e40fb5a1C77582247BC493b6c8B169"
```
