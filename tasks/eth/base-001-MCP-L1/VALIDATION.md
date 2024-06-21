# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

The following state overrides should be seen:

### `0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c` (`ProxyAdminOwner` Safe)

Links:
- [Etherscan](https://etherscan.io/address/0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c)

Enables the simulation by setting the threshold to 1:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`

## State Changes

**Notes:**
- The value `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` occurs
  multiple times below, and corresponds to the storage key of the implementation address as defined
  in [Proxy.sol](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/src/universal/Proxy.sol#L104) and [Constants.sol](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/src/libraries/Constants.sol#L26-L27). This is useful for [ERC-1967](https://eips.ethereum.org/EIPS/eip-1967) proxies.
- Check the provided links to ensure that the correct contract is described at the correct address. The superchain registry is the source of truth for contract addresses and etherscan is supplementary.

### `0x05cc379ebd9b30bba19c6fa282ab29218ec61d84` (`OptimismMintableERC20FactoryProxy`)

Links:
- [Etherscan](https://etherscan.io/address/0x05cc379ebd9b30bba19c6fa282ab29218ec61d84)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/3fb9d9b4c72183373447571e932ea01f6fef46e9/superchain/extra/addresses/mainnet/base.json#L7)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The `initialized` boolean is set to `true`. The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/OptimismMintableERC20Factory.json](https://github.com/ethereum-optimism/optimism/blob/e6ef3a900c42c8722e72c2e2314027f85d12ced5/packages/contracts-bedrock/snapshots/storageLayout/OptimismMintableERC20Factory.json#L2-L22).
   This state diff will only appear in contracts that were previously not initializable. Other contracts may be reinitialized but it does not show in the state diff because the storage diff is a noop.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000003154cf16ccdb4c6d922629664174b904d80f2c35` <br/>
  **Meaning:** Sets `bridge` at slot `0x01` (1). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/OptimismMintableERC20Factory.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/OptimismMintableERC20Factory.json#L24-L28). The address of the `L1StandardBridge` should be the value set in the slot, left padded with zero bytes to fill the slot. The address of the [L1StandardBridgeProxy](https://github.com/ethereum-optimism/superchain-registry/blob/645bb0a309970f3cc03ef6ff84670fc35917772a/superchain/extra/addresses/mainnet/base.json#L5) can be found in the Superchain Registry.

- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before:** `0x0000000000000000000000003d2c2f8f95caba644ea25319c4c08594b8dc0359` <br/>
  **After:** `0x000000000000000000000000e01efbeb1089d1d1db9c6c8b135c934c0734c846` <br/>
  **Meaning:** Implementation address is set to the new `OptimismMintableERC20Factory` implementation. The address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/implementations/networks/mainnet.yaml#L10).

### `0x3154Cf16ccdb4C6d922629664174b904d80F2C35` (`L1StandardBridgeProxy`)

Links:
- [Etherscan](https://etherscan.io/address/0x3154Cf16ccdb4C6d922629664174b904d80F2C35)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/f0ff9cdc7ee9a1181dea6612af6d78ad4be549c2/superchain/extra/addresses/mainnet/base.json#L5)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The `initialized` boolean is set to `true`. The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1StandardBridge.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1StandardBridge.json#L2-L22).
   This state diff will only appear in contracts that were previously not initializable. Other contracts may be reinitialized but it does not show in the state diff because the storage diff is a noop.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000003` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x000000000000000000000000866e82a600a1414e583f7f13623f1ac5d58b0afa` <br/>
  **Meaning:** Sets `messenger` at slot `0x03` (3). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1StandardBridge.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1StandardBridge.json#L38-L42). The address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5156b9582d0920624c61b63f1696bc624f37cc2e/superchain/extra/addresses/mainnet/base.json#L3).

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000004200000000000000000000000000000000000010` <br/>
  **Meaning:** Sets `otherBridge` at slot `0x04` (4). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1StandardBridge.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1StandardBridge.json#L45-L49). This should correspond to the L2StandardBridge predeploy address as seen in the [Optimism repo predeploys](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/op-bindings/predeploys/addresses.go#L13). The slot has left padding of zero bytes to fill the storage slot.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000032` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  **After:** `0x00000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c` <br/>
  **Meaning:** Sets `superchainConfig` at slot `0x32` (50). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1StandardBridge.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1StandardBridge.json#L58-L64). The `superchainConfig` address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/configs/mainnet/superchain.yaml#L8).

- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before:** `0x0000000000000000000000003f3c0f6bc115e698e35038e1759e9c31032e590c` <br/>
  **After:** `0x00000000000000000000000064b5a5ed26dcb17370ff4d33a8d503f0fbd06cff` <br/>
  **Meaning:** Implementation address is set to the new `L1StandardBridge`. The address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/implementations/networks/mainnet.yaml#L6).

### `0x49048044d57e1c92a77f79988d21fa8faf74e97e` (`OptimismPortalProxy`)

Links:
- [Etherscan](https://etherscan.io/address/0x49048044d57e1c92a77f79988d21fa8faf74e97e)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/3fb9d9b4c72183373447571e932ea01f6fef46e9/superchain/extra/addresses/mainnet/base.json#L8)

State Changes:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000035` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  TODO: verify that the trailing two 0s here are expected because of the storage offset.
  **After:** `0x000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c00` <br/>
  **Meaning:** Sets `superchainConfig` at slot `0x35` (53). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/OptimismPortal.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/OptimismPortal.json#L58-L64). The `superchainConfig` address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/configs/mainnet/superchain.yaml#L8).

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000036` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x00000000000000000000000056315b90c40730925ec5485cf004d835058518a0` <br/>
  **Meaning:** Sets `l2Oracle` at slot `0x36` (54). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/OptimismPortal.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/OptimismPortal.json#L66-L70). The `L2OutputOracleProxy` address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/3fb9d9b4c72183373447571e932ea01f6fef46e9/superchain/extra/addresses/mainnet/base.json#L6).

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000037` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x00000000000000000000000073a79fab69143498ed3712e519a88a918e1f4072` <br/>
  **Meaning:** Sets `systemConfig` at slot `0x37` (55). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/OptimismPortal.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/OptimismPortal.json#L73-L77). The `SystemConfigProxy` address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/3fb9d9b4c72183373447571e932ea01f6fef46e9/superchain/extra/addresses/mainnet/base.json#L10).

- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before:** `0x0000000000000000000000005fb30336a8d0841cf15d452afa297cb6d10877d7` <br/>
  **After:** `0x0000000000000000000000002d778797049fe9259d947d1ed8e5442226dfb589` <br/>
  **Meaning:** Implementation address is set to the new `OptimismPortal`. The implementation address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/implementations/networks/mainnet.yaml#L12).

### `0x56315b90c40730925ec5485cf004d835058518A0` (`L2OutputOracleProxy`)

Links:
- [Etherscan](https://etherscan.io/address/0x56315b90c40730925ec5485cf004d835058518A0)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/f0ff9cdc7ee9a1181dea6612af6d78ad4be549c2/superchain/extra/addresses/mainnet/base.json#L6)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000708` <br/>
  **Meaning:** Sets `submissionInterval` at slot `0x04` (4). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L2OutputOracle.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L2OutputOracle.json#L38-L42). `0x708` is 1800 in decimal, which matches the current value found by `cast call 0x56315b90c40730925ec5485cf004d835058518A0 "SUBMISSION_INTERVAL()(uint256)" -r https://ethereum.publicnode.com`.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000002` <br/>
  **Meaning:** Sets `l2BlockTime` at slot `0x05` (5). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L2OutputOracle.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L2OutputOracle.json#L45-L49). Units are in seconds, so the value should be 2 seconds to match the current value found by `cast call 0x56315b90c40730925ec5485cf004d835058518A0 "L2_BLOCK_TIME()(uint256)" -r https://ethereum.publicnode.com`.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000006` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000006f8c5ba3f59ea3e76300e3becdc231d656017824` <br/>
  **Meaning:** Sets `challenger` at slot `0x06` (6). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L2OutputOracle.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L2OutputOracle.json#L52-L56). This value matches the current address found by `cast call 0x56315b90c40730925ec5485cf004d835058518A0 "CHALLENGER()(address)" -r https://ethereum.publicnode.com`.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000007` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x000000000000000000000000642229f238fb9de03374be34b0ed8d9de80752c5` <br/>
  **Meaning:** Sets `proposer` at slot `0x07` (7). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L2OutputOracle.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L2OutputOracle.json#L59-L63). This value matches the current address found by `cast call 0x56315b90c40730925ec5485cf004d835058518A0 "PROPOSER()(address)" -r https://ethereum.publicnode.com`.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000008` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000093a80` <br/>
  **Meaning:** Sets `finalizationPeriodSeconds` at slot `0x08` (8). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L2OutputOracle.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L2OutputOracle.json#L66-L70). Units are in seconds, so the value should be `0x93a80` which is 604,800 in decimal. This value matches the current address found by `cast call 0x56315b90c40730925ec5485cf004d835058518A0 "FINALIZATION_PERIOD_SECONDS()(uint256)" -r https://ethereum.publicnode.com`

- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before:** `0x000000000000000000000000f2460d3433475c8008ceffe8283f07eb1447e39a` <br/>
  **After:** `0x000000000000000000000000f243bed163251380e78068d317ae10f26042b292` <br/>
  **Meaning:** Implementation address is set to the new `L2OutputOracle`. The address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/implementations/networks/mainnet.yaml#L8).

### `0x608d94945a64503e642e6370ec598e519a2c1e53` (`L1ERC721BridgeProxy`)

Links:
- [Etherscan](https://etherscan.io/address/0x608d94945a64503e642e6370ec598e519a2c1e53)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/f0ff9cdc7ee9a1181dea6612af6d78ad4be549c2/superchain/extra/addresses/mainnet/base.json#L4)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The `initialized` boolean is set to `true`. The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1ERC721Bridge.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1ERC721Bridge.json#L2-L22).
   This state diff will only appear in contracts that were previously not initializable. Other contracts are reinitialized but it does not show in the state diff because the storage diff is a noop.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x000000000000000000000000866e82a600a1414e583f7f13623f1ac5d58b0afa` <br/>
  **Meaning:** Sets `messenger` at slot `0x01` (1). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1ERC721Bridge.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1ERC721Bridge.json#L24-L28). The address of the [L1CrossDomainMessengerProxy](https://github.com/ethereum-optimism/superchain-registry/blob/3fb9d9b4c72183373447571e932ea01f6fef46e9/superchain/extra/addresses/mainnet/base.json#L3) should be in the slot with left padding to fill the storage slot.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000002` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000004200000000000000000000000000000000000014` <br/>
  **Meaning:** Sets `otherBridge` at slot `0x02` (2). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1ERC721Bridge.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1ERC721Bridge.json#L31-L35). This should correspond to the L2ERC721Bridge predeploy address as seen in the [Optimism repo predeploys](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/op-bindings/predeploys/addresses.go#L21). The slot has left padding of zero bytes to fill the storage slot.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000032` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  **After:** `0x00000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c` <br/>
  **Meaning:** Sets `superchainConfig` at slot `0x32` (50). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1ERC721Bridge.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1ERC721Bridge.json#L51-L57). The `superchainConfig` address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/3fb9d9b4c72183373447571e932ea01f6fef46e9/superchain/configs/mainnet/superchain.yaml#L8).

- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before:** `0x0000000000000000000000003311ac7f72bb4108d9f4d5d50e7623b1498a9ec0` <br/>
  **After:** `0x000000000000000000000000ae2af01232a6c4a4d3012c5ec5b1b35059caf10d` <br/>
  **Meaning:** The implementation address is set to the new `L1ERC721Bridge`. The address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/3fb9d9b4c72183373447571e932ea01f6fef46e9/superchain/implementations/networks/mainnet.yaml#L4).

### `0x73a79Fab69143498Ed3712e519A88a918e1f4072` (`SystemConfigProxy`)

Links:
- [Etherscan](https://etherscan.io/address/0x73a79Fab69143498Ed3712e519A88a918e1f4072)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/f0ff9cdc7ee9a1181dea6612af6d78ad4be549c2/superchain/extra/addresses/mainnet/base.json#L10)

State Changes:

Please ensure that each link to the `superchain-registry` correctly corresponds to Mainnet as the superchain registry contains data for
different chains. The `superchain-registry` is considered the source of truth for contract addresses across the superchain. To ensure
that the address actually matches the correct implementation, an Etherscan link is also provided for each.

[system-config-registry]: https://github.com/ethereum-optimism/superchain-registry/blob/3fb9d9b4c72183373447571e932ea01f6fef46e9/superchain/implementations/networks/mainnet.yaml#L13
[system-config-etherscan]: https://etherscan.io/address/0xba2492e52F45651B60B8B38d4Ea5E2390C64Ffb1
[l1-xdm-registry]: https://github.com/ethereum-optimism/superchain-registry/blob/3fb9d9b4c72183373447571e932ea01f6fef46e9/superchain/extra/addresses/mainnet/base.json#L3
[l1-xdm-etherscan]: https://etherscan.io/address/0x866E82a600A1414e583f7F13623F1aC5d58b0Afa
[l1-erc721-registry]: https://github.com/ethereum-optimism/superchain-registry/blob/3fb9d9b4c72183373447571e932ea01f6fef46e9/superchain/extra/addresses/mainnet/base.json#L4
[l1-erc721-etherscan]: https://etherscan.io/address/0x73a79Fab69143498Ed3712e519A88a918e1f4072
[portal-registry]: https://github.com/ethereum-optimism/superchain-registry/blob/3fb9d9b4c72183373447571e932ea01f6fef46e9/superchain/extra/addresses/mainnet/base.json#L8
[portal-etherscan]: https://etherscan.io/address/0x73a79Fab69143498Ed3712e519A88a918e1f4072
[batch-inbox-registry]: https://github.com/ethereum-optimism/superchain-registry/blob/3fb9d9b4c72183373447571e932ea01f6fef46e9/superchain/configs/mainnet/base.yaml#L11
[batch-inbox-etherscan]: https://etherscan.io/address/0xFf00000000000000000000000000000000008453
[l1-standard-bridge-registry]: https://github.com/ethereum-optimism/superchain-registry/blob/3fb9d9b4c72183373447571e932ea01f6fef46e9/superchain/extra/addresses/mainnet/base.json#L5
[l1-standard-bridge-etherscan]: https://etherscan.io/address/0x73a79Fab69143498Ed3712e519A88a918e1f4072
[factory-registry]: https://github.com/ethereum-optimism/superchain-registry/blob/3fb9d9b4c72183373447571e932ea01f6fef46e9/superchain/extra/addresses/mainnet/base.json#L7
[factory-etherscan]: https://etherscan.io/address/0x05cc379EBD9B30BbA19C6fA282AB29218EC61D84
[output-oracle-registry]: https://github.com/ethereum-optimism/superchain-registry/blob/3fb9d9b4c72183373447571e932ea01f6fef46e9/superchain/extra/addresses/mainnet/base.json#L6
[output-oracle-etherscan]: https://etherscan.io/address/0x56315b90c40730925ec5485cf004d835058518A0

- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before:** `0x0000000000000000000000006481ff79597fe4f77e1063f615ec5bdaddeffd4b` <br/>
  **After:** `0x000000000000000000000000ba2492e52f45651b60b8b38d4ea5e2390c64ffb1` <br/>
  **Meaning:** Implementation address is set to the new `SystemConfig` per the [Superchain Registry][system-config-registry] and [Etherscan][system-config-etherscan].

- **Key:** `0x383f291819e6d54073bc9a648251d97421076bdd101933c0c022219ce9580636` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x000000000000000000000000866e82a600a1414e583f7f13623f1ac5d58b0afa` <br/>
  **Meaning:** Sets `l1CrossDomainMessenger` address at slot per the [Superchain Registry][l1-xdm-registry]. This should be a proxy address per [Etherscan][l1-xdm-etherscan]. Verification of the key can be done by ensuring the result of the [L1_CROSS_DOMAIN_MESSENGER_SLOT](https://etherscan.io/address/0xba2492e52F45651B60B8B38d4Ea5E2390C64Ffb1#readContract#F2) getter on the implementation contract matches the key.

- **Key:** `0x46adcbebc6be8ce551740c29c47c8798210f23f7f4086c41752944352568d5a7` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x000000000000000000000000608d94945a64503e642e6370ec598e519a2c1e53` <br/>
  **Meaning:** Sets `l1ERC721Bridge` address at slot per the [Superchain Registry][l1-erc721-registry]. This should be a proxy address per [Etherscan][l1-erc721-etherscan]. Verification of the key can be done by ensuring the result of the [L1_ERC_721_BRIDGE_SLOT](https://etherscan.io/address/0xba2492e52F45651B60B8B38d4Ea5E2390C64Ffb1#readContract#F3) getter on the implementation contract matches the key.

- **Key:** `0x4b6c74f9e688cb39801f2112c14a8c57232a3fc5202e1444126d4bce86eb19ac` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x00000000000000000000000049048044d57e1c92a77f79988d21fa8faf74e97e` <br/>
  **Meaning:** Sets `optimismPortal` at slot per the [Superchain Registry][portal-registry]. This should be a proxy address per [Etherscan][portal-etherscan]. Verification of the key can be done by ensuring the result of the [OPTIMISM_PORTAL_SLOT](https://etherscan.io/address/0xba2492e52F45651B60B8B38d4Ea5E2390C64Ffb1#readContract#F7) getter on the implementation contract matches the key.

- **Key:** `0x71ac12829d66ee73d8d95bff50b3589745ce57edae70a3fb111a2342464dc597` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x000000000000000000000000ff00000000000000000000000000000000008453` <br/>
  **Meaning:** Sets `batchInbox` at slot per the [Superchain Registry][batch-inbox-registry]. This should be an address with no code per [Etherscan][batch-inbox-etherscan]. Verification of the key can be done by ensuring the result of the [BATCH_INBOX_SLOT](https://etherscan.io/address/0xba2492e52F45651B60B8B38d4Ea5E2390C64Ffb1#readContract#F1) getter on the implementation contract matches the key.

- **Key:** `0x9904ba90dde5696cda05c9e0dab5cbaa0fea005ace4d11218a02ac668dad6376` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000003154cf16ccdb4c6d922629664174b904d80f2c35` <br/>
  **Meaning:** Sets `l1StandardBridge` at slot per the [Superchain Registry][l1-standard-bridge-registry]. This should be a proxy address per [Etherscan][l1-standard-bridge-etherscan]. Verification of the key can be done by ensuring the result of the [L1_STANDARD_BRIDGE_SLOT](https://etherscan.io/address/0xba2492e52F45651B60B8B38d4Ea5E2390C64Ffb1#readContract#F4) getter on the implementation contract matches the key.

- **Key:** `0xa04c5bb938ca6fc46d95553abf0a76345ce3e722a30bf4f74928b8e7d852320c` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x00000000000000000000000005cc379ebd9b30bba19c6fa282ab29218ec61d84` <br/>
  **Meaning:** Sets `optimismMintableERC20Factory` at slot per the [Superchain Registry][factory-registry]. This should be a proxy address per [Etherscan][factory-etherscan]. Verification of the key can be done by ensuring the result of the [OPTIMISM_MINTABLE_ERC20_FACTORY_SLOT](https://etherscan.io/address/0xba2492e52F45651B60B8B38d4Ea5E2390C64Ffb1#readContract#F6) getter on the implementation contract matches the key.

- **Key:** `0xa11ee3ab75b40e88a0105e935d17cd36c8faee0138320d776c411291bdbbb19f` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x00000000000000000000000000000000000000000000000000000000010ac1a0` <br/>
  **Meaning:** Sets `startBlock` at slot to 17482144. This should be the block number at which the `SystemConfig` proxy was initialized for the first time. [Etherscan events](https://etherscan.io/address/0x73a79Fab69143498Ed3712e519A88a918e1f4072#events) shows twelve events have been emitted since contract creation in block 17482143, and that the first `Initialize` event after that should be in block 17482144. Verification of the key can be done by ensuring the result of the [START_BLOCK_SLOT](https://etherscan.io/address/0xba2492e52f45651b60b8b38d4ea5e2390c64ffb1#readContract#F8) getter on the implementation contract matches the key.

- **Key:** `0xe52a667f71ec761b9b381c7b76ca9b852adf7e8905da0e0ad49986a0a6871815` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x00000000000000000000000056315b90c40730925ec5485cf004d835058518a0` <br/>
  **Meaning:** Sets `l2OutputOracle` at slot per the [Superchain Registry][output-oracle-registry]. This should be a proxy per [Etherscan][output-oracle-etherscan]. Verification of the key can be done by ensuring the result of the [L2_OUTPUT_ORACLE_SLOT](https://etherscan.io/address/0xba2492e52F45651B60B8B38d4Ea5E2390C64Ffb1#readContract#F5) getter on the implementation contract matches the key.

### `0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c` (The 1 of 1 `ProxyAdminOwner` Safe)

Links:
- [Etherscan](https://etherscan.io/address/0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/f0ff9cdc7ee9a1181dea6612af6d78ad4be549c2/superchain/extra/addresses/mainnet/base.json#L11)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`<br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000002` <br/>
  **Meaning:** The Safe nonce is updated from `1` -> `2`.

### `0x866E82a600A1414e583f7F13623F1aC5d58b0Afa` (`L1CrossDomainMessengerProxy`)

Links:
- [Etherscan](https://etherscan.io/address/0x866E82a600A1414e583f7F13623F1aC5d58b0Afa)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/f0ff9cdc7ee9a1181dea6612af6d78ad4be549c2/superchain/extra/addresses/mainnet/base.json#L3)

State Changes:
- **Key:** `0x00000000000000000000000000000000000000000000000000000000000000cf` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:**  `0x0000000000000000000000004200000000000000000000000000000000000007` <br/>
  **Meaning:** Sets `otherMessenger` at slot `0xcf` (207). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1CrossDomainMessenger.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1CrossDomainMessenger.json#L115-L119). The `otherMessenger` address should be the the L2CrossDomainMessenger
   predeploy address as seen in the [Optimism repo predeploys](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/op-bindings/predeploys/addresses.go#L12). The slot has left padding of zero bytes to fill the storage slot.

- **Key:** `0x00000000000000000000000000000000000000000000000000000000000000fb` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:**  `0x00000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c` <br/>
  **Meaning:** Sets `SuperchainConfig` at slot `0xfb` (251). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1CrossDomainMessenger.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1CrossDomainMessenger.json#L128-L134). The `superchainConfig` address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/f0ff9cdc7ee9a1181dea6612af6d78ad4be549c2/superchain/configs/mainnet/superchain.yaml#L8).

- **Key:** `0x00000000000000000000000000000000000000000000000000000000000000fc` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:**  `0x00000000000000000000000049048044d57e1c92a77f79988d21fa8faf74e97e` <br/>
  **Meaning:** Sets `OptimismPortal` at slot `0xfc` (252). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1CrossDomainMessenger.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1CrossDomainMessenger.json#L136-L140). The `OptimismPortal` address can be found [here](https://github.com/ethereum-optimism/superchain-registry/blob/f0ff9cdc7ee9a1181dea6612af6d78ad4be549c2/superchain/extra/addresses/mainnet/base.json#L8).

### `0x8efb6b5c4767b09dc9aa6af4eaa89f749522bae2` (`AddressManager`)

Links:
- [Etherscan](https://etherscan.io/address/0x8efb6b5c4767b09dc9aa6af4eaa89f749522bae2)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/f0ff9cdc7ee9a1181dea6612af6d78ad4be549c2/superchain/extra/addresses/mainnet/base.json#L2)

State Changes:
- **Key:** `0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e` <br/>
  **Before:** `0x00000000000000000000000081c4bd600793ebd1c0323604e1f455fe50a951f8` <br/>
  **After:** `0x000000000000000000000000d3494713a5cfad3f5359379dfa074e2ac8c6fd65` <br/>
  **Meaning:** The name `OVM_L1CrossDomainMessenger` is set to the address of the new `L1CrossDomainMessenger` [implementation](https://github.com/ethereum-optimism/superchain-registry/blob/f0ff9cdc7ee9a1181dea6612af6d78ad4be549c2/superchain/implementations/networks/mainnet.yaml#L2). This key is complicated to compute, so instead we attest to correctness of the key by verifying that the "Before" value currently exists in that slot, as explained below.
  **Before** address matches both of the following cast calls (please consider changing out the rpc
  url):
  1. what is returned by calling `AddressManager.getAddress()`:
   ```
   cast call 0x8efb6b5c4767b09dc9aa6af4eaa89f749522bae2 'getAddress(string)(address)' 'OVM_L1CrossDomainMessenger' --rpc-url https://ethereum.publicnode.com
   ```
  2. what is currently stored at the key:
   ```
   cast storage 0x8efb6b5c4767b09dc9aa6af4eaa89f749522bae2 0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e --rpc-url https://ethereum.publicnode.com
   ```

The only other state change is a nonce increment of the owner on the safe that sent the transaction.
If simulating it will be `0x9855054731540a48b28990b63dcf4f33d8ae46a1`, but if your ledger is
connected it may be a different one of the safe's owners.
