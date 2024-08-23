# Execution

This section describes the transactions used to execute the upgrade. The upgrade is a batch of `4` transactions executed on chain ID `11155111`.

## Tx 1: Upgrade `AnchorStateRegistry` to `StorageSetter` implementation and set storage slot 2 to `SuperchainConfig` address

**Function Signature:** `upgradeAndCall(address,address,bytes)`

**To:** `0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3`

**Value:** `0 WEI`

**Raw Input Data:** `0x9623609d0000000000000000000000004c8ba32a5dac2a720bb35cedb51d6b067d10420500000000000000000000000054f8076f4027e21a010b4b3900c86211dd2c2deb00000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000044ca446dd90000000000000000000000000000000000000000000000000000000000000002000000000000000000000000c2be75506d5724086deb7245bd260cc9753911be00000000000000000000000000000000000000000000000000000000`

### Inputs

**_proxy:** `0x4C8BA32A5DAC2A720bb35CeDB51D6B067D104205`

**_implementation:** `0x54F8076f4027e21A010b4B3900C86211Dd2C2DEB`

### Commands

```sh
cast calldata "setAddress(bytes32,address)" "0x0000000000000000000000000000000000000000000000000000000000000002" "0xC2Be75506d5724086DEB7245bd260Cc9753911Be"
```

```sh
just add-transaction tasks/sep/base-004-fp-audit-fixes/input.json 0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3 "upgradeAndCall(address,address,bytes)" "0x4C8BA32A5DAC2A720bb35CeDB51D6B067D104205" "0x54F8076f4027e21A010b4B3900C86211Dd2C2DEB" "0xca446dd90000000000000000000000000000000000000000000000000000000000000002000000000000000000000000c2be75506d5724086deb7245bd260cc9753911be"
```

## Tx 2: Upgrade `AnchorStateRegistry` to new implementation address

**Function Signature:** `upgrade(address,address)`

**To:** `0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3`

**Value:** `0 WEI`

**Raw Input Data:** `0x99a88ec40000000000000000000000004c8ba32a5dac2a720bb35cedb51d6b067d10420500000000000000000000000095907b5069e5a2ef1029093599337a6c9dac8923`

### Inputs

**_proxy:** `0x4C8BA32A5DAC2A720bb35CeDB51D6B067D104205`

**_implementation:** `0x95907b5069e5a2EF1029093599337a6C9dac8923`

### Commands

```sh
just add-transaction tasks/sep/base-004-fp-audit-fixes/input.json 0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3 "upgrade(address,address)" "0x4C8BA32A5DAC2A720bb35CeDB51D6B067D104205" "0x95907b5069e5a2EF1029093599337a6C9dac8923"
```

## Tx 3: Set new `FaultDisputeGame` implementation on `DisputeGameFactory`

**Function Signature:** `setImplementation(uint32,address)`

**To:** `0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a300000000000000000000000000000000000000000000000000000000000000000000000000000000000000005062792ed6a85cf72a1424a1b7f39ed0f7972a4b`

### Inputs

**_gameType:** `0`

**_impl:** `0x5062792ED6A85cF72a1424a1b7f39eD0f7972a4B`

### Commands

```sh
just add-transaction tasks/sep/base-004-fp-audit-fixes/input.json 0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1 "setImplementation(uint32,address)" "0" "0x5062792ED6A85cF72a1424a1b7f39eD0f7972a4B"
```

## Tx 4: Set new `PermissionedDisputeGame` implementation on `DisputeGameFactory`

**Function Signature:** `setImplementation(uint32,address)`

**To:** `0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1`

**Value:** `0 WEI`

**Raw Input Data:** `0x14f6b1a30000000000000000000000000000000000000000000000000000000000000001000000000000000000000000ccefe451048eaa7df8d0d709be3aa30d565694d2`

### Inputs

**_gameType:** `1`

**_impl:** `0xCCEfe451048Eaa7df8D0d709bE3AA30d565694D2`

### Commands

```sh
just add-transaction tasks/sep/base-004-fp-audit-fixes/input.json 0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1 "setImplementation(uint32,address)" "1" "0xCCEfe451048Eaa7df8D0d709bE3AA30d565694D2"
```
