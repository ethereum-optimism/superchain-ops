# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Changes

### `0x2419423C72998eb1c6c15A235de2f112f8E38efF` (`DisputeGameFactoryProxy`)

**Key**: 0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e  
**Before**: 0x0000000000000000000000006a962628aa48564b7c48d97e1a738044ffec686f  
**After**: 0x0000000000000000000000004001542871a610a551b11dcaaea52dc5ca6fdb6a  
**Meaning**: Updates the PERMISSIONED_CANNON game type implementation. Verify that the new implementation is set using `cast call 0x2419423c72998eb1c6c15a235de2f112f8e38eff gameImpls(uint32)(address) 1`.
Confirm the expected key slot with the following:
```
cast index uint32 1 101
0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e
```

**Key**: 0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b  
**Before**: 0x000000000000000000000000e5e89e67f9715ca9e6be0bd7e50ce143d177117b  
**After**: 0x000000000000000000000000030aca4aea0cf48bd53dca03b34e35d05b9635c7  
**Meaning**: Updates the CANNON game type implementation. Verify that the new implementation is set using `cast call 0x2419423c72998eb1c6c15a235de2f112f8e38eff gameImpls(uint32)(address) 0`.
Confirm the expected key slot with the following:
```
cast index uint32 0 101
0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b
```

### Safe Contract State Changes

The only other state changes should be restricted to one of the following addresses:

- L1 1/1 ProxyAdmin Owner Safe: `0x4377BB0F0103992b31eC12b4d796a8687B8dC8E9`
    - The nonce (slot 0x5) should be increased from 25 to 26.
