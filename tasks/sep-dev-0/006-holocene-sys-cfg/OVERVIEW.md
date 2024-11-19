# Holocene Hardfork - System Config Contract Upgrade
Upgrades the `SystemConfig.sol` contract for Holocene.

The batch will be executed on chain ID `11155111`, and contains `10` transactions.

## Tx #1: Upgrade SystemConfig to StorageSetter
Upgrades the `SystemConfig` proxy to the `StorageSetter` contract in order to manually update new storage slots.

**Function Signature:** `upgrade(address,address)`

**To:** `0x18d890A46A3556e7F36f28C79F6157BC7a59f867`

**Value:** `0 WEI`

**Raw Input Data:** `0x99a88ec4000000000000000000000000a6b72407e2dc9ebf84b839b69a24c88929cf20f7000000000000000000000000d81f43edbcacb4c29a9ba38a13ee5d79278270cc`

### Inputs
**_implementation:** `0xd81f43eDBCAcb4c29a9bA38a13Ee5d79278270cC`

**_proxy:** `0xa6b72407e2dc9EBF84b839B69A24C88929cf20F7`


## Tx #2: Set `L1CrossDomainMessenger` storage slot in `SystemConfig`
Sets the new `L1CrossDomainMessenger` storage slot in the `SystemConfig` contract.

**Function Signature:** `setAddress(bytes32,address)`

**To:** `0xa6b72407e2dc9EBF84b839B69A24C88929cf20F7`

**Value:** `0 WEI`

**Raw Input Data:** `0xca446dd9383f291819e6d54073bc9a648251d97421076bdd101933c0c022219ce958063600000000000000000000000018e72c15fee4e995454b919efaa61d8f116f82dd`

### Inputs
**_slot:** `0x383f291819e6d54073bc9a648251d97421076bdd101933c0c022219ce9580636`

**_addr:** `0x18e72C15FEE4e995454b919EfaA61D8f116F82dd`


## Tx #3: Set `L1ERC721Bridge` storage slot in `SystemConfig`
Sets the new `L1ERC721Bridge` storage slot in the `SystemConfig` contract.

**Function Signature:** `setAddress(bytes32,address)`

**To:** `0xa6b72407e2dc9EBF84b839B69A24C88929cf20F7`

**Value:** `0 WEI`

**Raw Input Data:** `0xca446dd946adcbebc6be8ce551740c29c47c8798210f23f7f4086c41752944352568d5a70000000000000000000000001bb726658e039e8a9a4ac21a41fe5a0704760461`

### Inputs
**_slot:** `0x46adcbebc6be8ce551740c29c47c8798210f23f7f4086c41752944352568d5a7`

**_addr:** `0x1bb726658E039E8a9A4ac21A41fE5a0704760461`

## Tx #4: Set `L1StandardBridge` storage slot in `SystemConfig`
Sets the new `L1StandardBridge` storage slot in the `SystemConfig` contract.

**Function Signature:** `setAddress(bytes32,address)`

**To:** `0xa6b72407e2dc9EBF84b839B69A24C88929cf20F7`

**Value:** `0 WEI`

**Raw Input Data:** `0xca446dd99904ba90dde5696cda05c9e0dab5cbaa0fea005ace4d11218a02ac668dad63760000000000000000000000006d8bc564ef04aaf355a10c3eb9b00e349dd077ea`

### Inputs
**_slot:** `0x9904ba90dde5696cda05c9e0dab5cbaa0fea005ace4d11218a02ac668dad6376`

**_addr:** `0x6D8bC564EF04AaF355a10c3eb9b00e349dd077ea`


## Tx #5: Set `OptimismPortal` storage slot in `SystemConfig`
Sets the new `OptimismPortal` storage slot in the `SystemConfig` contract.

**Function Signature:** `setAddress(bytes32,address)`

**To:** `0xa6b72407e2dc9EBF84b839B69A24C88929cf20F7`

**Value:** `0 WEI`

**Raw Input Data:** `0xca446dd94b6c74f9e688cb39801f2112c14a8c57232a3fc5202e1444126d4bce86eb19ac00000000000000000000000076114bd29dfcc7a9892240d317e6c7c2a281ffc6`

### Inputs
**_slot:** `0x4b6c74f9e688cb39801f2112c14a8c57232a3fc5202e1444126d4bce86eb19ac`

**_addr:** `0x76114bd29dFcC7a9892240D317E6c7C2A281Ffc6`


## Tx #6: Set `OptimismMintableERC20Factory` storage slot in `SystemConfig`
Sets the new `OptimismMintableERC20Factory` storage slot in the `SystemConfig` contract.

**Function Signature:** `setAddress(bytes32,address)`

**To:** `0xa6b72407e2dc9EBF84b839B69A24C88929cf20F7`

**Value:** `0 WEI`

**Raw Input Data:** `0xca446dd9a04c5bb938ca6fc46d95553abf0a76345ce3e722a30bf4f74928b8e7d852320c000000000000000000000000a16b8db3b5cdbaf75158f34034b0537e528e17e2`

### Inputs
**_slot:** `0xa04c5bb938ca6fc46d95553abf0a76345ce3e722a30bf4f74928b8e7d852320c`

**_addr:** `0xA16b8db3b5Cdbaf75158F34034B0537e528E17e2`

## Tx #7: Set `BatchInbox` storage slot in `SystemConfig`
Sets the new `BatchInbox` storage slot in the `SystemConfig` contract.

**Function Signature:** `setAddress(bytes32,address)`

**To:** `0xa6b72407e2dc9EBF84b839B69A24C88929cf20F7`

**Value:** `0 WEI`

**Raw Input Data:** `0xca446dd971ac12829d66ee73d8d95bff50b3589745ce57edae70a3fb111a2342464dc597000000000000000000000000ff00000000000000000000000000000011155421`

### Inputs
**_slot:** `0x71ac12829d66ee73d8d95bff50b3589745ce57edae70a3fb111a2342464dc597`

**_addr:** `0xff00000000000000000000000000000011155421`

## Tx #8: Set `StartBlock` storage slot in `SystemConfig`
Sets the new `StartBlock` storage slot in the `SystemConfig` contract.

**Function Signature:** `setAddress(bytes32,uint256)`

**To:** `0xa6b72407e2dc9EBF84b839B69A24C88929cf20F7`

**Value:** `0 WEI`

**Raw Input Data:** `0x8053d7d3a11ee3ab75b40e88a0105e935d17cd36c8faee0138320d776c411291bdbbb19f00000000000000000000000000000000000000000000000000000000003e1f50`

### Inputs
**_slot:** `0xa11ee3ab75b40e88a0105e935d17cd36c8faee0138320d776c411291bdbbb19f`

**_block:** `4071248`

## Tx #9: Set `DisputeGameFactory` storage slot in `SystemConfig`
Sets the new `DisputeGameFactory` storage slot in the `SystemConfig` contract.

**Function Signature:** `setAddress(bytes32,address)`

**To:** `0xa6b72407e2dc9EBF84b839B69A24C88929cf20F7`

**Value:** `0 WEI`

**Raw Input Data:** `0xca446dd952322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa9060000000000000000000000002419423c72998eb1c6c15a235de2f112f8e38eff`

### Inputs
**_slot:** `0x52322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906`

**_addr:** `0x2419423C72998eb1c6c15A235de2f112f8E38efF`


## Tx #10: Upgrade `SystemConfig` proxy
Upgrades the `SystemConfig` proxy to the new implementation, featuring configurable EIP-1559 parameters.

**Function Signature:** `upgrade(address,address)`

**To:** `0x18d890A46A3556e7F36f28C79F6157BC7a59f867`

**Value:** `0 WEI`

**Raw Input Data:** `0x99a88ec4000000000000000000000000a6b72407e2dc9ebf84b839b69a24c88929cf20f700000000000000000000000029d06ed7105c7552efd9f29f3e0d250e5df412cd`

### Inputs
**_proxy:** `0xa6b72407e2dc9EBF84b839B69A24C88929cf20F7`

**_implementation:** `0x29d06Ed7105c7552EFD9f29f3e0d250e5df412CD`

