## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Nested Safe 1 (Foundation): `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`
>
> - Domain Hash: `0x37e1f5dd3b92a004a23589b741196c8a214629d4ea3a690ec8e41ae45c689cbb`
> - Message Hash: `0x2cd75220c7abdf2917440cc98017cbae98ac36818925569b3493f0c6e0a84338`
>
> ### Nested Safe 2 (Security Council): `0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`
>
> - Domain Hash: `0xbe081970e9fc104bd1ea27e375cd21ec7bb1eec56bfe43347c3e36c5d27b8533`
> - Message Hash: `0x92d0c5274b12e4c9ac70088051a1da3d8715e48f984538fbfbfda1135a51c3db`


## Normalized State Diff Hash Attestation

The normalized state diff hash MUST match the hash created by the state changes attested to in the state diff audit report.
As a signer, you are responsible for making sure this hash is correct. Please compare the hash below with the hash in the audit report.


**Normalized hash:** `0xa0e4e0b77250520faf7057e117d834a646791fc847bf443c8d42d54c3ea8460e`


## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the OPCM upgrade to v4.0.0.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `opcm.upgrade()`

For each chain being upgraded, the `opcm.upgrade()` function is called with a tuple of three elements:

1. Soneium Testnet Minato:

- SystemConfigProxy: [0x4Ca9608Fef202216bc21D543798ec854539bAAd3](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/soneium-minato.toml#L61)
- ProxyAdmin: [0xff9d236641962Cebf9DBFb54E7b8e91F99f10Db0](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/soneium-minato.toml#L62)
- AbsolutePrestate: [0x03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/validation/standard/standard-prestates.toml#L6)

Thus, the command to encode the calldata is:

```bash
cast calldata 'upgrade((address,address,bytes32)[])' "[(0x4Ca9608Fef202216bc21D543798ec854539bAAd3,0xff9d236641962Cebf9DBFb54E7b8e91F99f10Db0,0x03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8)]"
```

### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the argument to the `Multicall3DelegateCall.aggregate3()` function.

This function is called with a tuple of three elements:

Call3 struct for Multicall3DelegateCall:

- `target`: [0x1ac76f0833bbfccc732cadcc3ba8a3bbd0e89c3d](https://oplabs.notion.site/Sepolia-Release-Checklist-op-contracts-v4-0-0-rc-8-216f153ee1628095ba5be322a0bf9364) - Sepolia OPContractsManager v4.0.0
- `allowFailure`: false
- `callData`: `0xff2dd5a1...` (output from the previous section)

Command to encode:

```bash
cast calldata 'aggregate3((address,bool,bytes)[])' "[(0x1ac76f0833bbfccc732cadcc3ba8a3bbd0e89c3d,false,0xff2dd5a1000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000004ca9608fef202216bc21d543798ec854539baad3000000000000000000000000ff9d236641962cebf9dbfb54e7b8e91f99f10db003eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

0x82ad56cb0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000001ac76f0833bbfccc732cadcc3ba8a3bbd0e89c3d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a4ff2dd5a1000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000004ca9608fef202216bc21d543798ec854539baad3000000000000000000000000ff9d236641962cebf9dbfb54e7b8e91f99f10db003eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc800000000000000000000000000000000000000000000000000000000

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

### State Overrides

Note: The changes listed below do not include threshold, nonce and owner mapping overrides. These changes are listed and explained in the [NESTED-VALIDATION.md](../../../../../NESTED-VALIDATION.md) file.

## Task Transfers

#### Decoded Transfer 0
  - **From:**              [`0x65ea1489741A5D72fFdD8e6485B216bBdcC15Af3`](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/superchain/configs/sepolia/soneium-minato.toml#L60) (Soneium Minato OptimismPortal2)
  - **To:**                `0x8757A0F58D7151c1c3dbaB07cFec7888D3465ee1` (Soneium Minato ETHLockbox - newly deployed)
  - **Value:**             `176676906466144167650175` (All funds)
  - **Token Address:**     `0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE` (ETH)
  
## Task State Changes

### `0x0184245d202724dc28a2b688952cb56c882c226f` ([L1CrossDomainMessengerProxy](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/soneium-minato.toml#L55)) - Chain ID: 1946
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000010000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000020000000000000000000000000000000000000000`
  - **Summary:** _initialized flag incremented from 1 to 2 (initialization completed)
  - **Detail:** Packed storage slot with spacer_0_0_20 (address), _initialized (uint8), and _initializing (bool)
  
- **Key:**          `0x00000000000000000000000000000000000000000000000000000000000000fe`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** [`0x0000000000000000000000004ca9608fef202216bc21d543798ec854539baad3`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/soneium-minato.toml#L61)
  - **Summary:** portal (slot 252) set to SystemConfigProxy for Soneium
  - **Detail:** Storage slot 254 stores the IOptimismPortal2 portal address
  
  ---
  
### `0x1ac76f0833bbfccc732cadcc3ba8a3bbd0e89c3d` ([OP Contracts Manager](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/validation/standard/standard-versions-sepolia.toml#L42))
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Summary:** isRC set to false
  
  ---
  
### `0x1eb2ffc903729a0f03966b917003800b145f56e2` ([ProxyAdminOwner](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/soneium-minato.toml#L46)) - Chain ID: 11155420
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `31`
  - **After:** `32`
  - **Summary:** Gnosis Safe nonce incremented from 31 to 32
  - **Detail:** Transaction counter for the Safe wallet managing proxy admin ownership
  
  ---
  
### `0x2bfb22cd534a462028771a1ca9d6240166e450c4` ([L1ERC721BridgeProxy](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/soneium-minato.toml#L56)) - Chain ID: 1946
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** _initialized flag incremented from 1 to 2 (initialization completed)
  - **Detail:** Bridge initialization process completed
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** [`0x0000000000000000000000004ca9608fef202216bc21d543798ec854539baad3`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/soneium-minato.toml#L61)
  - **Summary:** Configuration set to SystemConfigProxy for Soneium
  - **Detail:** Storage slot 51 configuration parameter
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** [`0x7aE1d3BD877a4C5CA257404ce26BE93A02C98013`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L39)
  - **After:** [`0x25d6CeDEB277Ad7ebEe71226eD7877768E0B7A2F`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L19)
  - **Summary:** ERC-1967 implementation upgraded to L1ERC721Bridge v2.7.0
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
  ---
  
### `0x4ca9608fef202216bc21d543798ec854539baad3` ([SystemConfigProxy](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/soneium-minato.toml#L61)) - Chain ID: 1946
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** _initialized flag incremented from 1 to 2 (initialization completed)
  - **Detail:** Packed storage slot with _initialized (uint8) and _initializing (bool)
  
- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000006b`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000000000000000000000000000000000000000079a`
  - **Summary:** l2ChainId (slot 107) set to 1946 for Soneium Testnet Minato
  - **Detail:** Chain ID configuration for the L2 network
  
- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000006c`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** [`0x000000000000000000000000c2be75506d5724086deb7245bd260cc9753911be`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/soneium-minato.toml#L63)
  - **Summary:** Configuration linked to SuperchainConfig for Soneium
  - **Detail:** Storage slot configuration parameter
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** [`0x340f923E5c7cbB2171146f64169EC9d5a9FfE647`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L29)
  - **After:** [`0xFaA660bf783CBAa55e1B7F3475C20Db74a53b9Fa`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L8)
  - **Summary:** ERC-1967 implementation upgraded to SystemConfig v3.4.0
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
- **Key:**          `0x52322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906`
  - **Decoded Kind:** `address`
  - **Before:** [`0xB3Ad2c38E6e0640d7ce6aA952AB3A60E81bf7a01`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/soneium-minato.toml#L66)
  - **After:** `0x0000000000000000000000000000000000000000`
  - **Summary:** DisputeGameFactory address cleared (reset to zero)
  - **Detail:** Unstructured storage slot for the address of the DisputeGameFactory proxy.
  
  ---
  
### `0x5aae0449931b90258f8ceb414658e0b79b6c6e2d` (ETHLockboxProxy) 
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** _initialized flag set to 1 (initialization started)
  - **Detail:** Packed storage slot containing _initialized (uint8), _initializing (bool), and superchainConfig (contract ISuperchainConfig) 
  
  
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000004`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** [`0x0000000000000000000000004ca9608fef202216bc21d543798ec854539baad3`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/soneium-minato.toml#L61)
  - **Summary:** superchainConfig set to SystemConfigProxy for Soneium
  - **Detail:** This appears to be setting the superchainConfig reference in the packed slot 0 structure during initialization 
  
  
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x33Dadc2d1aA9BB613A7AE6B28425eA00D44c6998`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L14)
  - **Summary:** ERC-1967 implementation upgraded to ETHLockbox v1.2.0
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
  
- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** `0xff9d236641962Cebf9DBFb54E7b8e91F99f10Db0`
  - **Summary:** Proxy owner address
  - **Detail:** Standard slot for storing the owner address in a Proxy contract.
  
  
  ---
  
### `0x5f5a404a5edabcdd80db05e8e54a78c9ebf000c2` ([L1StandardBridgeProxy](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/soneium-minato.toml#L57)) - Chain ID: 1946
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** _initialized flag incremented from 1 to 2 (initialization completed)
  - **Detail:** Bridge initialization process completed 
  
  
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000034`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** [`0x0000000000000000000000004ca9608fef202216bc21d543798ec854539baad3`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/soneium-minato.toml#L61)
  - **Summary:** superchainConfig set to SystemConfigProxy for Soneium
  - **Detail:** Storage slot 52 corresponds to superchainConfig in L1StandardBridge storage layout 
  
  
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** [`0x0b09ba359A106C9ea3b181CBc5F394570c7d2a7A`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L40)
  - **After:** [`0x44AfB7722AF276A601D524F429016A18B6923df0`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L20)
  - **Summary:** ERC-1967 implementation upgraded to L1StandardBridge v2.6.0
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
  
  ---
  
### `0x65ea1489741a5d72ffdd8e6485b216bbdcc15af3` ([OptimismPortalProxy](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/soneium-minato.toml#L60)) - Chain ID: 1946
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** _initialized flag incremented from 1 to 2 (initialization completed)
  - **Detail:** Portal initialization process completed 
  
  
  
- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000003e`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000000090066735ee774b405c4f54bfec05b07f16d67188`
  - **Summary:** anchorStateRegistry set to AnchorStateRegistryProxy
  - **Detail:** Storage slot 62 corresponds to anchorStateRegistry in OptimismPortal2 storage layout 
  
  
  
- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000003f`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000008757a0f58d7151c1c3dbab07cfec7888d3465ee1`
  - **Summary:** ethLockbox set to DelayedWETHProxy
  - **Detail:** Storage slot 63 corresponds to ethLockbox in OptimismPortal2 storage layout 
  
  
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** [`0xB443Da3e07052204A02d630a8933dAc05a0d6fB4`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L33)
  - **After:** [`0xEFEd7F38BB9BE74bBa583a1A5B7D0fe7C9D5787a`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L12)
  - **Summary:** ERC-1967 implementation upgraded to OptimismPortal2 v4.6.0
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
  
  ---
  
### `0x6e8a77673109783001150dfa770e6c662f473da9` ([AddressManager](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/soneium-minato.toml#L54)) - Chain ID: 1946
  
- **Key:**          `0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e`
  - **Before:** [`0x0000000000000000000000005d5a095665886119693f0b41d8dfee78da033e8b`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L38)
  - **After:** [`0x000000000000000000000000d26bb3aaaa4cb5638a8581a4c4b1d937d8e05c54`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L18)
  - **Summary:** L1CrossDomainMessenger implementation upgraded to v2.9.0
  - **Detail:** AddressManager mapping slot for "OVM_L1CrossDomainMessenger" key updated 
  
  
  
  ---
  
### `0x8757a0f58d7151c1c3dbab07cfec7888d3465ee1` (DelayedWETHProxy) 
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** [`0x000000000000000000004ca9608fef202216bc21d543798ec854539baad30001`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/soneium-minato.toml#L61)
  - **Summary:** Packed slot initialization with _initialized=1 and config=SystemConfigProxy
  - **Detail:** Packed storage slot with _initialized (uint8), _initializing (bool), and config (contract ISuperchainConfig) 
  
  
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x784d2F03593A42A6E4676A012762F18775ecbBe6`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L15)
  - **Summary:** ERC-1967 implementation upgraded to DelayedWETH v1.5.0
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
  
- **Key:**          `0xaf309396611bd83e01df94cc09abe3386b4a507a7d24606eb253ef190041f1d9`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** Boolean flag set to true (value 1)
  - **Detail:** This appears to be an authorization or enablement flag being set during initialization 
  
  
  
- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** `0xff9d236641962Cebf9DBFb54E7b8e91F99f10Db0`
  - **Summary:** Proxy owner address
  - **Detail:** Standard slot for storing the owner address in a Proxy contract.
  
  
  ---
  
### `0x90066735ee774b405c4f54bfec05b07f16d67188` (AnchorStateRegistryProxy) 
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** [`0x000000000000000000004ca9608fef202216bc21d543798ec854539baad30001`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/soneium-minato.toml#L61)
  - **Summary:** Packed slot initialization with _initialized=1 and superchainConfig=SystemConfigProxy
  - **Detail:** Packed storage slot with _initialized (uint8), _initializing (bool), and superchainConfig (contract ISuperchainConfig)
  
  
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** [`0x000000000000000000000000b3ad2c38e6e0640d7ce6aa952ab3a60e81bf7a01`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/soneium-minato.toml#L66)
  - **Summary:** disputeGameFactory set to DisputeGameFactoryProxy for Soneium
  - **Detail:** Storage slot 1 corresponds to disputeGameFactory in AnchorStateRegistry storage layout
  
  
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000003`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0xa8eae029511315ef0c1e6837558cdeaa00add8326e6a65b4bec99c08d63249c8`
  - **Summary:** startingAnchorRoot hash set during initialization
  - **Detail:** Storage slot 3 corresponds to startingAnchorRoot (struct OutputRoot) in AnchorStateRegistry storage layout
  
  
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000004`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000000000000000000000000000000000000093886a`
  - **Summary:** startingAnchorRoot block number set to 9676906
  - **Detail:** Storage slot 4 is the second part of the startingAnchorRoot struct (block number field)
  
  
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000006`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000000000000000000000000000685d46f000000001`
  - **Summary:** Packed slot with respectedGameType=1 and retirementTimestamp=438880367
  - **Detail:** Storage slot 6 contains respectedGameType (GameType) and retirementTimestamp (uint64) in AnchorStateRegistry
  
  
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0xeb69cC681E8D4a557b30DFFBAd85aFfD47a2CF2E`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L13)
  - **Summary:** ERC-1967 implementation upgraded to AnchorStateRegistry v3.5.0
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
  
- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** `0xff9d236641962Cebf9DBFb54E7b8e91F99f10Db0`
  - **Summary:** Proxy owner address
  - **Detail:** Standard slot for storing the owner address in a Proxy contract.
  
  
  ---
  
### `0xb3ad2c38e6e0640d7ce6aa952ab3a60e81bf7a01` ([DisputeGameFactoryProxy](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/soneium-minato.toml#L66)) - Chain ID: 1946
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** [`0x4bbA758F006Ef09402eF31724203F316ab74e4a0`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L36)
  - **After:** [`0x33D1e8571a85a538ed3D5A4d88f46C112383439D`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L16)
  - **Summary:** ERC-1967 implementation upgraded to DisputeGameFactory v1.2.0
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
  
- **Key:**          `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`
  - **Before:** [`0x000000000000000000000000697a4684576d8a76d4b11e83e9b6f3b61bf04755`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/soneium-minato.toml#L69)
  - **After:** `0x000000000000000000000000383fbf071b8aad992e30ebdd56b22eec06c401c0`
  - **Summary:** Game implementation mapping updated
  - **Detail:** gameImpls mapping slot updated from PermissionedDisputeGame to new implementation address
  
  
  
  ---
  
### `0xc2be75506d5724086deb7245bd260cc9753911be` ([SuperchainConfig](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/soneium-minato.toml#L63)) - Chain ID: 11155420
  
  - **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x000000000000000000007a50f00e8d05b95f98fe38d8bee366a7324dcf7e0002`
  - **Summary:** _initialized flag incremented from 1 to 2 (initialization completed)
  - **Detail:** Packed storage slot with _initialized (uint8) and _initializing (bool)
  
  
  
- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** [`0x4da82a327773965b8d4D85Fa3dB8249b387458E7`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L43)
  - **After:** [`0xCe28685EB204186b557133766eCA00334EB441E4`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L23)
  - **Summary:** ERC-1967 implementation upgraded to SuperchainConfig v2.3.0
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
  
  
- **Key:**          `0xd30e835d3f35624761057ff5b27d558f97bd5be034621e62240e5c0b784abe68`
  - **Decoded Kind:** `address`
  - **Before:** [`0x7a50f00e8D05b95F98fE38d8BeE366a7324dCf7E`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/soneium-minato.toml#L47)
  - **After:** `0x0000000000000000000000000000000000000000`
  - **Summary:** Guardian address cleared (reset to zero)
  - **Detail:** Unstructured storage slot for the address of the superchain guardian (GUARDIAN_SLOT).
  

### Nonce increments

- `0x90066735EE774b405C4f54bfeC05b07f16D67188` - AnchorStateRegistryProxy
- `0xB3Ad2c38E6e0640d7ce6aA952AB3A60E81bf7a01` - DisputeGameFactoryProxy
- `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B` - FoundationOperationsSafe
- `0xA03DaFadE71F1544f4b0120145eEC9b89105951f` - Sender Address of the Tenderly transaction (Your ledger or first owner on the nested safe).
- `0x383FbF071b8aad992E30ebdd56B22Eec06C401c0` - 