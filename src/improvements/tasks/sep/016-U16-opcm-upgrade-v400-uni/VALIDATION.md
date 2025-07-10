## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Safe (L1ProxyAdminOwner): `0xd363339eE47775888Df411A163c586a8BdEA9dbf` - This safe is not nested.
>
> - Domain Hash: `0x2fedecce87979400ff00d5cec4c77da942d43ab3b9db4a5ffc51bb2ef498f30b`
> - Message Hash: `0x033bfb0599c44b6c3c23866b4ad20ef88708f0c5e8ede528ecd0b131292d6bb8`

## Normalized State Diff Hash Attestation

The normalized state diff hash MUST match the hash created by the state changes attested to in the state diff audit report.
As a signer, you are responsible for making sure this hash is correct. Please compare the hash below with the hash in the audit report.

**Normalized hash:** `0x8763756674cf7638da9caa8196e90cb641fa6a1f364a25e7590eb5a66252bf5b`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the OPCM upgrade to v4.0.0.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `opcm.upgrade()`

For each chain being upgraded, the `opcm.upgrade()` function is called with a tuple of three elements:

1. Unichain Sepolia Testnet:

- SystemConfigProxy: [0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/unichain.toml#L60)
- ProxyAdmin: [0x2BF403E5353A7a082ef6bb3Ae2Be3B866D8D3ea4](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/unichain.toml#L61)
- AbsolutePrestate: [0x03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/validation/standard/standard-prestates.toml#L6)

Thus, the command to encode the calldata is:

```bash
cast calldata 'upgrade((address,address,bytes32)[])' "[(0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D,0x2BF403E5353A7a082ef6bb3Ae2Be3B866D8D3ea4,0x03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8)]"
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
cast calldata 'aggregate3((address,bool,bytes)[])' "[(0x1ac76f0833bbfccc732cadcc3ba8a3bbd0e89c3d,false,0xff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000aee94b9ab7752d3f7704bde212c0c6a0b701571d0000000000000000000000002bf403e5353a7a082ef6bb3ae2be3b866d8d3ea403eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

0x82ad56cb0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000001ac76f0833bbfccc732cadcc3ba8a3bbd0e89c3d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a4ff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000aee94b9ab7752d3f7704bde212c0c6a0b701571d0000000000000000000000002bf403e5353a7a082ef6bb3ae2be3b866d8d3ea403eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc800000000000000000000000000000000000000000000000000000000



## Task Transfers

#### Decoded Transfer 0
  - **From:**              [`0x0d83dab629f0e0F9d36c0Cbc89B69a489f0751bD`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/unichain.toml#L59) (OptimismPortalProxy)
  - **To:**                `0x62D47fd9256248D33A38A22ac4F0336Da1cfdfe4` (EthLockboxProxy - newly deployed)
  - **Value:**             `344792481010589432510077`
  - **Token Address:**     `0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE` (ETH)

## Task State Changes

### `0x0b0bde7ac8ffd654dbd0db92fdbcc2f9fd73fc6b` (DelayedWETH Proxy - newly deployed)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** _initialized flag set to 1 (DelayedWETH contract initialized)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000004`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** [`0x000000000000000000000000aee94b9ab7752d3f7704bde212c0c6a0b701571d`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/unichain.toml#L60)
  - **Summary:** systemConfig set to SystemConfigProxy for Unichain

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x33Dadc2d1aA9BB613A7AE6B28425eA00D44c6998`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L14)
  - **Summary:** ERC-1967 implementation slot set to DelayedWETH v1.5.0

- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x2BF403E5353A7a082ef6bb3Ae2Be3B866D8D3ea4`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/unichain.toml#L61)
  - **Summary:** Proxy owner set to ProxyAdminOwner for Unichain

  ---

### `0x0d83dab629f0e0f9d36c0cbc89b69a489f0751bd` ([OptimismPortalProxy](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/unichain.toml#L59)) - Chain ID: 1301

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** _initialized flag incremented from 1 to 2 (reinitialization completed)

- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000003e`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000bb6ca820978442750b682663efa851ad4131127b`
  - **Summary:** anchorStateRegistry set to newly deployed AnchorStateRegistryProxy `0xbb6ca820978442750b682663efa851ad4131127b`

- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000003f`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000000062d47fd9256248d33a38a22ac4f0336da1cfdfe4`
  - **Summary:** ethLockbox set to newly deployed EthLockboxProxy `0x62d47fd9256248d33a38a22ac4f0336da1cfdfe4`

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0xB443Da3e07052204A02d630a8933dAc05a0d6fB4`
  - **After:** [`0xEFEd7F38BB9BE74bBa583a1A5B7D0fe7C9D5787a`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L12)
  - **Summary:** ERC-1967 implementation upgraded to OptimismPortal v4.6.0

  ---

### `0x184d2cad90506337aad35afc674ef48095717d3d` (DelayedWETH Proxy - newly deployed)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** _initialized flag set to 1 (DelayedWETH contract initialized)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000004`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** [`0x000000000000000000000000aee94b9ab7752d3f7704bde212c0c6a0b701571d`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/unichain.toml#L60)
  - **Summary:** systemConfig set to SystemConfigProxy for Unichain

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x33Dadc2d1aA9BB613A7AE6B28425eA00D44c6998`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L14)
  - **Summary:** ERC-1967 implementation slot set to DelayedWETH v1.5.0

- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x2BF403E5353A7a082ef6bb3Ae2Be3B866D8D3ea4`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/unichain.toml#L61)
  - **Summary:** Proxy owner set to ProxyAdminOwner for Unichain

  ---

### `0x448a37330a60494e666f6dd60ad48d930aeba381` (L1CrossDomainMessenger) - Chain ID: 1301

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000010000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000020000000000000000000000000000000000000000`
  - **Summary:** _initialized flag incremented from 1 to 2 (reinitialization completed)

- **Key:**          `0x00000000000000000000000000000000000000000000000000000000000000fe`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** [`0x000000000000000000000000aee94b9ab7752d3f7704bde212c0c6a0b701571d`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/unichain.toml#L60)
  - **Summary:** systemConfig set to SystemConfigProxy for Unichain

  ---

### `0x4696b5e042755103fe558738bcd1ecee7a45ebfe` ([L1ERC721BridgeProxy](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/unichain.toml#L58)) - Chain ID: 1301

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** _initialized flag incremented from 1 to 2 (reinitialization completed)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** [`0x000000000000000000000000aee94b9ab7752d3f7704bde212c0c6a0b701571d`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/unichain.toml#L60)
  - **Summary:** systemConfig set to SystemConfigProxy for Unichain

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x7aE1d3BD877a4C5CA257404ce26BE93A02C98013`
  - **After:** [`0x25d6CeDEB277Ad7ebEe71226eD7877768E0B7A2F`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L21)
  - **Summary:** ERC-1967 implementation upgraded to L1ERC721Bridge v2.6.0

  ---

### `0x62d47fd9256248d33a38a22ac4f0336da1cfdfe4` (EthLockboxProxy) - FLAG: newly deployed, not in superchain-registry yet

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000aee94b9ab7752d3f7704bde212c0c6a0b701571d0001`
  - **Summary:** Packed slot with systemConfig ([`0xaee94b9ab7752d3f7704bde212c0c6a0b701571d`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/unichain.toml#L60)) and _initialized=1

- **Key:**          `0x22a197fa3db2cf5f014c98b6ebc59f33e88ecd7a5304ec589cbca4f71ef87ea0`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** authorizedPortals mapping - OptimismPortalProxy for Unichain authorized (slot calculated from mapping key)

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x784d2F03593A42A6E4676A012762F18775ecbBe6`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L15)
  - **Summary:** ERC-1967 implementation slot set to ETHLockbox v1.2.0

- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x2BF403E5353A7a082ef6bb3Ae2Be3B866D8D3ea4`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/unichain.toml#L61)
  - **Summary:** Proxy owner set to ProxyAdminOwner for Unichain

  ---

### `0xaee94b9ab7752d3f7704bde212c0c6a0b701571d` ([SystemConfigProxy](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/unichain.toml#L60)) - Chain ID: 1301

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** _initialized flag incremented from 1 to 2 (reinitialization completed)

- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000006b`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000515`
  - **Summary:** l2ChainId set to 1301 (Unichain Sepolia chain ID)

- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000006c`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** [`0x000000000000000000000000c2be75506d5724086deb7245bd260cc9753911be`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/superchain.toml#L7)
  - **Summary:** superchainConfig set to SuperchainConfigProxy

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x340f923E5c7cbB2171146f64169EC9d5a9FfE647`
  - **After:** [`0xFaA660bf783CBAa55e1B7F3475C20Db74a53b9Fa`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L25)
  - **Summary:** ERC-1967 implementation upgraded to SystemConfig v2.6.0

- **Key:**          `0x52322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906`
  - **Decoded Kind:** `address`
  - **Before:** [`0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/unichain.toml#L66)
  - **After:** `0x0000000000000000000000000000000000000000`
  - **Summary:** DisputeGameFactory proxy address cleared from SystemConfig

  ---

### `0xbb6ca820978442750b682663efa851ad4131127b` (AnchorStateRegistryProxy - newly deployed)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000aee94b9ab7752d3f7704bde212c0c6a0b701571d0001`
  - **Summary:** Packed slot with systemConfig ([`0xaee94b9ab7752d3f7704bde212c0c6a0b701571d`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/unichain.toml#L60)) and _initialized=1

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** [`0x000000000000000000000000eff73e5aa3b9aec32c659aa3e00444d20a84394b`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/unichain.toml#L66)
  - **Summary:** disputeGameFactory set to DisputeGameFactoryProxy for Unichain

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000003`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0xf9a55788dece89fdfdd498e48bbcf19515c8b5b4c3edc1313b02e4cf150bf7be`
  - **Summary:** startingAnchorRoot hash (first 32 bytes of anchor state proposal)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000004`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000f9e7b7`
  - **Summary:** startingAnchorRoot block number (16376759, second 32 bytes of anchor state proposal)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000006`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000000000000000000000000000685c542000000000`
  - **Summary:** retirementTimestamp set to 1750734368 (packed slot with respectedGameType)

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0xeb69cC681E8D4a557b30DFFBAd85aFfD47a2CF2E`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L13)
  - **Summary:** ERC-1967 implementation slot set to AnchorStateRegistry v3.5.0

- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x2BF403E5353A7a082ef6bb3Ae2Be3B866D8D3ea4`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/unichain.toml#L61)
  - **Summary:** Proxy owner set to ProxyAdminOwner for Unichain

  ---

### [`0xd363339ee47775888df411a163c586a8bdea9dbf`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/unichain.toml#L46)  (ProxyAdminOwner (GnosisSafe)) - Chain ID: 1301Add commentMore actions

- **Account Nonce in State:**
  - **Before:** 8
  - **After:** 14
  - **Detail:** Six new contracts were deployed, including:
    - Two dispute games
    - Two new delayed WETH proxies
    - A new ETHLockbox proxy
    - A new AnchorStateRegistry proxy

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`

  - **Decoded Kind:** `uint256`
  - **Before:** `33`
  - **After:** `34`
  - **Summary:** nonce
  - **Detail:**  The nonce of the ProxyAdminOwner contract is updated.

  ---

### `0xea58fca6849d79ead1f26608855c2d6407d54ce2` ([L1StandardBridgeProxy](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/unichain.toml#L57)) - Chain ID: 1301

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** _initialized flag incremented from 1 to 2 (reinitialization completed)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000034`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** [`0x000000000000000000000000aee94b9ab7752d3f7704bde212c0c6a0b701571d`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/unichain.toml#L60)
  - **Summary:** systemConfig set to SystemConfigProxy for Unichain

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0b09ba359A106C9ea3b181CBc5F394570c7d2a7A`
  - **After:** [`0x44AfB7722AF276A601D524F429016A18B6923df0`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L20)
  - **Summary:** ERC-1967 implementation upgraded to L1StandardBridge v2.6.0

  ---

### `0xef1295ed471dfec101691b946fb6b4654e88f98a` (AddressManager) - Chain ID: 1301

- **Key:**          `0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e`
  - **Before:** `0x0000000000000000000000005d5a095665886119693f0b41d8dfee78da033e8b`
  - **After:** [`0x000000000000000000000000d26bb3aaaa4cb5638a8581a4c4b1d937d8e05c54`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L18)
  - **Summary:** L1CrossDomainMessenger implementation updated from v2.6.0 to v2.9.0

  ---

### `0xeff73e5aa3b9aec32c659aa3e00444d20a84394b` (DisputeGameFactory) - Chain ID: 1301

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x4bbA758F006Ef09402eF31724203F316ab74e4a0`
  - **After:** [`0x33D1e8571a85a538ed3D5A4d88f46C112383439D`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L16)
  - **Summary:** ERC-1967 implementation upgraded to DisputeGameFactory v1.2.0

- **Key:**          `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`
  - **Decoded Kind:** `gameImpls[1]` (FaultDisputeGame mapping)
  - **Before:** `0x0000000000000000000000005acc5b2da22463eb8a54851dc0ac80a193f4039a`
  - **After:** `0x0000000000000000000000007ee2427f4f1de711f2286438cebb6c4794f01a23` (newly deployed contract)
  - **Summary:** Updated FaultDisputeGame implementation for game type 1

- **Key:**          `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b`
  - **Decoded Kind:** `gameImpls[0]` (FaultDisputeGame mapping)
  - **Before:** `0x000000000000000000000000a84cf3aab33a5ac812f46a46601b0e39a03e07f1`
  - **After:** `0x00000000000000000000000016bee830196457e95a43f31102772af89b5c486e` (newly deployed contract)
  - **Summary:** Updated FaultDisputeGame implementation for game type 0