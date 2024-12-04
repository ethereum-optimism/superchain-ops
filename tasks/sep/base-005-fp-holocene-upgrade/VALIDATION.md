# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

The following state override should be seen:

### `0x0fe884546476dDd290eC46318785046ef68a0BA9` (Gnosis Safe `ProxyAdmin` owner)

Links:
- [Sepolia Etherscan](https://sepolia.etherscan.io/address/0x0fe884546476ddd290ec46318785046ef68a0ba9)

Overrides:
- **Key:**   `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** Enables the simulation by setting the signature threshold to 1. The key can be validated by the location of the `threshold` variable in 
  the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L14)

## State Changes

### `0x0fe884546476dDd290eC46318785046ef68a0BA9` (Gnosis Safe `ProxyAdmin` owner)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000009` <br/>
  **After**: `0x000000000000000000000000000000000000000000000000000000000000000a` <br/>
  **Meaning**: The nonce in slot `0x05` of the L1 Gnosis Safe `ProxyAdmin` owner is incremented from 9 to 10.

### `0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1` (`DisputeGameFactoryProxy`)

- **Key**: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b` <br/>
  **Before**: `0x0000000000000000000000005062792ed6a85cf72a1424a1b7f39ed0f7972a4b` <br/>
  **After**: `0x000000000000000000000000b7fb44a61fde2b9db28a84366e168b14d1a1b103` <br/>
  **Meaning**: Updates the CANNON game type implementation. Prior to this upgrade running, verify the old implementation is set using `cast call 0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1 "gameImpls(uint32)(address)" 0`. Where `0` is the [`CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L28). Once the upgrade has been executed, the same command should now return the new implementation address.

- **Key**: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e` <br/>
  **Before**: `0x000000000000000000000000593d20c4c69485b95d11507239be2c725ea2a6fd` <br/>
  **After**: `0x00000000000000000000000068f600e592799c16d1b096616edbf1681fb9c0de` <br/>
  **Meaning**: Updates the PERMISSIONED_CANNON game type implementation. Prior to this upgrade running, verify the old implementation is set using `cast call 0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1 "gameImpls(uint32)(address)" 1`. Where `1` is the [`PERMISSIONED_CANNON` game type](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.4.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L31). Once the upgrade has been executed, the same command should now return the new implementation address.