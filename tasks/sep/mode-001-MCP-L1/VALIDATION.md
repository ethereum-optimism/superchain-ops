# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

The following state overrides should be seen:

### `0xE75Cd021F520B160BF6b54D472Fa15e52aFe5aDD` (The 1 of 1 `ProxyAdmin` owner Safe)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0xE75Cd021F520B160BF6b54D472Fa15e52aFe5aDD)

Enables the simulation by setting the threshold to 1:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`

## State Changes

**Notes:**
- The value `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` occurs
  multiple times below, and corresponds to the storage key of the implementation address as defined
  in [Proxy.sol](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/src/universal/Proxy.sol#L104) and [Constants.sol](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/src/libraries/Constants.sol#L26-L27). This is useful for [ERC-1967](https://eips.ethereum.org/EIPS/eip-1967) proxies.
- Check the provided links to ensure that the correct contract is described at the correct address. The superchain registry is the source of truth for contract addresses and etherscan is supplementary.

### `0x00F7ab8c72D32f55cFf15e8901C2F9f2BF29A3C0` (`OptimismMintableERC20FactoryProxy`)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0x00F7ab8c72D32f55cFf15e8901C2F9f2BF29A3C0)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/extra/addresses/sepolia/mode.json#L7)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The `initialized` boolean is set to `true`. The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/OptimismMintableERC20Factory.json](https://github.com/ethereum-optimism/optimism/blob/e6ef3a900c42c8722e72c2e2314027f85d12ced5/packages/contracts-bedrock/snapshots/storageLayout/OptimismMintableERC20Factory.json#L2-L22).
   This state diff will only appear in contracts that were previously not initializable. Other contracts may be reinitialized but it does not show in the state diff because the storage diff is a noop.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x000000000000000000000000bc5c679879b2965296756cd959c3c739769995e2` <br/>
  **Meaning:** Sets `bridge` at slot `0x01` (1). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/OptimismMintableERC20Factory.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/OptimismMintableERC20Factory.json#L24-L28). The address of the `L1StandardBridge` should be the value set in the slot, left padded with zero bytes to fill the slot. The address of the [L1StandardBridgeProxy](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/extra/addresses/sepolia/mode.json#L5) can be found in the Superchain Registry.

- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before:** `0x0000000000000000000000000f5908861962dffab7e4d9a1c9f513f1988e8dcc` <br/>
  **After:** `0x000000000000000000000000e01efbeb1089d1d1db9c6c8b135c934c0734c846` <br/>
  **Meaning:** Implementation address is set to the new `OptimismMintableERC20Factory` implementation. The address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/implementations/networks/sepolia.yaml#L10).

### `0x015a8c2e0a5fEd579dbb05fd290e413Adc6FC24A` (`L1ERC721BridgeProxy`)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0x015a8c2e0a5fEd579dbb05fd290e413Adc6FC24A)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/extra/addresses/sepolia/mode.json#L4)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The `initialized` boolean is set to `true`. The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1ERC721Bridge.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1ERC721Bridge.json#L2-L22).
   This state diff will only appear in contracts that were previously not initializable. Other contracts are reinitialized but it does not show in the state diff because the storage diff is a noop.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x000000000000000000000000c19a60d9e8c27b9a43527c3283b4dd8edc8be15c` <br/>
  **Meaning:** Sets `messenger` at slot `0x01` (1). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1ERC721Bridge.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1ERC721Bridge.json#L24-L28). The address of the [L1CrossDomainMessengerProxy](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/extra/addresses/sepolia/mode.json#L3) should be in the slot with left padding to fill the storage slot.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000002` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000004200000000000000000000000000000000000014` <br/>
  **Meaning:** Sets `otherBridge` at slot `0x02` (2). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1ERC721Bridge.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1ERC721Bridge.json#L31-L35). This should correspond to the L2ERC721Bridge predeploy address as seen in the [Optimism repo predeploys](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/op-bindings/predeploys/addresses.go#L21). The slot has left padding of zero bytes to fill the storage slot.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000032` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  **After:** `0x000000000000000000000000c2be75506d5724086deb7245bd260cc9753911be` <br/>
  **Meaning:** Sets `superchainConfig` at slot `0x32` (50). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1ERC721Bridge.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1ERC721Bridge.json#L51-L57). The `superchainConfig` address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/configs/sepolia/superchain.yaml#L8).

- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before:** `0x0000000000000000000000007bf471d9181ad783c7510243d1b0ebc6f29e9a81` <br/>
  **After:** `0x000000000000000000000000ae2af01232a6c4a4d3012c5ec5b1b35059caf10d` <br/>
  **Meaning:** The implementation address is set to the new `L1ERC721Bridge`. The address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/implementations/networks/sepolia.yaml#L4).

### `0x15cd4f6e0CE3B4832B33cB9c6f6Fe6fc246754c2` (`SystemConfigProxy`)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0x15cd4f6e0CE3B4832B33cB9c6f6Fe6fc246754c2)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/extra/addresses/sepolia/mode.json#L9)

State Changes:

Please ensure that each link to the `superchain-registry` correctly corresponds to Sepolia as the superchain registry contains data for
different chains. The `superchain-registry` is considered the source of truth for contract addresses across the superchain. To ensure
that the address actually matches the correct implementation, an Etherscan link is also provided for each.

[system-config-registry]: https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/implementations/networks/sepolia.yaml#L14
[system-config-etherscan]: https://sepolia.etherscan.io/address/0xba2492e52F45651B60B8B38d4Ea5E2390C64Ffb1
[l1-xdm-registry]: https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/extra/addresses/sepolia/mode.json#L3
[l1-xdm-etherscan]: https://sepolia.etherscan.io/address/0xc19a60d9E8C27B9A43527c3283B4dd8eDC8bE15C
[l1-erc721-registry]: https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/extra/addresses/sepolia/mode.json#L4
[l1-erc721-etherscan]: https://sepolia.etherscan.io/address/0x015a8c2e0a5fEd579dbb05fd290e413Adc6FC24A
[portal-registry]: https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/extra/addresses/sepolia/mode.json#L8
[portal-etherscan]: https://sepolia.etherscan.io/address/0x320e1580effF37E008F1C92700d1eBa47c1B23fD
[batch-inbox-registry]: https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/configs/sepolia/mode.yaml#L9
[batch-inbox-etherscan]: https://sepolia.etherscan.io/address/0x24567B64a86A4c966655fba6502a93dFb701E316
[l1-standard-bridge-registry]: https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/extra/addresses/sepolia/mode.json#L5
[l1-standard-bridge-etherscan]: https://sepolia.etherscan.io/address/0xbC5C679879B2965296756CD959C3C739769995E2
[factory-registry]: https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/extra/addresses/sepolia/mode.json#L7
[factory-etherscan]: https://sepolia.etherscan.io/address/0x00F7ab8c72D32f55cFf15e8901C2F9f2BF29A3C0
[output-oracle-registry]: https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/extra/addresses/sepolia/mode.json#L6
[output-oracle-etherscan]: https://sepolia.etherscan.io/address/0x2634BD65ba27AB63811c74A63118ACb312701Bfa

- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before:** `0x0000000000000000000000002238382dcea03f024993c8a0355917c80b20301f` <br/>
  **After:** `0x000000000000000000000000ba2492e52f45651b60b8b38d4ea5e2390c64ffb1` <br/>
  **Meaning:** Implementation address is set to the new `SystemConfig` per the [Superchain Registry][system-config-registry] and [Etherscan][system-config-etherscan].

- **Key:** `0x383f291819e6d54073bc9a648251d97421076bdd101933c0c022219ce9580636` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x000000000000000000000000c19a60d9e8c27b9a43527c3283b4dd8edc8be15c` <br/>
  **Meaning:** Sets `l1CrossDomainMessenger` address at slot per the [Superchain Registry][l1-xdm-registry]. This should be a proxy address per [Etherscan][l1-xdm-etherscan]. Verification of the key can be done by ensuring the result of the [L1_CROSS_DOMAIN_MESSENGER_SLOT](https://sepolia.etherscan.io/address/0xba2492e52F45651B60B8B38d4Ea5E2390C64Ffb1#readContract#F2) getter on the implementation contract matches the key.

- **Key:** `0x46adcbebc6be8ce551740c29c47c8798210f23f7f4086c41752944352568d5a7` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x000000000000000000000000015a8c2e0a5fed579dbb05fd290e413adc6fc24a` <br/>
  **Meaning:** Sets `l1ERC721Bridge` address at slot per the [Superchain Registry][l1-erc721-registry]. This should be a proxy address per [Etherscan][l1-erc721-etherscan]. Verification of the key can be done by ensuring the result of the [L1_ERC_721_BRIDGE_SLOT](https://sepolia.etherscan.io/address/0xba2492e52F45651B60B8B38d4Ea5E2390C64Ffb1#readContract#F3) getter on the implementation contract matches the key.

- **Key:** `0x4b6c74f9e688cb39801f2112c14a8c57232a3fc5202e1444126d4bce86eb19ac` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x000000000000000000000000320e1580efff37e008f1c92700d1eba47c1b23fd` <br/>
  **Meaning:** Sets `optimismPortal` at slot per the [Superchain Registry][portal-registry]. This should be a proxy address per [Etherscan][portal-etherscan]. Verification of the key can be done by ensuring the result of the [OPTIMISM_PORTAL_SLOT](https://sepolia.etherscan.io/address/0xba2492e52F45651B60B8B38d4Ea5E2390C64Ffb1#readContract#F7) getter on the implementation contract matches the key.

- **Key:** `0x71ac12829d66ee73d8d95bff50b3589745ce57edae70a3fb111a2342464dc597` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x000000000000000000000000cddae6148da1e003c230e4527f9baedc8a204e7e` <br/>
  **Meaning:** Sets `batchInbox` at slot per the [Superchain Registry][batch-inbox-registry]. This should be an address with no code per [Etherscan][batch-inbox-etherscan]. Verification of the key can be done by ensuring the result of the [BATCH_INBOX_SLOT](https://sepolia.etherscan.io/address/0xba2492e52F45651B60B8B38d4Ea5E2390C64Ffb1#readContract#F1) getter on the implementation contract matches the key.

- **Key:** `0x9904ba90dde5696cda05c9e0dab5cbaa0fea005ace4d11218a02ac668dad6376` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x000000000000000000000000bc5c679879b2965296756cd959c3c739769995e2` <br/>
  **Meaning:** Sets `l1StandardBridge` at slot per the [Superchain Registry][l1-standard-bridge-registry]. This should be a proxy address per [Etherscan][l1-standard-bridge-etherscan]. Verification of the key can be done by ensuring the result of the [L1_STANDARD_BRIDGE_SLOT](https://sepolia.etherscan.io/address/0xba2492e52F45651B60B8B38d4Ea5E2390C64Ffb1#readContract#F4) getter on the implementation contract matches the key.

- **Key:** `0xa04c5bb938ca6fc46d95553abf0a76345ce3e722a30bf4f74928b8e7d852320c` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x00000000000000000000000000f7ab8c72d32f55cff15e8901c2f9f2bf29a3c0` <br/>
  **Meaning:** Sets `optimismMintableERC20Factory` at slot per the [Superchain Registry][factory-registry]. This should be a proxy address per [Etherscan][factory-etherscan]. Verification of the key can be done by ensuring the result of the [OPTIMISM_MINTABLE_ERC20_FACTORY_SLOT](https://sepolia.etherscan.io/address/0xba2492e52F45651B60B8B38d4Ea5E2390C64Ffb1#readContract#F6) getter on the implementation contract matches the key.

- **Key:** `0xa11ee3ab75b40e88a0105e935d17cd36c8faee0138320d776c411291bdbbb19f` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x000000000000000000000000000000000000000000000000000000000039a76e` <br/>
  **Meaning:** Sets `startBlock` at slot to 3778414. This should be the block number at which the `SystemConfig` proxy was initialized for the first time. [Etherscan events](https://sepolia.etherscan.io/address/0x15cd4f6e0CE3B4832B33cB9c6f6Fe6fc246754c2#events) shows only five events have been emitted since contract creation in block 3778398, and that the first `Initialize` event after that should be in block 3778414. Verification of the key can be done by ensuring the result of the [START_BLOCK_SLOT](https://sepolia.etherscan.io/address/0xba2492e52F45651B60B8B38d4Ea5E2390C64Ffb1#readContract#F8) getter on the implementation contract matches the key.

- **Key:** `0xe52a667f71ec761b9b381c7b76ca9b852adf7e8905da0e0ad49986a0a6871815` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000002634bd65ba27ab63811c74a63118acb312701bfa` <br/>
  **Meaning:** Sets `l2OutputOracle` at slot per the [Superchain Registry][output-oracle-registry]. This should be a proxy per [Etherscan][output-oracle-etherscan]. Verification of the key can be done by ensuring the result of the [L2_OUTPUT_ORACLE_SLOT](https://sepolia.etherscan.io/address/0xba2492e52F45651B60B8B38d4Ea5E2390C64Ffb1#readContract#F5) getter on the implementation contract matches the key.

### `0x2634BD65ba27AB63811c74A63118ACb312701Bfa` (`L2OutputOracleProxy`)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0x2634BD65ba27AB63811c74A63118ACb312701Bfa)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/extra/addresses/sepolia/mode.json#L6)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x00000000000000000000000000000000000000000000000000000000000000b4` <br/>
  **Meaning:** Sets `submissionInterval` at slot `0x04` (4). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L2OutputOracle.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L2OutputOracle.json#L38-L42). `0xb4` is 180 in decimal, which matches the current value found by `cast call 0x2634BD65ba27AB63811c74A63118ACb312701Bfa "SUBMISSION_INTERVAL()(uint256)" -r https://ethereum-sepolia.publicnode.com`.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000002` <br/>
  **Meaning:** Sets `l2BlockTime` at slot `0x05` (5). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L2OutputOracle.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L2OutputOracle.json#L45-L49). Units are in seconds, so the value should be 2 seconds to match the current value found by `cast call 0x2634BD65ba27AB63811c74A63118ACb312701Bfa "L2_BLOCK_TIME()(uint256)" -r https://ethereum-sepolia.publicnode.com`.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000006` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x00000000000000000000000045effbd799ab49122eeeab75b78d9c56a187f9a7` <br/>
  **Meaning:** Sets `challenger` at slot `0x06` (6). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L2OutputOracle.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L2OutputOracle.json#L52-L56). This value matches the current address found by `cast call 0x2634BD65ba27AB63811c74A63118ACb312701Bfa "CHALLENGER()(address)" -r https://ethereum-sepolia.publicnode.com`.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000007` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x000000000000000000000000e9e08a478e3a773c1b5d59014a0fdb901e6d1d69` <br/>
  **Meaning:** Sets `proposer` at slot `0x07` (7). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L2OutputOracle.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L2OutputOracle.json#L59-L63). This value matches the current address found by `cast call 0x2634BD65ba27AB63811c74A63118ACb312701Bfa "PROPOSER()(address)" -r https://ethereum-sepolia.publicnode.com`.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000008` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x00000000000000000000000000000000000000000000000000000000000000b4` <br/>
  **Meaning:** Sets `finalizationPeriodSeconds` at slot `0x08` (8). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L2OutputOracle.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L2OutputOracle.json#L66-L70). Units are in seconds, so the value should be `0xb4` which is 180 in decimal. This value matches the current address found by `cast call 0x2634BD65ba27AB63811c74A63118ACb312701Bfa "FINALIZATION_PERIOD_SECONDS()(uint256)" -r https://ethereum-sepolia.publicnode.com`

- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before:** `0x000000000000000000000000eebd920ae8444c4f5d6ad07879ccbeb53663d93a` <br/>
  **After:** `0x000000000000000000000000f243bed163251380e78068d317ae10f26042b292` <br/>
  **Meaning:** Implementation address is set to the new `L2OutputOracle`. The address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/implementations/networks/sepolia.yaml#L8).

### `0x320e1580effF37E008F1C92700d1eBa47c1B23fD` (`OptimismPortalProxy`)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0x320e1580effF37E008F1C92700d1eBa47c1B23fD)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/extra/addresses/sepolia/mode.json#L8)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000035` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000c2be75506d5724086deb7245bd260cc9753911be00` <br/>
  **Meaning:** Sets `superchainConfig` at slot `0x35` (53). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/OptimismPortal.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/OptimismPortal.json#L58-L64). The `superchainConfig` address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/configs/sepolia/superchain.yaml#L8).

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000036` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000002634bd65ba27ab63811c74a63118acb312701bfa` <br/>
  **Meaning:** Sets `l2Oracle` at slot `0x36` (54). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/OptimismPortal.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/OptimismPortal.json#L66-L70). The `L2OutputOracleProxy` address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/extra/addresses/sepolia/mode.json#L6).

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000037` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x00000000000000000000000015cd4f6e0ce3b4832b33cb9c6f6fe6fc246754c2` <br/>
  **Meaning:** Sets `systemConfig` at slot `0x37` (55). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/OptimismPortal.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/OptimismPortal.json#L73-L77). The `SystemConfigProxy` address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/extra/addresses/sepolia/mode.json#L9).

- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before:** `0x000000000000000000000000d9b9dce20d7837379cbd4fa1a58bc70e595bb9a5` <br/>
  **After:** `0x0000000000000000000000002d778797049fe9259d947d1ed8e5442226dfb589` <br/>
  **Meaning:** Implementation address is set to the new `OptimismPortal`. The implementation address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/implementations/networks/sepolia.yaml#L12).

### `0x83D45725d6562d8CD717673D6bb4c67C07dC1905` (`AddressManager`)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0x83D45725d6562d8CD717673D6bb4c67C07dC1905)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/extra/addresses/sepolia/mode.json#L2)

State Changes:
- **Key:** `0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e` <br/>
  **Before:** `0x0000000000000000000000009b800c1e8b61aa9d141bcd317dde7849f7a043e5` <br/>
  **After:** `0x000000000000000000000000d3494713a5cfad3f5359379dfa074e2ac8c6fd65` <br/>
  **Meaning:** The name `OVM_L1CrossDomainMessenger` is set to the address of the new `L1CrossDomainMessenger` [implementation](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/implementations/networks/sepolia.yaml#L2). This key is complicated to compute, so instead we attest to correctness of the key by verifying that the "Before" value currently exists in that slot, as explained below.
  **Before** address matches both of the following cast calls (please consider changing out the rpc
  url):
  1. what is returned by calling `AddressManager.getAddress()`:
   ```
   cast call 0x83D45725d6562d8CD717673D6bb4c67C07dC1905 'getAddress(string)(address)' 'OVM_L1CrossDomainMessenger' --rpc-url https://ethereum-sepolia.publicnode.com
   ```
  2. what is currently stored at the key:
   ```
   cast storage 0x83D45725d6562d8CD717673D6bb4c67C07dC1905 0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e --rpc-url https://ethereum-sepolia.publicnode.com
   ```

### `0xbC5C679879B2965296756CD959C3C739769995E2` (`L1StandardBridgeProxy`)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0xbC5C679879B2965296756CD959C3C739769995E2)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/extra/addresses/sepolia/mode.json#L5)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The `initialized` boolean is set to `true`. The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1StandardBridge.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1StandardBridge.json#L2-L22).
   This state diff will only appear in contracts that were previously not initializable. Other contracts may be reinitialized but it does not show in the state diff because the storage diff is a noop.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000003` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x000000000000000000000000c19a60d9e8c27b9a43527c3283b4dd8edc8be15c` <br/>
  **Meaning:** Sets `messenger` at slot `0x03` (3). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1StandardBridge.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1StandardBridge.json#L38-L42). The address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/extra/addresses/sepolia/mode.json#L3).

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000004200000000000000000000000000000000000010` <br/>
  **Meaning:** Sets `otherBridge` at slot `0x04` (4). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1StandardBridge.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1StandardBridge.json#L45-L49). This should correspond to the L2StandardBridge predeploy address as seen in the [Optimism repo predeploys](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/op-bindings/predeploys/addresses.go#L13). The slot has left padding of zero bytes to fill the storage slot.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000032` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  **After:** `0x000000000000000000000000c2be75506d5724086deb7245bd260cc9753911be` <br/>
  **Meaning:** Sets `superchainConfig` at slot `0x32` (50). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1StandardBridge.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1StandardBridge.json#L58-L64). The `superchainConfig` address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/configs/sepolia/superchain.yaml#L8).

- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before:** `0x00000000000000000000000098c41994f0b4dccd52fad6bfea6615de34c2ce0f` <br/>
  **After:** `0x00000000000000000000000064b5a5ed26dcb17370ff4d33a8d503f0fbd06cff` <br/>
  **Meaning:** Implementation address is set to the new `L1StandardBridge`. The address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/implementations/networks/sepolia.yaml#L6).

### `0xc19a60d9E8C27B9A43527c3283B4dd8eDC8bE15C` (`L1CrossDomainMessengerProxy`)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0xc19a60d9E8C27B9A43527c3283B4dd8eDC8bE15C)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/extra/addresses/sepolia/mode.json#L3)

State Changes:
- **Key:** `0x00000000000000000000000000000000000000000000000000000000000000cf` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:**  `0x0000000000000000000000004200000000000000000000000000000000000007` <br/>
  **Meaning:** Sets `otherMessenger` at slot `0xcf` (207). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1CrossDomainMessenger.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1CrossDomainMessenger.json#L115-L119). The `otherMessenger` address should be the the L2CrossDomainMessenger
   predeploy address as seen in the [Optimism repo predeploys](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/op-bindings/predeploys/addresses.go#L12). The slot has left padding of zero bytes to fill the storage slot.

- **Key:** `0x00000000000000000000000000000000000000000000000000000000000000fb` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:**  `0x000000000000000000000000c2be75506d5724086deb7245bd260cc9753911be` <br/>
  **Meaning:** Sets `SuperchainConfig` at slot `0xfb` (251). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1CrossDomainMessenger.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1CrossDomainMessenger.json#L128-L134). The `superchainConfig` address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/configs/sepolia/superchain.yaml#L8).

- **Key:** `0x00000000000000000000000000000000000000000000000000000000000000fc` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:**  `0x000000000000000000000000320e1580efff37e008f1c92700d1eba47c1b23fd` <br/>
  **Meaning:** Sets `OptimismPortal` at slot `0xfc` (252). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1CrossDomainMessenger.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1CrossDomainMessenger.json#L136-L140). The `OptimismPortal` address can be found [here](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/extra/addresses/sepolia/mode.json#L8).

### `0xE75Cd021F520B160BF6b54D472Fa15e52aFe5aDD` (The 1 of 1 `ProxyAdmin` owner Safe)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0xE75Cd021F520B160BF6b54D472Fa15e52aFe5aDD)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/extra/addresses/sepolia/mode.json#L10)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`<br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The Safe nonce is updated.

The only other state change is a nonce increment of `0xefCf0c8faFB425997870f845e26fC6cA6EE6dD5C`,
which is the account sending the transaction and is the only signer on the safe.
