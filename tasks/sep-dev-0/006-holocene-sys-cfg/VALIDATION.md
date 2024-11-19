# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Changes

### `0xa6b72407e2dc9EBF84b839B69A24C88929cf20F7` (`SystemConfigProxy`)

- **Key**: `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  **Before**: `0x000000000000000000000000c0ccc8b32a7bf4dc3fe8d0de41ad3c9b9b25d681`
  **After**: `0x00000000000000000000000029d06ed7105c7552efd9f29f3e0d250e5df412cd`
  **Meaning**: Updates the `SystemConfig` proxy implementation.

- **Key**: `0x383f291819e6d54073bc9a648251d97421076bdd101933c0c022219ce9580636`
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000`
  **After**: `0x00000000000000000000000018e72c15fee4e995454b919efaa61d8f116f82dd`
  **Meaning**: Sets the `L1CrossDomainMessenger` slot in the `SystemConfig`.

- **Key**: `0x46adcbebc6be8ce551740c29c47c8798210f23f7f4086c41752944352568d5a7`
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000`
  **After**: `0x0000000000000000000000001bb726658e039e8a9a4ac21a41fe5a0704760461`
  **Meaning**: Sets the `L1ERC721Bridge` slot in the `SystemConfig`

- **Key**: `0x4b6c74f9e688cb39801f2112c14a8c57232a3fc5202e1444126d4bce86eb19ac`
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000`
  **After**: `0x00000000000000000000000076114bd29dfcc7a9892240d317e6c7c2a281ffc6`
  **Meaning**: Sets the `OptimismPortal` slot in the `SystemConfig`

- **Key**: `0x52322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906`
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000`
  **After**: `0x0000000000000000000000002419423c72998eb1c6c15a235de2f112f8e38eff`
  **Meaning**: Sets the `DisputeGameFactory` slot in the `SystemConfig`

- **Key**: `0x71ac12829d66ee73d8d95bff50b3589745ce57edae70a3fb111a2342464dc597`
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000`
  **After**: `0x000000000000000000000000ff00000000000000000000000000000011155421`
  **Meaning**: Sets the batch inbox slot in the `SystemConfig`

- **Key**: `0x9904ba90dde5696cda05c9e0dab5cbaa0fea005ace4d11218a02ac668dad6376`
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000`
  **After**: `0x0000000000000000000000006d8bc564ef04aaf355a10c3eb9b00e349dd077ea`
  **Meaning**: Sets the `L1StandardBridge` slot in the `SystemConfig`

- **Key**: `0xa04c5bb938ca6fc46d95553abf0a76345ce3e722a30bf4f74928b8e7d852320c`
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000`
  **After**: `0x000000000000000000000000a16b8db3b5cdbaf75158f34034b0537e528e17e2`
  **Meaning**: Sets the `OptimismMintableERC20Factory` slot in the `SystemConfig`

- **Key**: `0xa11ee3ab75b40e88a0105e935d17cd36c8faee0138320d776c411291bdbbb19f`
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000`
  **After**: `0x00000000000000000000000000000000000000000000000000000000003e1f50`
  **Meaning**: Sets the start block in the `SystemConfig`
