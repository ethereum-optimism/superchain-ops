# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Changes

The only pertinent state changes (ignoring safe nonce updates) should be made to the `DisputeGameFactoryProxy` game type implementations.

### `0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1` (`DisputeGameFactoryProxy`)

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x0000000000000000000000003f5c770f17a6982d2b3ac77f6fdc93bfe0330e17` <br/>
  **After**: `0x0000000000000000000000008105d699b38ed7cf9b75353baccca60496ed72fd` <br/>
  **Meaning**: Updates the PERMISSIONED_CANNON game type implementation. Verify that the new implementation is set using `cast call 0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1 "gameImpls(uint32)(address)" 1`. Where `1` is the [`PERMISSIONED_CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L31).

- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
  **Before**: `0x0000000000000000000000008a9ba50a785c3868bef1fd4924b640a5e0ed54cf` <br/>
  **After**: `0x000000000000000000000000da35a941d76ff37a4abd877156f58e6aa2e499b0` <br/>
  **Meaning**: Updates the CANNON game type implementation. Verify that the new implementation is set using `cast call 0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1 "gameImpls(uint32)(address)" 0`. Where `0` is the [`CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L28).