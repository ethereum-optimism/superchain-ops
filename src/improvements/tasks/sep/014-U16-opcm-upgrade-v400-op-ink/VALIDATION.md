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
> - Message Hash: `0xc7cfbb96124f4c0e3c0f73ae1aaa55746b7497d5416c4d5c1c792eef6e493c2e`

> ### Nested Safe 2 (Security Council): `0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`
>
> - Domain Hash: `0xbe081970e9fc104bd1ea27e375cd21ec7bb1eec56bfe43347c3e36c5d27b8533`
> - Message Hash: `0xbfc6bd12af707b0d0f1fed2ea318942bfb4d3fef6d3bf360d3d69d7a1fac54f1`

## Normalized State Diff Hash Attestation

The normalized state diff hash MUST match the hash created by the state changes attested to in the state diff audit report.
As a signer, you are responsible for making sure this hash is correct. Please compare the hash below with the hash in the audit report.

**Normalized hash:** `0xf21c08ee68df610b38634605eee5395ba375c61f84898dbc5e72a8697ed65610`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the OPCM upgrade to v4.0.0.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `opcm.upgrade()`

For each chain being upgraded, the `opcm.upgrade()` function is called with a tuple of three elements:

1. OP Sepolia Testnet:

- SystemConfigProxy: [0x034EdD2A225f7f429a63E0f1d2084B9E0a93b538](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/op.toml#L60)
- ProxyAdmin: [0x189aBAAaa82DfC015A588A7dbaD6F13b1D3485Bc](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/op.toml#L61)
- AbsolutePrestate: [0x03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/validation/standard/standard-prestates.toml#L6)

2. Ink Sepolia Testnet:

- SystemConfigProxy: [0x05c993e60179f28bf649a2bb5b00b5f4283bd525](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L60)
- ProxyAdmin: [0xd7dB319a49362b2328cf417a934300cCcB442C8d](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L61)
- AbsolutePrestate: [0x03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/validation/standard/standard-prestates.toml#L6)

Thus, the command to encode the calldata is:

```bash
cast calldata 'upgrade((address,address,bytes32)[])' "[(0x034EdD2A225f7f429a63E0f1d2084B9E0a93b538,0x189aBAAaa82DfC015A588A7dbaD6F13b1D3485Bc,0x03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8),(0x05c993e60179f28bf649a2bb5b00b5f4283bd525,0xd7dB319a49362b2328cf417a934300cCcB442C8d,0x03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8)]"
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
cast calldata 'aggregate3((address,bool,bytes)[])' "[(0x1ac76f0833bbfccc732cadcc3ba8a3bbd0e89c3d,false,0xff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000034edd2a225f7f429a63e0f1d2084b9e0a93b538000000000000000000000000189abaaaa82dfc015a588a7dbad6f13b1d3485bc03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc800000000000000000000000005c993e60179f28bf649a2bb5b00b5f4283bd525000000000000000000000000d7db319a49362b2328cf417a934300cccb442c8d03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x82ad56cb0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000001ac76f0833bbfccc732cadcc3ba8a3bbd0e89c3d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000104ff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000034edd2a225f7f429a63e0f1d2084b9e0a93b538000000000000000000000000189abaaaa82dfc015a588a7dbad6f13b1d3485bc03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc800000000000000000000000005c993e60179f28bf649a2bb5b00b5f4283bd525000000000000000000000000d7db319a49362b2328cf417a934300cccb442c8d03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc800000000000000000000000000000000000000000000000000000000
```

## Task Transfers

#### Decoded Transfer 0
  - **From:**              [`0x16Fc5058F25648194471939df75CF27A2fdC48BC`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/op.toml#L59) (OP Sepolia OptimismPortal2)
  - **To:**                `0xC38de74A8B0F6C671669cfB36e160548Fb4A0c05` (OP Sepolia ETHLockbox - newly deployed)
  - **Value:**             `913121708389850874698556`
  - **Token Address:**     `0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE` (ETH)

#### Decoded Transfer 1
  - **From:**              [`0x5c1d29C6c9C8b0800692acC95D700bcb4966A1d7`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L59) (Ink OptimismPortal2)
  - **To:**                `0x636F1E307CAE86C0f93Ef7E1443A0Fcf01947b2c` (Ink ETHLockbox - newly deployed)
  - **Value:**             `96495691258514667389802`
  - **Token Address:**     `0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE` (ETH)

## Task State Changes

### [`0x034edd2a225f7f429a63e0f1d2084b9e0a93b538`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/op.toml#L60) (SystemConfig) - Chain ID: 11155420

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** `reinitVersion` incremented from 1 to 2.

- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000006b`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000aa37dc`
  - **Summary:** `l2ChainId` set to 11155420.

- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000006c`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** [`0x000000000000000000000000c2be75506d5724086deb7245bd260cc9753911be`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L62)
  - **Summary:** `superchainConfig` address added to SystemConfig.

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x340f923E5c7cbB2171146f64169EC9d5a9FfE647`
  - **After:** `0xFaA660bf783CBAa55e1B7F3475C20Db74a53b9Fa`
  - **Summary:** ERC-1967 implementation address updated to [`0xFaA660bf783CBAa55e1B7F3475C20Db74a53b9Fa`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L8).

- **Key:**          `0x52322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906`
  - **Decoded Kind:** `address`
  - **Before:** `0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1`
  - **After:** `0x0000000000000000000000000000000000000000`
  - **Summary:** DisputeGameFactory proxy address is [deleted](https://github.com/ethereum-optimism/optimism/pull/14820) from the SystemConfig.

  ---

### [`0x05c993e60179f28bf649a2bb5b00b5f4283bd525`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L60) (SystemConfig) - Chain ID: 763373

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** `reinitVersion` incremented from 1 to 2.

- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000006b`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000000000000000000000000000000000000000000ba5ed`
  - **Summary:** `l2ChainId` set to 763373.

- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000006c`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** [`0x000000000000000000000000c2be75506d5724086deb7245bd260cc9753911be`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L62)
  - **Summary:** `superchainConfig` address added to SystemConfig.

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x340f923E5c7cbB2171146f64169EC9d5a9FfE647`
  - **After:** [`0xFaA660bf783CBAa55e1B7F3475C20Db74a53b9Fa`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L8)
  - **Summary:** ERC-1967 implementation address updated.

- **Key:**          `0x52322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906`
  - **Decoded Kind:** `address`
  - **Before:** `0x860e626c700AF381133D9f4aF31412A2d1DB3D5d`
  - **After:** `0x0000000000000000000000000000000000000000`
  - **Summary:** DisputeGameFactory proxy address is [deleted](https://github.com/ethereum-optimism/optimism/pull/14820) from the SystemConfig.

  ---

### `0x05f9613adb30026ffd634f38e5c4dfd30a197fa1` ([DisputeGameFactory](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/op.toml#L64)) - Chain ID: 11155420

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x4bbA758F006Ef09402eF31724203F316ab74e4a0`
  - **After:** [`0x33D1e8571a85a538ed3D5A4d88f46C112383439D`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L16)
  - **Summary:** ERC-1967 implementation slot updated upgraded to DisputeGameFactory v1.2.0

- **Key:**          `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`
  - **Decoded Kind:** `gameImpls[1]` (FaultDisputeGame mapping)
  - **Before:** `0x0000000000000000000000003dbfb370be95eb598c8b89b45d7c101dc1679ab9`
  - **After:** `0x000000000000000000000000af5d8df055ff00a51fae4bc141182fbd65225f27` (newly deployed contract)
  - **Summary:** Updated FaultDisputeGame implementation for game type 1

- **Key:**          `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b`
  - **Decoded Kind:** `gameImpls[0]` (FaultDisputeGame mapping)
  - **Before:** `0x00000000000000000000000038c2b9a214cdc3bbbc4915dae8c2f0a7917952dd`
  - **After:** `0x0000000000000000000000000cd0bcdba5978d4e0258e23abbd5216a36a2177c` (newly deployed contract)
  - **Summary:** Updated FaultDisputeGame implementation for game type 0

  ---

### `0x16fc5058f25648194471939df75cf27a2fdc48bc` ([OptimismPortal2](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/op.toml#L59)) - Chain ID: 11155420

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** Contract reinitialized during upgrade (_initialized incremented from 1 to 2)

- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000003e`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000a1cec548926eb5d69aa3b7b57d371edbdd03e64b` (newly deployed contract)
  - **Summary:** Previously unused storage gap slot now populated during upgrade

- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000003f`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000c38de74a8b0f6c671669cfb36e160548fb4a0c05` (newly deployed contract)
  - **Summary:** Previously unused storage gap slot now populated during upgrade

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0xB443Da3e07052204A02d630a8933dAc05a0d6fB4`
  - **After:** [`0xEFEd7F38BB9BE74bBa583a1A5B7D0fe7C9D5787a`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L12)
  - **Summary:** ERC-1967 implementation slot updated upgraded to OptimismPortal2 v4.6.0

  ---

### `0x1ac76f0833bbfccc732cadcc3ba8a3bbd0e89c3d` ([OPContractsManager](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/validation/standard/standard-versions-sepolia.toml#L42))

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Summary:** isRC flag set to false

  ---

### `0x1e4578692cd39faad678f5d78b65b584b355bc69` (DelayedWETH Proxy - newly deployed for Ink chain)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** Initializer version incremented from 0 to 1 Contract initialized (_initialized set to 1)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000004`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** [`0x00000000000000000000000005c993e60179f28bf649a2bb5b00b5f4283bd525`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L60)
  - **Summary:** Configuration reference set to Ink chain SystemConfig

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x33Dadc2d1aA9BB613A7AE6B28425eA00D44c6998`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L14)
  - **Summary:** ERC-1967 implementation slot updated set to DelayedWETH v1.5.0

- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0xd7dB319a49362b2328cf417a934300cCcB442C8d`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L61)
  - **Summary:** Proxy owner address set set to Ink chain ProxyAdmin

  ---

### `0x1eb2ffc903729a0f03966b917003800b145f56e2` ([ProxyAdminOwner (GnosisSafe)](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-config-roles-sepolia.toml#L3)) - Chain ID: 11155420

- **Account Nonce in State:**
  - **Before:** 27
  - **After:** 39
  - **Detail:** 12 new contracts were deployed, including the following for both OP and Ink chains:
    - Two dispute games
    - Two new delayed WETH proxies
    - A new ETHLockbox proxy
    - A new AnchorStateRegistry proxy

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `30`
  - **After:** `31`
  - **Summary:** nonce incremented (transaction executed)

  ---

### `0x299d7ea9f0b584cfaf2a5341d151b44967594ca9` (AnchorStateRegistry Proxy - newly deployed for Ink chain)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000005c993e60179f28bf649a2bb5b00b5f4283bd5250001`
  - **Summary:** Packed slot with superchainConfig ([`0x05c993e60179f28bf649a2bb5b00b5f4283bd525`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L60)) and _initialized=1

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000860e626c700af381133d9f4af31412a2d1db3d5d`
  - **Summary:** disputeGameFactory set to [`0x860e626c700af381133d9f4af31412a2d1db3d5d`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L65) (DisputeGameFactoryProxy for Ink)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000003`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x269d89e7b7e7fc214dee16c3eb62cde71e1b3797ae64f0c73defd4e051f6d26c`
  - **Summary:** anchor state mapping key set to specific anchor state hash (dispute game result)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000004`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000000000000000000000000000000000000000013b06c7`
  - **Summary:** startingBlockNumber set.

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000006`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000006852c88800000000`
  - **Summary:** retirementTimestamp set.

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0xeb69cC681E8D4a557b30DFFBAd85aFfD47a2CF2E`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L13)
  - **Summary:** ERC-1967 implementation slot updated set to AnchorStateRegistry v3.5.0

- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0xd7dB319a49362b2328cf417a934300cCcB442C8d`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L61)
  - **Summary:** Proxy owner set to ProxyAdminOwner for Ink

  ---

### `0x33f60714bbd74d62b66d79213c348614de51901c` ([L1StandardBridgeProxy](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L57)) - Chain ID: 763373

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** _initialized flag incremented from 1 to 2 (initialization completed)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000034`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000000005c993e60179f28bf649a2bb5b00b5f4283bd525`
  - **Summary:** superchainConfig set to [`0x05c993e60179f28bf649a2bb5b00b5f4283bd525`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L60) (SystemConfigProxy for Ink)

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0b09ba359A106C9ea3b181CBc5F394570c7d2a7A`
  - **After:** [`0x44AfB7722AF276A601D524F429016A18B6923df0`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L20)
  - **Summary:** ERC-1967 implementation upgraded to L1StandardBridge v2.6.0

  ---

### `0x3454f9df5e750f1383e58c1cb001401e7a4f3197` ([AddressManager](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L54)) - Chain ID: 763373

- **Key:**          `0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e`
  - **Before:** [`0x0000000000000000000000005d5a095665886119693f0b41d8dfee78da033e8b`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L38)
  - **After:** [`0x000000000000000000000000d26bb3aaaa4cb5638a8581a4c4b1d937d8e05c54`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L18)
  - **Summary:** L1CrossDomainMessenger implementation upgraded to v2.9.0

  ---

### `0x58cc85b8d04ea49cc6dbd3cbffd00b4b8d6cb3ef` ([L1CrossDomainMessengerProxy](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/op.toml#L55)) - Chain ID: 11155420

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000010000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000020000000000000000000000000000000000000000`
  - **Summary:** _initialized flag incremented from 1 to 2 (initialization completed)

- **Key:**          `0x00000000000000000000000000000000000000000000000000000000000000fe`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000034edd2a225f7f429a63e0f1d2084b9e0a93b538`
  - **Summary:** systemConfig set to [`0x034edd2a225f7f429a63e0f1d2084b9e0a93b538`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/op.toml#L60) (SystemConfigProxy for OP)

  ---

### `0x5c1d29c6c9c8b0800692acc95d700bcb4966a1d7` ([OptimismPortalProxy](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L59)) - Chain ID: 763373

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** Contract reinitialized during upgrade (_initialized incremented from 1 to 2)

- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000003e`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** [`0x000000000000000000000000299d7ea9f0b584cfaf2a5341d151b44967594ca9`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L66)
  - **Summary:** `anchorStateRegistry` (slot 62) set to AnchorStateRegistryProxy for Ink

- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000003f`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000636f1e307cae86c0f93ef7e1443a0fcf01947b2c`
  - **Summary:** systemConfig (slot 55) set to newly deployed ETHLockbox proxy `0x636f1e307cae86c0f93ef7e1443a0fcf01947b2c`

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0xB443Da3e07052204A02d630a8933dAc05a0d6fB4`
  - **After:** [`0xEFEd7F38BB9BE74bBa583a1A5B7D0fe7C9D5787a`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L12)
  - **Summary:** ERC-1967 implementation upgraded to OptimismPortal v4.6.0

  ---

### `0x636f1e307cae86c0f93ef7e1443a0fcf01947b2c` (ETHLockbox Proxy - newly deployed contract)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000005c993e60179f28bf649a2bb5b00b5f4283bd5250001`
  - **Summary:** Packed slot with systemConfig ([`0x05c993e60179f28bf649a2bb5b00b5f4283bd525`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L60)) and _initialized=1

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x784d2F03593A42A6E4676A012762F18775ecbBe6`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L15)
  - **Summary:** ERC-1967 implementation slot updated set to ETHLockbox v1.2.0

- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0xd7dB319a49362b2328cf417a934300cCcB442C8d`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L61)
  - **Summary:** Proxy owner address set set to Ink chain ProxyAdmin

- **Key:**          `0xea0b22f73ed4c3337cef1435de18103db664e6ae0b7570fc56ea0ff4b86cba57`
  - **Decoded Kind:** `authorizedPortals[0x5c1d29c6c9c8b0800692acc95d700bcb4966a1d7]` (mapping)
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** [`0x5c1d29c6c9c8b0800692acc95d700bcb4966a1d7`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L59) (OptimismPortalProxy for Ink) authorized in ETHLockbox authorizedPortals mapping

  ---

### [`0x860e626c700af381133d9f4af31412a2d1db3d5d`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L65) (DisputeGameFactory) - Chain ID: 763373

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x4bbA758F006Ef09402eF31724203F316ab74e4a0`
  - **After:** [`0x33D1e8571a85a538ed3D5A4d88f46C112383439D`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L16)
  - **Summary:** ERC-1967 implementation slot updated upgraded to DisputeGameFactory v1.2.0

- **Key:**          `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`
  - **Decoded Kind:** `gameImpls[1]` (FaultDisputeGame mapping)
  - **Before:** [`0x00000000000000000000000097766954baf17e3a2bfa43728830f0fa647f7546`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L68)
  - **After:** `0x000000000000000000000000d1195498324cff527e17b725f2f5c49e86585128` (newly deployed contract)
  - **Summary:** Updated FaultDisputeGame implementation for game type 1

- **Key:**          `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b`
  - **Decoded Kind:** `gameImpls[0]` (FaultDisputeGame mapping)
  - **Before:** [`0x000000000000000000000000bd72dd2fb74a537b9b47b454614a15b066cc464a`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L66)
  - **After:** `0x0000000000000000000000001248811b4d2c8eea7c8a7f8e3702bc2c47eb1672` (newly deployed contract)
  - **Summary:** Updated FaultDisputeGame implementation for game type 0

  ---

### `0x88403997654873cb54082a881f14fbe48dd68609` (DelayedWETH Proxy - newly deployed for Ink chain)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** Initializer version incremented from 0 to 1 Initializer version incremented from 0 to 1

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000004`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** [`0x00000000000000000000000005c993e60179f28bf649a2bb5b00b5f4283bd525`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L60)
  - **Summary:** SystemConfig address set to Ink chain SystemConfig

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x33Dadc2d1aA9BB613A7AE6B28425eA00D44c6998`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L14)
  - **Summary:** ERC-1967 implementation slot updated set to DelayedWETH v1.5.0

- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0xd7dB319a49362b2328cf417a934300cCcB442C8d`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L61)
  - **Summary:** Proxy owner address set set to Ink ProxyAdmin

  ---

### [`0x9bfe9c5609311df1c011c47642253b78a4f33f4b`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/op.toml#L54) (AddressManager) - Chain ID: 11155420

- **Key:**          `0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e`
  - **Before:** [`0x0000000000000000000000005d5a095665886119693f0b41d8dfee78da033e8b`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L38)
  - **After:** [`0x000000000000000000000000d26bb3aaaa4cb5638a8581a4c4b1d937d8e05c54`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L18)
  - **Summary:** L1CrossDomainMessenger implementation updated from v2.6.0 to v2.9.0

  ---

### [`0x9fe1d3523f5342535e6e7770ed09ed85dbc1acc2`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L55) (L1CrossDomainMessenger) - Chain ID: 763373

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000010000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000020000000000000000000000000000000000000000`
  - **Summary:** Initializer version incremented from 1 to 2

- **Key:**          `0x00000000000000000000000000000000000000000000000000000000000000fe`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** [`0x00000000000000000000000005c993e60179f28bf649a2bb5b00b5f4283bd525`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L60)
  - **Summary:** SystemConfig address set to Ink chain SystemConfig

  ---

### `0xa1cec548926eb5d69aa3b7b57d371edbdd03e64b` ([AnchorStateRegistry](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L63))

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000034edd2a225f7f429a63e0f1d2084b9e0a93b5380001`
  - **Summary:** SystemConfig address set to [`0x034edd2a225f7f429a63e0f1d2084b9e0a93b538`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/op.toml#L60) and initializer version incremented to 1

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** [`0x00000000000000000000000005f9613adb30026ffd634f38e5c4dfd30a197fa1`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/op.toml#L64)
  - **Summary:** DisputeGameFactory address set to OP Sepolia DisputeGameFactory

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000003`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0xe90c894a71b4599aafad8019a22925aa02b8cbe9f25376c3861b7cd6fafa40a4`
  - **Summary:** Starting anchor root hash set for initial state

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000004`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000001b958a0`
  - **Summary:** Starting anchor root L2 block number set

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000006`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000006852c88800000000`
  - **Summary:** Respected game type set to 0 with retirement timestamp

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0xeb69cC681E8D4a557b30DFFBAd85aFfD47a2CF2E`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L13)
  - **Summary:** ERC-1967 implementation slot updated set to AnchorStateRegistry v3.5.0

- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x189aBAAaa82DfC015A588A7dbaD6F13b1D3485Bc`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/op.toml#L61)
  - **Summary:** Proxy owner address set set to OP Sepolia ProxyAdmin

  ---

### [`0xc2be75506d5724086deb7245bd260cc9753911be`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/superchain.toml#L5) (SuperchainConfig) - Chain ID: 11011

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x000000000000000000007a50f00e8d05b95f98fe38d8bee366a7324dcf7e0002`
  - **Summary:** Guardian set to [`0x7a50f00e8D05b95F98fE38d8BeE366a7324dCf7E`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L47) and initializer version incremented to 2

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** [`0x4da82a327773965b8d4D85Fa3dB8249b387458E7`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L43)
  - **After:** [`0xCe28685EB204186b557133766eCA00334EB441E4`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L23)
  - **Summary:** ERC-1967 implementation slot updated updated from SuperchainConfig v1.2.0 to v2.3.0

- **Key:**          `0xd30e835d3f35624761057ff5b27d558f97bd5be034621e62240e5c0b784abe68`
  - **Decoded Kind:** `address`
  - **Before:** [`0x7a50f00e8D05b95F98fE38d8BeE366a7324dCf7E`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L47)
  - **After:** `0x0000000000000000000000000000000000000000`
  - **Summary:** Guardian address cleared from pause timestamps mapping

  ---

### `0xc350c54c484ac9111fc61c247580abcc5fcc365f` (DelayedWETH Proxy - newly deployed for OP)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** Initializer version incremented from 0 to 1

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000004`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** [`0x000000000000000000000000034edd2a225f7f429a63e0f1d2084b9e0a93b538`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/op.toml#L60)
  - **Summary:** SystemConfig address set to OP Sepolia SystemConfig

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x33Dadc2d1aA9BB613A7AE6B28425eA00D44c6998`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L14)
  - **Summary:** ERC-1967 implementation slot updated

- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x189aBAAaa82DfC015A588A7dbaD6F13b1D3485Bc`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/op.toml#L61)
  - **Summary:** Proxy owner address set

  ---

### `0xc38de74a8b0f6c671669cfb36e160548fb4a0c05` ([ETHLockbox](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/op.toml#L115))

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000034edd2a225f7f429a63e0f1d2084b9e0a93b5380001`
  - **Summary:** SystemConfig address set to [`0x034edd2a225f7f429a63e0f1d2084b9e0a93b538`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/op.toml#L60) and initializer version incremented to 1

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x784d2F03593A42A6E4676A012762F18775ecbBe6`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L15)
  - **Summary:** ERC-1967 implementation slot updated

- **Key:**          `0x5ebb8b440881cb51b1c7cd664fb2730eb6b54aa75b0ba6e2be9b5aad1c9a869b`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** ETH authorization state initialized

- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x189aBAAaa82DfC015A588A7dbaD6F13b1D3485Bc`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/op.toml#L61)
  - **Summary:** Proxy owner address set


  ---

### [`0xd1c901bbd7796546a7ba2492e0e199911fae68c7`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L56) (L1ERC721Bridge) - Chain ID: 763373

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** Initializer version incremented from 1 to 2

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** [`0x00000000000000000000000005c993e60179f28bf649a2bb5b00b5f4283bd525`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L60)
  - **Summary:** SystemConfig address set to Ink chain SystemConfig

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x7aE1d3BD877a4C5CA257404ce26BE93A02C98013`
  - **After:** [`0x25d6CeDEB277Ad7ebEe71226eD7877768E0B7A2F`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L19)
  - **Summary:** ERC-1967 implementation slot updated

---

### [`0xd83e03d576d23c9aeab8cc44fa98d058d2176d1f`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/op.toml#L56) (L1ERC721Bridge) - Chain ID: 11155420

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** Initializer version incremented from 1 to 2

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** [`0x000000000000000000000000034edd2a225f7f429a63e0f1d2084b9e0a93b538`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/op.toml#L60)
  - **Summary:** SystemConfig address set to OP Sepolia SystemConfig


- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x7aE1d3BD877a4C5CA257404ce26BE93A02C98013`
  - **After:** [`0x25d6CeDEB277Ad7ebEe71226eD7877768E0B7A2F`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L19)
  - **Summary:** ERC-1967 implementation slot updated


  ---

  ### `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B` (GnosisSafe) - Sepolia Foundation Safe

**Note: You'll only see this state diff if signer is on foundation safe: `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`. Ignore if you're signing for the council safe: `0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`.**

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `44`
  - **After:** `45`
  - **Summary:**  Nonce update

  ---

  ### `0xf64bc17485f0B4Ea5F06A96514182FC4cB561977` (GnosisSafe) - Sepolia Council Safe

**Note: You'll only see this state diff if signer is on council safe: `0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`. Ignore if you're signing for the foundation safe: `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`.**

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `40`
  - **After:** `41`
  - **Summary:**  Nonce update

---

### `0xf8d7b42e1ad39f0e321cf8bf913e0e4cd1c1f571` (DelayedWETH Proxy - newly deployed for OP)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** Initializer version incremented from 0 to 1

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000004`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** [`0x000000000000000000000000034edd2a225f7f429a63e0f1d2084b9e0a93b538`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/op.toml#L60)
  - **Summary:** SystemConfig address set to OP Sepolia SystemConfig

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x33Dadc2d1aA9BB613A7AE6B28425eA00D44c6998`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L14)
  - **Summary:** ERC-1967 implementation slot updated

- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x189aBAAaa82DfC015A588A7dbaD6F13b1D3485Bc`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/op.toml#L61)
  - **Summary:** Proxy owner address set

  ---

### [`0xfbb0621e0b23b5478b630bd55a5f21f67730b0f1`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/op.toml#L57) (L1StandardBridge) - Chain ID: 11155420

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** Initializer version incremented from 1 to 2

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000034`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** [`0x000000000000000000000000034edd2a225f7f429a63e0f1d2084b9e0a93b538`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/op.toml#L60)
  - **Summary:** SystemConfig address set to OP Sepolia SystemConfig

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0b09ba359A106C9ea3b181CBc5F394570c7d2a7A`
  - **After:** [`0x44AfB7722AF276A601D524F429016A18B6923df0`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L20)
  - **Summary:** ERC-1967 implementation slot updated