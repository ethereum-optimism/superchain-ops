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


### `0x16b0a4f451c4cb567703367e587e15ac108e4311` (`L1ERC721BridgeProxy`)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0x16b0a4f451c4cb567703367e587e15ac108e4311)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/4156733e723282b632a5743ac3064710caea03d4/superchain/extra/addresses/sepolia/zora.json#L4)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The `initialized` boolean is set to `true`. The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1ERC721Bridge.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1ERC721Bridge.json#L2-L22).
   This state diff will only appear in contracts that were previously not initializable. Other contracts are reinitialized but it does not show in the state diff because the storage diff is a noop.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000001bdbc0ae22bec0c2f08b4dd836944b3e28fe9b7a` <br/>
  **Meaning:** Sets `messenger` at slot `0x01` (1). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1ERC721Bridge.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1ERC721Bridge.json#L24-L28). The address of the [L1CrossDomainMessengerProxy](https://github.com/ethereum-optimism/superchain-registry/blob/4156733e723282b632a5743ac3064710caea03d4/superchain/extra/addresses/sepolia/zora.json#L3) should be in the slot with left padding to fill the storage slot.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000002` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000004200000000000000000000000000000000000014` <br/>
  **Meaning:** Sets `otherBridge` at slot `0x02` (2). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1ERC721Bridge.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1ERC721Bridge.json#L31-L35). This should correspond to the L2ERC721Bridge predeploy address as seen in the [Optimism repo predeploys](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/op-bindings/predeploys/addresses.go#L21). The slot has left padding of zero bytes to fill the storage slot.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000032` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  **After:** `0x000000000000000000000000c2be75506d5724086deb7245bd260cc9753911be` <br/>
  **Meaning:** Sets `superchainConfig` at slot `0x32` (50). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1ERC721Bridge.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1ERC721Bridge.json#L51-L57). The `superchainConfig` address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/4156733e723282b632a5743ac3064710caea03d4/superchain/configs/sepolia/superchain.yaml#L8).

- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before:** `0x000000000000000000000000463ad1d9e283f920306a04d195bca9f88c89d30e` <br/>
  **After:** `0x000000000000000000000000ae2af01232a6c4a4d3012c5ec5b1b35059caf10d` <br/>
  **Meaning:** The implementation address is set to the new `L1ERC721Bridge`. The address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/4156733e723282b632a5743ac3064710caea03d4/superchain/implementations/networks/sepolia.yaml#L4).

### `0x1bDBC0ae22bEc0c2f08B4dd836944b3E28fe9b7A` (`L1CrossDomainMessengerProxy`)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0x1bDBC0ae22bEc0c2f08B4dd836944b3E28fe9b7A)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/4156733e723282b632a5743ac3064710caea03d4/superchain/extra/addresses/sepolia/zora.json#L3)

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
  **After:**  `0x000000000000000000000000effe2c6ca9ab797d418f0d91ea60807713f3536f` <br/>
  **Meaning:** Sets `OptimismPortal` at slot `0xfc` (252). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1CrossDomainMessenger.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1CrossDomainMessenger.json#L136-L140). The `OptimismPortal` address can be found [here](https://github.com/ethereum-optimism/superchain-registry/blob/4156733e723282b632a5743ac3064710caea03d4/superchain/extra/addresses/sepolia/zora.json#L8).

### `0x2615B481Bd3E5A1C0C7Ca3Da1bdc663E8615Ade9` (`L2OutputOracleProxy`)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0x2615B481Bd3E5A1C0C7Ca3Da1bdc663E8615Ade9)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/4156733e723282b632a5743ac3064710caea03d4/superchain/extra/addresses/sepolia/zora.json#L6C27-L6C69)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x00000000000000000000000000000000000000000000000000000000000000b4` <br/>
  **Meaning:** Sets `submissionInterval` at slot `0x04` (4). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L2OutputOracle.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L2OutputOracle.json#L38-L42). `0xb4` is 180 in decimal, which matches the current value found by `cast call 0x2615B481Bd3E5A1C0C7Ca3Da1bdc663E8615Ade9 "SUBMISSION_INTERVAL()(uint256)" -r https://ethereum-sepolia.publicnode.com`.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000002` <br/>
  **Meaning:** Sets `l2BlockTime` at slot `0x05` (5). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L2OutputOracle.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L2OutputOracle.json#L45-L49). Units are in seconds, so the value should be 2 seconds to match the current value found by `cast call 0x2615B481Bd3E5A1C0C7Ca3Da1bdc663E8615Ade9 "L2_BLOCK_TIME()(uint256)" -r https://ethereum-sepolia.publicnode.com`.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000006` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x00000000000000000000000045effbd799ab49122eeeab75b78d9c56a187f9a7` <br/>
  **Meaning:** Sets `challenger` at slot `0x06` (6). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L2OutputOracle.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L2OutputOracle.json#L52-L56). This value matches the current address found by `cast call 0x2615B481Bd3E5A1C0C7Ca3Da1bdc663E8615Ade9 "CHALLENGER()(address)" -r https://ethereum-sepolia.publicnode.com`.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000007` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x000000000000000000000000e8326a5839175de7f467e66d8bb443aa70da1c3e` <br/>
  **Meaning:** Sets `proposer` at slot `0x07` (7). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L2OutputOracle.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L2OutputOracle.json#L59-L63). This value matches the current address found by `cast call 0x2615B481Bd3E5A1C0C7Ca3Da1bdc663E8615Ade9 "PROPOSER()(address)" -r https://ethereum-sepolia.publicnode.com`.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000008` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000093a80` <br/>
  **Meaning:** Sets `finalizationPeriodSeconds` at slot `0x08` (8). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L2OutputOracle.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L2OutputOracle.json#L66-L70). Units are in seconds, so the value should be `0x93a80` which is 604,800 in decimal. This value matches the current address found by `cast call 0x2615B481Bd3E5A1C0C7Ca3Da1bdc663E8615Ade9 "FINALIZATION_PERIOD_SECONDS()(uint256)" -r https://ethereum-sepolia.publicnode.com`

- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before:** `0x00000000000000000000000005f3b4588b00bacb7808c54126072f5907fdc21a` <br/>
  **After:** `0x000000000000000000000000f243bed163251380e78068d317ae10f26042b292` <br/>
  **Meaning:** Implementation address is set to the new `L2OutputOracle`. The address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/implementations/networks/sepolia.yaml#L8).

### `0x27c9392144DFcB6dab113F737356C32435cD1D55` (`AddressManager`)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0x27c9392144DFcB6dab113F737356C32435cD1D55)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/4156733e723282b632a5743ac3064710caea03d4/superchain/extra/addresses/sepolia/zora.json#L2C22-L2C64)

State Changes:
- **Key:** `0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e` <br/>
  **Before:** `0x00000000000000000000000044173eff58cc8946ffc28faef4abd710e5da7d24` <br/>
  **After:** `0x000000000000000000000000d3494713a5cfad3f5359379dfa074e2ac8c6fd65` <br/>
  **Meaning:** The name `OVM_L1CrossDomainMessenger` is set to the address of the new `L1CrossDomainMessenger` [implementation](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/implementations/networks/sepolia.yaml#L2). This key is complicated to compute, so instead we attest to correctness of the key by verifying that the "Before" value currently exists in that slot, as explained below.
  **Before** address matches both of the following cast calls (please consider changing out the rpc
  url):
  1. what is returned by calling `AddressManager.getAddress()`:
   ```
   cast call 0x27c9392144DFcB6dab113F737356C32435cD1D55 'getAddress(string)(address)' 'OVM_L1CrossDomainMessenger' --rpc-url https://ethereum-sepolia.publicnode.com
   ```
  2. what is currently stored at the key:
   ```
   cast storage 0x27c9392144DFcB6dab113F737356C32435cD1D55 0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e --rpc-url https://ethereum-sepolia.publicnode.com
   ```

### `0x5376f1D543dcbB5BD416c56C189e4cB7399fCcCB` (`L1StandardBridgeProxy`)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0x5376f1D543dcbB5BD416c56C189e4cB7399fCcCB)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/4156733e723282b632a5743ac3064710caea03d4/superchain/extra/addresses/sepolia/zora.json#L5C29-L5C71)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The `initialized` boolean is set to `true`. The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1StandardBridge.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1StandardBridge.json#L2-L22).
   This state diff will only appear in contracts that were previously not initializable. Other contracts may be reinitialized but it does not show in the state diff because the storage diff is a noop.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000003` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000001bdbc0ae22bec0c2f08b4dd836944b3e28fe9b7a` <br/>
  **Meaning:** Sets `messenger` at slot `0x03` (3). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/L1StandardBridge.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/L1StandardBridge.json#L38-L42). The address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/4156733e723282b632a5743ac3064710caea03d4/superchain/extra/addresses/sepolia/zora.json#L3).

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
  **Before:** `0x000000000000000000000000e3a97585c6958c95738e2afa9088ab808cc2ac3b` <br/>
  **After:** `0x00000000000000000000000064b5a5ed26dcb17370ff4d33a8d503f0fbd06cff` <br/>
  **Meaning:** Implementation address is set to the new `L1StandardBridge`. The address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/implementations/networks/sepolia.yaml#L6).

### `0x5F3bdd57f01e88cE2F88f00685D30D6eb51A187c` (`OptimismMintableERC20FactoryProxy`)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0x5F3bdd57f01e88cE2F88f00685D30D6eb51A187c)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/4156733e723282b632a5743ac3064710caea03d4/superchain/extra/addresses/sepolia/zora.json#L7C41-L7C83)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The `initialized` boolean is set to `true`. The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/OptimismMintableERC20Factory.json](https://github.com/ethereum-optimism/optimism/blob/e6ef3a900c42c8722e72c2e2314027f85d12ced5/packages/contracts-bedrock/snapshots/storageLayout/OptimismMintableERC20Factory.json#L2-L22).
   This state diff will only appear in contracts that were previously not initializable. Other contracts may be reinitialized but it does not show in the state diff because the storage diff is a noop.

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000005376f1d543dcbb5bd416c56c189e4cb7399fcccb` <br/>
  **Meaning:** Sets `bridge` at slot `0x01` (1). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/OptimismMintableERC20Factory.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/OptimismMintableERC20Factory.json#L24-L28). The address of the `L1StandardBridge` should be the value set in the slot, left padded with zero bytes to fill the slot. The address of the [L1StandardBridgeProxy](https://github.com/ethereum-optimism/superchain-registry/blob/4156733e723282b632a5743ac3064710caea03d4/superchain/extra/addresses/sepolia/zora.json#L5) can be found in the Superchain Registry.

- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before:** `0x00000000000000000000000042d4a53fdcbc738479aaac9a39e3efe6a3216bef` <br/>
  **After:** `0x000000000000000000000000e01efbeb1089d1d1db9c6c8b135c934c0734c846` <br/>
  **Meaning:** Implementation address is set to the new `OptimismMintableERC20Factory` implementation. The address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/implementations/networks/sepolia.yaml#L10).

### `0xB54c7BFC223058773CF9b739cC5bd4095184Fb08` (`SystemConfigProxy`)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0xB54c7BFC223058773CF9b739cC5bd4095184Fb08)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/4156733e723282b632a5743ac3064710caea03d4/superchain/extra/addresses/sepolia/zora.json#L10C25-L10C67)

State Changes:

Please ensure that each link to the `superchain-registry` correctly corresponds to Sepolia as the superchain registry contains data for
different chains. The `superchain-registry` is considered the source of truth for contract addresses across the superchain. To ensure
that the address actually matches the correct implementation, an Etherscan link is also provided for each.

[system-config-registry]: https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/implementations/networks/sepolia.yaml#L14
[system-config-etherscan]: https://sepolia.etherscan.io/address/0xba2492e52F45651B60B8B38d4Ea5E2390C64Ffb1

[l1-xdm-registry]: https://github.com/ethereum-optimism/superchain-registry/blob/4156733e723282b632a5743ac3064710caea03d4/superchain/extra/addresses/sepolia/zora.json#L3
[l1-xdm-etherscan]: https://sepolia.etherscan.io/address/0x1bDBC0ae22bEc0c2f08B4dd836944b3E28fe9b7A

[l1-erc721-registry]: https://github.com/ethereum-optimism/superchain-registry/blob/4156733e723282b632a5743ac3064710caea03d4/superchain/extra/addresses/sepolia/zora.json#L4
[l1-erc721-etherscan]: https://sepolia.etherscan.io/address/0x16B0a4f451c4CB567703367e587E15Ac108e4311

[portal-registry]: https://github.com/ethereum-optimism/superchain-registry/blob/4156733e723282b632a5743ac3064710caea03d4/superchain/extra/addresses/sepolia/zora.json#L8
[portal-etherscan]: https://sepolia.etherscan.io/address/0xeffE2C6cA9Ab797D418f0D91eA60807713f3536f

[batch-inbox-registry]: https://github.com/ethereum-optimism/superchain-registry/blob/4156733e723282b632a5743ac3064710caea03d4/superchain/configs/sepolia/zora.yaml#L10
[batch-inbox-etherscan]: https://sepolia.etherscan.io/address/0xcd734290e4bd0200dac631c7d4b9e8a33234e91f

[l1-standard-bridge-registry]: https://github.com/ethereum-optimism/superchain-registry/blob/4156733e723282b632a5743ac3064710caea03d4/superchain/extra/addresses/sepolia/zora.json#L5
[l1-standard-bridge-etherscan]: https://sepolia.etherscan.io/address/0x5376f1D543dcbB5BD416c56C189e4cB7399fCcCB

[factory-registry]: https://github.com/ethereum-optimism/superchain-registry/blob/4156733e723282b632a5743ac3064710caea03d4/superchain/extra/addresses/sepolia/zora.json#L7
[factory-etherscan]: https://sepolia.etherscan.io/address/0x5F3bdd57f01e88cE2F88f00685D30D6eb51A187c

[output-oracle-registry]: https://github.com/ethereum-optimism/superchain-registry/blob/4156733e723282b632a5743ac3064710caea03d4/superchain/extra/addresses/sepolia/zora.json#L6
[output-oracle-etherscan]: https://sepolia.etherscan.io/address/0x2615B481Bd3E5A1C0C7Ca3Da1bdc663E8615Ade9

- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before:** `0x000000000000000000000000c3f36530e27c31874e414958f0a7ac3d542ec943` <br/>
  **After:** `0x000000000000000000000000ba2492e52f45651b60b8b38d4ea5e2390c64ffb1` <br/>
  **Meaning:** Implementation address is set to the new `SystemConfig` per the [Superchain Registry][system-config-registry] and [Etherscan][system-config-etherscan].

- **Key:** `0x383f291819e6d54073bc9a648251d97421076bdd101933c0c022219ce9580636` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000001bdbc0ae22bec0c2f08b4dd836944b3e28fe9b7a` <br/>
  **Meaning:** Sets `l1CrossDomainMessenger` address at slot per the [Superchain Registry][l1-xdm-registry]. This should be a proxy address per [Etherscan][l1-xdm-etherscan]. Verification of the key can be done by ensuring the result of the [L1_CROSS_DOMAIN_MESSENGER_SLOT](https://sepolia.etherscan.io/address/0xba2492e52F45651B60B8B38d4Ea5E2390C64Ffb1#readContract#F2) getter on the implementation contract matches the key.

- **Key:** `0x46adcbebc6be8ce551740c29c47c8798210f23f7f4086c41752944352568d5a7` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x00000000000000000000000016b0a4f451c4cb567703367e587e15ac108e4311` <br/>
  **Meaning:** Sets `l1ERC721Bridge` address at slot per the [Superchain Registry][l1-erc721-registry]. This should be a proxy address per [Etherscan][l1-erc721-etherscan]. Verification of the key can be done by ensuring the result of the [L1_ERC_721_BRIDGE_SLOT](https://sepolia.etherscan.io/address/0xba2492e52F45651B60B8B38d4Ea5E2390C64Ffb1#readContract#F3) getter on the implementation contract matches the key.

- **Key:** `0x4b6c74f9e688cb39801f2112c14a8c57232a3fc5202e1444126d4bce86eb19ac` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x000000000000000000000000effe2c6ca9ab797d418f0d91ea60807713f3536f` <br/>
  **Meaning:** Sets `optimismPortal` at slot per the [Superchain Registry][portal-registry]. This should be a proxy address per [Etherscan][portal-etherscan]. Verification of the key can be done by ensuring the result of the [OPTIMISM_PORTAL_SLOT](https://sepolia.etherscan.io/address/0xba2492e52F45651B60B8B38d4Ea5E2390C64Ffb1#readContract#F7) getter on the implementation contract matches the key.

- **Key:** `0x71ac12829d66ee73d8d95bff50b3589745ce57edae70a3fb111a2342464dc597` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x000000000000000000000000cd734290e4bd0200dac631c7d4b9e8a33234e91f` <br/>
  **Meaning:** Sets `batchInbox` at slot per the [Superchain Registry][batch-inbox-registry]. This should be an address with no code per [Etherscan][batch-inbox-etherscan]. Verification of the key can be done by ensuring the result of the [BATCH_INBOX_SLOT](https://sepolia.etherscan.io/address/0xba2492e52F45651B60B8B38d4Ea5E2390C64Ffb1#readContract#F1) getter on the implementation contract matches the key.

- **Key:** `0x9904ba90dde5696cda05c9e0dab5cbaa0fea005ace4d11218a02ac668dad6376` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000005376f1d543dcbb5bd416c56c189e4cb7399fcccb` <br/>
  **Meaning:** Sets `l1StandardBridge` at slot per the [Superchain Registry][l1-standard-bridge-registry]. This should be a proxy address per [Etherscan][l1-standard-bridge-etherscan]. Verification of the key can be done by ensuring the result of the [L1_STANDARD_BRIDGE_SLOT](https://sepolia.etherscan.io/address/0xba2492e52F45651B60B8B38d4Ea5E2390C64Ffb1#readContract#F4) getter on the implementation contract matches the key.

- **Key:** `0xa04c5bb938ca6fc46d95553abf0a76345ce3e722a30bf4f74928b8e7d852320c` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000005f3bdd57f01e88ce2f88f00685d30d6eb51a187c` <br/>
  **Meaning:** Sets `optimismMintableERC20Factory` at slot per the [Superchain Registry][factory-registry]. This should be a proxy address per [Etherscan][factory-etherscan]. Verification of the key can be done by ensuring the result of the [OPTIMISM_MINTABLE_ERC20_FACTORY_SLOT](https://sepolia.etherscan.io/address/0xba2492e52F45651B60B8B38d4Ea5E2390C64Ffb1#readContract#F6) getter on the implementation contract matches the key.

- **Key:** `0xa11ee3ab75b40e88a0105e935d17cd36c8faee0138320d776c411291bdbbb19f` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x00000000000000000000000000000000000000000000000000000000004565cd` <br/>
  **Meaning:** Sets `startBlock` at slot to 4548045. This should be the block number at which the `SystemConfig` proxy was initialized for the first time. [Etherscan events](https://sepolia.etherscan.io/address/0xB54c7BFC223058773CF9b739cC5bd4095184Fb08#events) shows only five events have been emitted since contract creation in block 4548045, and that the first `Initialized` event after that should be in block 4548045. Verification of the key can be done by ensuring the result of the [START_BLOCK_SLOT](https://sepolia.etherscan.io/address/0xba2492e52F45651B60B8B38d4Ea5E2390C64Ffb1#readContract#F8) getter on the implementation contract matches the key.

- **Key:** `0xe52a667f71ec761b9b381c7b76ca9b852adf7e8905da0e0ad49986a0a6871815` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000002615b481bd3e5a1c0c7ca3da1bdc663e8615ade9` <br/>
  **Meaning:** Sets `l2OutputOracle` at slot per the [Superchain Registry][output-oracle-registry]. This should be a proxy per [Etherscan][output-oracle-etherscan]. Verification of the key can be done by ensuring the result of the [L2_OUTPUT_ORACLE_SLOT](https://sepolia.etherscan.io/address/0xba2492e52F45651B60B8B38d4Ea5E2390C64Ffb1#readContract#F5) getter on the implementation contract matches the key.

### `0xE75Cd021F520B160BF6b54D472Fa15e52aFe5aDD` (The 1 of 1 `ProxyAdminOwner` Safe)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0xE75Cd021F520B160BF6b54D472Fa15e52aFe5aDD)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/4156733e723282b632a5743ac3064710caea03d4/superchain/extra/addresses/sepolia/zora.json#L11C23-L11C65)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000003`<br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Meaning:** The Safe nonce is updated.

### `0xeffE2C6cA9Ab797D418f0D91eA60807713f3536f` (`OptimismPortalProxy`)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0xeffE2C6cA9Ab797D418f0D91eA60807713f3536f)
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/4156733e723282b632a5743ac3064710caea03d4/superchain/extra/addresses/sepolia/zora.json#L8C27-L8C69)

State Changes:
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000035` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000c2be75506d5724086deb7245bd260cc9753911be00` <br/>
  **Meaning:** Sets `superchainConfig` at slot `0x35` (53). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/OptimismPortal.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/OptimismPortal.json#L58-L64). The `superchainConfig` address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/configs/sepolia/superchain.yaml#L8).

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000036` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x0000000000000000000000002615b481bd3e5a1c0c7ca3da1bdc663e8615ade9` <br/>
  **Meaning:** Sets `l2Oracle` at slot `0x36` (54). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/OptimismPortal.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/OptimismPortal.json#L66-L70). The `L2OutputOracleProxy` address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/4156733e723282b632a5743ac3064710caea03d4/superchain/extra/addresses/sepolia/zora.json#L6).

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000037` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x000000000000000000000000b54c7bfc223058773cf9b739cc5bd4095184fb08` <br/>
  **Meaning:** Sets `systemConfig` at slot `0x37` (55). The correctness of
   this slot is attested to in the Optimism repo at [storageLayout/OptimismPortal.json](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.3.0/packages/contracts-bedrock/snapshots/storageLayout/OptimismPortal.json#L73-L77). The `SystemConfigProxy` address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/4156733e723282b632a5743ac3064710caea03d4/superchain/extra/addresses/sepolia/zora.json#L10).

- **Key:** `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` <br/>
  **Before:** `0x0000000000000000000000008e24bdf3dcba149bae8dd8b73efd9d886f9f5d3c` <br/>
  **After:** `0x0000000000000000000000002d778797049fe9259d947d1ed8e5442226dfb589` <br/>
  **Meaning:** Implementation address is set to the new `OptimismPortal`. The implementation address can be found in the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/5ad42cbb49472a0bf164ade976426f7526ee6dfe/superchain/implementations/networks/sepolia.yaml#L12).

The only other state change is a nonce increment of an owner on the safe.
If simulating it will be `0xa4000bdd2bb92ce6750b31f1eeda47bd1cb8e6e4`, but if your ledger is
connected it may be a different one of the safe's owners.
