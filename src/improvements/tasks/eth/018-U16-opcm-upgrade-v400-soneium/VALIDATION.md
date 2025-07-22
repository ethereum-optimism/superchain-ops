# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are
signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Verifying the transaction input](#understanding-task-calldata)
3. [Verifying the state changes](#state-changes)

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Security Council - `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`
>
> - Domain Hash: `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0xce40e3decaa02589fcdb44bcc57e7f4dc9f20453b6a789f7851a202d8c9931ae`
>
> ### Optimism Foundation - `0x847B5c174615B1B7fDF770882256e2D3E95b9D92`
>
> - Domain Hash: `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0x7cf562d07268a0573c5d4b7ef53e78848ea3159c2e10fbb6b33234806ff7cede`

## Normalized State Diff Hash Attestation

The normalized state diff hash **MUST** match the hash produced by the state changes attested to in the state diff audit report. As a signer, you are responsible for verifying that this hash is correct. Please compare the hash below with the one in the audit report. If no audit report is available for this task, you must still ensure that the normalized state diff hash matches the output in your terminal.

**Normalized hash:** `0xcca3402e8f555f6cc96b34945ca5c674d6c53da7582f49e9ae833f26ed71dd05`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the OPCM upgrade to v4.0.0.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `opcm.upgrade()`

For each chain being upgrade, the `opcm.upgrade()` function is called with a tuple of three elements:

1. Soneium:
    - SystemConfigProxy: [0x7a8ed66b319911a0f3e7288bddab30d9c0c875c3](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/mainnet/soneium.toml#L58)
    - ProxyAdmin: [0x89889b569c3a505f3640ee1bd0ac1d557f436d2a](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/mainnet/soneium.toml#L59)
    - AbsolutePrestate: [0x03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8](https://www.notion.so/oplabs/U16-Update-Cannon-for-go1-23-1f4f153ee1628012beb5f016a3bfef0a)


Thus, the command to encode the calldata is:


```bash
cast calldata 'upgrade((address,address,bytes32)[])' "[(0x7a8ed66b319911a0f3e7288bddab30d9c0c875c3,0x89889b569c3a505f3640ee1bd0ac1d557f436d2a,0x03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8)]"
```

### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the argument to the `Multicall3DelegateCall.aggregate3()` function.

This function is called with a tuple of three elements:


Call3 struct for Multicall3DelegateCall:
- `target`: [0x56ebc5c4870f5367b836081610592241ad3e0734](https://github.com/ethereum-optimism/superchain-registry/blob/88bed19aadb11d22e34aa1a1236530c061fb747b/validation/standard/standard-versions-mainnet.toml#L22) - Mainnet OPContractsManager v3.0.0
- `allowFailure`: false
- `callData`: `0xff2dd5a1...` (output from the previous section)

Command to encode:
```bash
cast calldata 'aggregate3((address,bool,bytes)[])' "[(0x56ebc5c4870f5367b836081610592241ad3e0734,false,0xff2dd5a1000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000007a8ed66b319911a0f3e7288bddab30d9c0c875c300000000000000000000000089889b569c3a505f3640ee1bd0ac1d557f436d2a03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x82ad56cb00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000056ebc5c4870f5367b836081610592241ad3e07340000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a4ff2dd5a1000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000007a8ed66b319911a0f3e7288bddab30d9c0c875c300000000000000000000000089889b569c3a505f3640ee1bd0ac1d557f436d2a03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc800000000000000000000000000000000000000000000000000000000
```

In mainnet runbooks, this calldata should appear in [Action Plan](https://gov.optimism.io/t/upgrade-16-proposal-interop-contracts-stage-1-and-go-1-23-support-in-cannon/10037) section of the Governance proposal.


## Task Transfers

### Decoded Transfer 0
  - **From:**              [`0x88e529A6ccd302c948689Cd5156C83D4614FAE92`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/soneium.toml#L58) (OptimismPortal2 - Soneium)
  - **To:**                `0x67B4de6FfA66EF201Ea6099A89cA397D56622E31` (Newly deployed ETHLockboxProxy)
  - **Value:**             `9327163640386103948987` (All the funds)
  - **Token Address:**     `0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE` (Ether)


## Task State Changes

### `0x372dc0b87b790d6e1308cf9e7f73f0f1fcbd3754` (DelayedWETHProxy) - Chain ID: 1868

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** _initialized flag set to 1 (initialization completed)
  - **Detail:** Reinitializable pattern - marks contract as initialized

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000004`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000007a8ed66b319911a0f3e7288bddab30d9c0c875c3`
  - **Summary:** systemConfig set to [`0x7a8ed66b319911a0f3e7288bddab30d9c0c875c3`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/soneium.toml#L59)
  - **Detail:** Points to SystemConfigProxy for Soneium

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x33Dadc2d1aA9BB613A7AE6B28425eA00D44c6998`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L14)
  - **Summary:** ERC-1967 implementation upgraded to DelayedWETH v1.5.0
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x89889B569c3a505f3640ee1Bd0ac1D557f436D2a`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/soneium.toml#L60)
  - **Summary:** Proxy owner set to ProxyAdminOwner for Soneium
  - **Detail:** Standard slot for storing the owner address in a Proxy contract.

  ---

### `0x4890928941e62e273da359374b105f803329f473` ([AnchorStateRegistryProxy](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/soneium.toml#L62)) - Chain ID: 1868 (Newly Deployed)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000007a8ed66b319911a0f3e7288bddab30d9c0c875c30001`
  - **Summary:** _initialized flag set to 1 and systemConfig address packed in slot 0
  - **Detail:** Packed storage slot containing initialization flag and [SystemConfig](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/soneium.toml#L58) address

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000512a3d2c7a43bd9261d2b8e8c9c70d4bd4d503c0`
  - **Summary:** disputeGameFactory set to Soneium DisputeGameFactory proxy
  - **Detail:** Storage slot 1 holds the [DisputeGameFactory proxy address](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/soneium.toml#L64) for Soneium

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000003`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** See validation instructions below
  - **Summary:** startingAnchorRoot struct first half initialized for Soneium
  - **Detail:** Storage slot 3 contains the first 32 bytes of the 64-byte startingAnchorRoot [Proposal struct](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v4.0.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L44-L47), which is a Hash.
    The actual value MAY differ based on the most recently finalized L2 output.

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000004`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** See validation instructions below
  - **Summary:** startingAnchorRoot struct second half initialized for Soneium
  - **Detail:** Storage slot 4 contains the second 32 bytes of the 64-byte startingAnchorRoot [Proposal struct](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v4.0.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L44-L47), which is an L2 block number.

    **VALIDATION:** To verify the correct values for slots 3 and 4, run the following command using the same block number as your simulation.
      It should return two values, the first being the hash (slot 3) and the second being the block number (slot 4).

    ```
    cast call --block <simulation-block-number> 0x190B6ecEE5A2ddF39669288B9B8daEa4641ae8b1 'anchors(uint32)(bytes32,bytes32)' 0
    ```

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000006`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** See validation instructions below
  - **Summary:** Packed slot with respectedGameType and retirementTimestamp initialized for Soneium
  - **Detail:** The non-zero values should correspond to recent timestamp values, as [set](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v4.0.0/packages/contracts-bedrock/src/dispute/AnchorStateRegistry.sol#L106) in the AnchorStateRegistry's initialize function.

    **VALIDATION:** The value in slot 6 will differ from simulation to simulation based on chain state. The following cast command should return a value
      matching the timestamp of the simulation:

      ```
      cast to-dec $(cast shr <after-value> 32)
      ```

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0xeb69cC681E8D4a557b30DFFBAd85aFfD47a2CF2E`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L13)
  - **Summary:** ERC-1967 implementation upgraded to AnchorStateRegistry v3.5.0
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x89889B569c3a505f3640ee1Bd0ac1D557f436D2a`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/soneium.toml#L60)
  - **Summary:** Proxy owner set to ProxyAdminOwner for Soneium
  - **Detail:** Standard slot for storing the owner address in a Proxy contract.

  ---

### `0x512a3d2c7a43bd9261d2b8e8c9c70d4bd4d503c0` ([DisputeGameFactoryProxy](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/soneium.toml#L64)) - Chain ID: 1868

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x4bbA758F006Ef09402eF31724203F316ab74e4a0`
  - **After:** [`0x33D1e8571a85a538ed3D5A4d88f46C112383439D`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L16)
  - **Summary:** ERC-1967 implementation upgraded to DisputeGameFactory v1.2.0
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

- **Key:**          `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`
  - **Before:** [`0x0000000000000000000000003d56d47b9e7e34a46612badc70377f74051e6b17`](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/superchain/configs/mainnet/soneium.toml#L67)
  - **After:** `0x0000000000000000000000003c12f1f4f0702cb7fc83e2e5594331c10b9e39b4` (Newly deployed DisputeGameFactory)
  - **Summary:** gameImpls mapping updated - GameType 1 implementation changed
  - **Detail:** Mapping slot derivation for gameImpls[GameType(1)] - updated game implementation address for GameType 1

  ---


  ---

### `0x5933e323be8896dfacd1cd671442f27daa10a053` ([L1ERC721BridgeProxy](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/soneium.toml#L55)) - Chain ID: 1868

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** _initialized flag incremented from 1 to 2 (re-initialization completed)
  - **Detail:** Reinitializable pattern - packed slot with _initialized and _initializing flags

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000007a8ed66b319911a0f3e7288bddab30d9c0c875c3`
  - **Summary:** systemConfig set to [`0x7a8ed66b319911a0f3e7288bddab30d9c0c875c3`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/soneium.toml#L59)
  - **Detail:** Points to SystemConfigProxy for Soneium

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x7aE1d3BD877a4C5CA257404ce26BE93A02C98013`
  - **After:** [`0x25d6CeDEB277Ad7ebEe71226eD7877768E0B7A2F`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L19)
  - **Summary:** ERC-1967 implementation upgraded to L1ERC721Bridge v2.7.0
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

  ---

### `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a` ([ProxyAdminOwner](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/soneium.toml#L45) (GnosisSafe)) - Chain ID: 10

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `21`
  - **After:** `22`
  - **Summary:** nonce incremented from 21 to 22
  - **Detail:** GnosisSafe transaction nonce incremented after successful transaction execution

  ---

### `0x67b4de6ffa66ef201ea6099a89ca397d56622e31` (ETHLockboxProxy) - Chain ID: 1868

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000007a8ed66b319911a0f3e7288bddab30d9c0c875c30001`
  - **Summary:** Packed slot with systemConfig ([`0x7a8ed66b319911a0f3e7288bddab30d9c0c875c3`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/soneium.toml#L59)) and _initialized=1
  - **Detail:** ETHLockbox packed storage - SystemConfigProxy address + initialization flag

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x784d2F03593A42A6E4676A012762F18775ecbBe6`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L15)
  - **Summary:** ERC-1967 implementation upgraded to ETHLockbox v1.2.0
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

- **Key:**          `0x58321ae9f41f6a103febd5c3a9a0fcce07f40d75e877fda01183207281661d60`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** authorizedPortals mapping - OptimismPortal for Soneium authorized
  - **Detail:** Mapping slot derivation for authorizedPortals[OptimismPortalProxy] = true

- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x89889B569c3a505f3640ee1Bd0ac1D557f436D2a`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/soneium.toml#L60)
  - **Summary:** Proxy owner set to ProxyAdminOwner for Soneium
  - **Detail:** Standard slot for storing the owner address in a Proxy contract.

  ---

### `0x7a8ed66b319911a0f3e7288bddab30d9c0c875c3` ([SystemConfigProxy](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/soneium.toml#L59)) - Chain ID: 1868

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** _initialized flag incremented from 1 to 2 (re-initialization completed)
  - **Detail:** Reinitializable pattern - packed slot with _initialized and _initializing flags

- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000006b`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000000000000000000000000000000000000000074c`
  - **Summary:** l2ChainId set to 1868 (Soneium chain ID)
  - **Detail:** L2 chain ID configured for Soneium network

- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000006c`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c`
  - **Summary:** superchainConfig set to [`0x95703e0982140d16f8eba6d158fccede42f04a4c`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/soneium.toml#L61)
  - **Detail:** Points to SuperchainConfigProxy on mainnet

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** [`0x340f923E5c7cbB2171146f64169EC9d5a9FfE647`](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/validation/standard/standard-versions-mainnet.toml#L69)
  - **After:** [`0xFaA660bf783CBAa55e1B7F3475C20Db74a53b9Fa`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L8)
  - **Summary:** ERC-1967 implementation upgraded to SystemConfig v3.4.0
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

- **Key:**          `0x52322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906`
  - **Decoded Kind:** `address`
  - **Before:** [`0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/soneium.toml#L64)
  - **After:** `0x0000000000000000000000000000000000000000`
  - **Summary:** disputeGameFactory cleared (set to zero address)
  - **Detail:** Unstructured storage slot for the address of the DisputeGameFactory proxy - temporarily cleared during upgrade process

  ---

### `0x88e529a6ccd302c948689cd5156c83d4614fae92` ([OptimismPortalProxy](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/soneium.toml#L58)) - Chain ID: 1868

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** _initialized flag incremented from 1 to 2 (re-initialization completed)
  - **Detail:** Reinitializable pattern - packed slot with _initialized and _initializing flags

- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000003e`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000004890928941e62e273da359374b105f803329f473`
  - **Summary:** anchorStateRegistry set to newly deployed AnchorStateRegistryProxy for Soneium
  - **Detail:** Points to the newly deployed AnchorStateRegistryProxy

- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000003f`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000000067b4de6ffa66ef201ea6099a89ca397d56622e31`
  - **Summary:** ethLockbox set to newly deployed ETHLockboxProxy for Soneium
  - **Detail:** Points to the newly deployed ETHLockboxProxy

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** [`0xB443Da3e07052204A02d630a8933dAc05a0d6fB4`](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/validation/standard/standard-versions-sepolia.toml#L73)
  - **After:** [`0xEFEd7F38BB9BE74bBa583a1A5B7D0fe7C9D5787a`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L12)
  - **Summary:** ERC-1967 implementation upgraded to OptimismPortal v4.6.0
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

  ---

### `0x9cf951e3f74b644e621b36ca9cea147a78d4c39f` ([L1CrossDomainMessengerProxy](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/soneium.toml#L54)) - Chain ID: 1868

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000010000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000020000000000000000000000000000000000000000`
  - **Summary:** Packed slot with _initialized incremented from 1 to 2 (re-initialization completed)
  - **Detail:** L1CrossDomainMessenger packed storage - contains spacer + _initialized + _initializing flags

- **Key:**          `0x00000000000000000000000000000000000000000000000000000000000000fe`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000007a8ed66b319911a0f3e7288bddab30d9c0c875c3`
  - **Summary:** systemConfig set to [`0x7a8ed66b319911a0f3e7288bddab30d9c0c875c3`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/soneium.toml#L59)
  - **Detail:** Points to SystemConfigProxy for Soneium

  ---

### `0xb24bfeece1b3b7a44559f4cbc21bed312b130b70` ([AddressManager](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/soneium.toml#L52)) - Chain ID: 1868

- **Key:**          `0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e`
  - **Before:** [`0x0000000000000000000000005d5a095665886119693f0b41d8dfee78da033e8b`](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/validation/standard/standard-versions-mainnet.toml#L98)
  - **After:** [`0x000000000000000000000000d26bb3aaaa4cb5638a8581a4c4b1d937d8e05c54`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L18)
  - **Summary:** addresses mapping updated - L1CrossDomainMessenger implementation address changed
  - **Detail:** Mapping slot for addresses["L1CrossDomainMessenger"] - updated to L1CrossDomainMessenger v2.9.0 implementation

  ---

### `0xeb9bf100225c214efc3e7c651ebbadcf85177607` ([L1StandardBridgeProxy](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/soneium.toml#L56)) - Chain ID: 1868

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** _initialized flag incremented from 1 to 2 (re-initialization completed)
  - **Detail:** Reinitializable pattern - packed slot with _initialized, _initializing flags and spacer

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000034`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000007a8ed66b319911a0f3e7288bddab30d9c0c875c3`
  - **Summary:** systemConfig set to [`0x7a8ed66b319911a0f3e7288bddab30d9c0c875c3`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/soneium.toml#L59)
  - **Detail:** Points to SystemConfigProxy for Soneium

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** [`0x0b09ba359A106C9ea3b181CBc5F394570c7d2a7A`](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/validation/standard/standard-versions-mainnet.toml#L100)
  - **After:** [`0x44AfB7722AF276A601D524F429016A18B6923df0`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L20)
  - **Summary:** ERC-1967 implementation upgraded to L1StandardBridge v2.6.0
  - **Detail:** Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.

** Nonce Increments **

- `0x372dC0B87b790D6e1308CF9e7f73F0F1fcbD3754` (Newly deployed DelayedWETH)
- `0x4890928941e62e273dA359374b105F803329F473` (Newly deployed AnchorStateRegistryProxy)
- `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (L1 PAO on GnosisSafe)
- `0x67B4de6FfA66EF201Ea6099A89cA397D56622E31` (Newly deployed ETHLockboxProxy)
- `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (FoundationOperationSafe)
- `0x3c12f1F4F0702CB7fC83e2e5594331c10b9e39b4` (Newly deployed DisputeGameFactory)
- `0x42d27eEA1AD6e22Af6284F609847CB3Cd56B9c64` (Sender of the Tenderly transaction)
