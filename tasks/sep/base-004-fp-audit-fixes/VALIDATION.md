# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Changes

### `0x0fe884546476dDd290eC46318785046ef68a0BA9` (`GnosisSafeProxy`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000006` <br/>
  **Meaning**: The nonce in slot `0x05` of the L1 Gnosis Safe `ProxyAdmin` owner is incremented from 5 to 6.

### `0x4C8BA32A5DAC2A720bb35CeDB51D6B067D104205` (`AnchorStateRegistryProxy`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000002` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `0x000000000000000000000000c2be75506d5724086deb7245bd260cc9753911be` <br/>
  **Meaning**: This sets the `superchainConfig` address into storage slot 2 per the new [storage layout](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.6.0-rc.2/packages/contracts-bedrock/src/dispute/AnchorStateRegistry.sol#L40) of the `AnchorStateRegistry` implementation.

- **Key**: `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before**: `0x0000000000000000000000001ffafb5fdc292393c187629968ca86b112860a3e` <br/>
  **After**: `0x00000000000000000000000095907b5069e5a2ef1029093599337a6c9dac8923` <br/>
  **Meaning**: This upgrades the implementation of the `AnchorStateRegistryProxy` contract, where the storage key is the standard ERC-1967 storage slot.

### `0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1` (`DisputeGameFactoryProxy`)

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x00000000000000000000000054966d5a42a812d0daade1fa2321ff8b102d1ee1` <br/>
  **After**: `0x000000000000000000000000ccefe451048eaa7df8d0d709be3aa30d565694d2` <br/>
  **Meaning**: Updates the PERMISSIONED_CANNON game type implementation. Verify that the new implementation is set using `cast call 0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1 "gameImpls(uint32)(address)" 1`. Where `1` is the [`PERMISSIONED_CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.6.0-rc.2/packages/contracts-bedrock/src/dispute/lib/Types.sol#L31).

- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
  **Before**: `0x00000000000000000000000048f9f3190b7b5231cbf2ad1a1315af7f6a554020` <br/>
  **After**: `0x0000000000000000000000005062792ed6a85cf72a1424a1b7f39ed0f7972a4b` <br/>
  **Meaning**: Updates the CANNON game type implementation. Verify that the new implementation is set using `cast call 0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1 "gameImpls(uint32)(address)" 0`. Where `0` is the [`CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.6.0-rc.2/packages/contracts-bedrock/src/dispute/lib/Types.sol#L28).
