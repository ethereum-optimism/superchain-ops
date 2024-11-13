# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Changes

### `0x2419423C72998eb1c6c15A235de2f112f8E38efF` (`DisputeGameFactoryProxy`)

- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
  **Before**: `0x00000000000000000000000054416a2e28e8cbc761fbce0c7f107307991282e5` <br/>
  **After**: `0x000000000000000000000000e5e89e67f9715ca9e6be0bd7e50ce143d177117b` <br/>
  **Meaning**: Updates the CANNON game type implementation. Verify that the new implementation is set using `cast call 0x2419423C72998eb1c6c15A235de2f112f8E38efF "gameImpls(uint32)(address)" 0`. Where `0` is the [`CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L28).

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x00000000000000000000000050573970b291726b881b204ed9f3c1d507e504cd` <br/>
  **After**: `0x0000000000000000000000006a962628aa48564b7c48d97e1a738044ffec686f` <br/>
  **Meaning**: Updates the PERMISSIONED_CANNON game type implementation. Verify that the new implementation is set using `cast call 0x2419423C72998eb1c6c15A235de2f112f8E38efF "gameImpls(uint32)(address)" 1`. Where `1` is the [`PERMISSIONED_CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L31).

### `0xa6b72407e2dc9EBF84b839B69A24C88929cf20F7` (`SystemConfigProxy`)

- **Key**: `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  **Before**: `0x000000000000000000000000c0ccc8b32a7bf4dc3fe8d0de41ad3c9b9b25d681`
  **After**: `0x00000000000000000000000029d06ed7105c7552efd9f29f3e0d250e5df412cd`
  **Meaning**: Updates the `SystemConfig` proxy implementation.
