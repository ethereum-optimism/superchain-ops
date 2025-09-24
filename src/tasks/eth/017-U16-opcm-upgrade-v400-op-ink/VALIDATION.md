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
> - Message Hash: `0x546ba8ee81704c05da28b68f54137c0cf05ad7a09bb517a5691be9cbed6c6577`
>
> ### Optimism Foundation - `0x847B5c174615B1B7fDF770882256e2D3E95b9D92`
>
> - Domain Hash: `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0x7d04a5c2306840bc0487d8585241d810eb0c690bbc9bc442df8403a38f80ebe0`

## Normalized State Diff Hash Attestation

The normalized state diff hash **MUST** match the hash produced by the state changes attested to in the state diff audit report. As a signer, you are responsible for verifying that this hash is correct. Please compare the hash below with the one in the audit report. If no audit report is available for this task, you must still ensure that the normalized state diff hash matches the output in your terminal.

**Normalized hash:** `0xa70090790ed38c3e99eae8543ebd06c886e9f0fe6f03b523a781d61a4404cec9`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the OPCM upgrade to v4.0.0.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `opcm.upgrade()`

For each chain being upgrade, the `opcm.upgrade()` function is called with a tuple of three elements:

1. OP Mainnet:
    - SystemConfigProxy: [0x229047fed2591dbec1ef1118d64f7af3db9eb290](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/mainnet/op.toml#L58)
    - ProxyAdmin: [0x543ba4aadbab8f9025686bd03993043599c6fb04](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/mainnet/op.toml#L59)
    - AbsolutePrestate: [0x03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8](https://www.notion.so/oplabs/U16-Update-Cannon-for-go1-23-1f4f153ee1628012beb5f016a3bfef0a)

2. Ink:
    - SystemConfigProxy: [0x62c0a111929fa32cec2f76adba54c16afb6e8364](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/mainnet/ink.toml#L58)
    - ProxyAdmin: [0xd56045e68956fce2576e680c95a4750cf8241f79](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/mainnet/ink.toml#L59)
    - AbsolutePrestate: [0x03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8](https://www.notion.so/oplabs/U16-Update-Cannon-for-go1-23-1f4f153ee1628012beb5f016a3bfef0a)


Thus, the command to encode the calldata is:


```bash
cast calldata 'upgrade((address,address,bytes32)[])' "[(0x229047fed2591dbec1ef1118d64f7af3db9eb290,0x543ba4aadbab8f9025686bd03993043599c6fb04,0x03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8),(0x62c0a111929fa32cec2f76adba54c16afb6e8364,0xd56045e68956fce2576e680c95a4750cf8241f79,0x03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8)]"
```

### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the argument to the `Multicall3DelegateCall.aggregate3()` function.

This function is called with a tuple of three elements:


Call3 struct for Multicall3DelegateCall:
- `target`: [0x56ebc5c4870f5367b836081610592241ad3e0734](https://github.com/ethereum-optimism/superchain-registry/blob/88bed19aadb11d22e34aa1a1236530c061fb747b/validation/standard/standard-versions-mainnet.toml#L22) - Mainnet OPContractsManager v4.0.0
- `allowFailure`: false
- `callData`: `0xff2dd5a1...` (output from the previous section)

Command to encode:
```bash
cast calldata 'aggregate3((address,bool,bytes)[])' "[(0x56ebc5c4870f5367b836081610592241ad3e0734,false,0xff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000229047fed2591dbec1ef1118d64f7af3db9eb290000000000000000000000000543ba4aadbab8f9025686bd03993043599c6fb0403eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc800000000000000000000000062c0a111929fa32cec2f76adba54c16afb6e8364000000000000000000000000d56045e68956fce2576e680c95a4750cf8241f7903eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x82ad56cb00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000056ebc5c4870f5367b836081610592241ad3e0734000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000104ff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000229047fed2591dbec1ef1118d64f7af3db9eb290000000000000000000000000543ba4aadbab8f9025686bd03993043599c6fb0403eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc800000000000000000000000062c0a111929fa32cec2f76adba54c16afb6e8364000000000000000000000000d56045e68956fce2576e680c95a4750cf8241f7903eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc800000000000000000000000000000000000000000000000000000000
```

In mainnet runbooks, this calldata should appear in [Action Plan](https://gov.optimism.io/t/upgrade-16-proposal-interop-contracts-stage-1-and-go-1-23-support-in-cannon/10037) section of the Governance proposal.

## Task Transfers

#### Decoded Transfer 0 (OP Mainnet)
  - **From:**              `0xbEb5Fc579115071764c7423A4f12eDde41f106Ed` - [OptimismPortal](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/op.toml#L58)
  - **To:**                `0x322b47Ff1FA8D5611F761e3E275C45B71b294D43` - ETHLockbox
  - **Value:**             `239697858685983334945689` - All funds
  - **Token Address:**     `0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE` - ETH

#### Decoded Transfer 1 (Ink)
  - **From:**              `0x5d66C1782664115999C47c9fA5cd031f495D3e4F` - [OptimismPortal](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/ink.toml#L58)
  - **To:**                `0xbd4AbB321138e8Eddc399cE64E66451294325a14` - ETHLockbox
  - **Value:**             `7312493031515086142193` - All funds
  - **Token Address:**     `0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE` - ETH

## Task State Changes

### `0x10d7b35078d3baabb96dd45a9143b94be65b12cd` ([DisputeGameFactoryProxy](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/ink.toml#L64)) - Chain ID: 57073

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** [`0x4bbA758F006Ef09402eF31724203F316ab74e4a0`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L76) - DisputeGameFactory v1.0.1
  - **After:** [`0x33D1e8571a85a538ed3D5A4d88f46C112383439D`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L16)
  - **Summary:** ERC-1967 implementation upgraded to DisputeGameFactory v1.2.0

- **Key:**          `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`
  - **Before:** `0x00000000000000000000000040641a4023f0f4c66d7f8ade16497f4c947a7163`
  - **After:** `0x00000000000000000000000046dde051eb4561694dc1f0286ebe940d9e90fbe9`
  - **Summary:** gameImpls mapping - FaultDisputeGame implementation updated (slot calculated from mapping key)

- **Key:**          `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b`
  - **Before:** `0x0000000000000000000000003ccf7c31a3a8c1b8aaa9a18fc2d010dde4262342`
  - **After:** `0x0000000000000000000000001a20c06a80260aa45ada0f9f59b334560ee3fef1`
  - **Summary:** gameImpls mapping - PermissionedDisputeGame implementation updated (slot calculated from mapping key)

  ---

### `0x229047fed2591dbec1ef1118d64f7af3db9eb290` ([SystemConfigProxy](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/op.toml#L59)) - Chain ID: 10

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** _initialized flag incremented from 1 to 2 (initialization completed)

- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000006b`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000000000000000000000000000000000000000000a`
  - **Summary:** l2ChainId set to 10 (OP Mainnet chain ID)

- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000006c`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** [`0x00000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/superchain.toml#L3)
  - **Summary:** superchainConfig set to SuperchainConfig proxy

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** [`0x340f923E5c7cbB2171146f64169EC9d5a9FfE647`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L69) - SystemConfig 2.5.0
  - **After:** [`0xFaA660bf783CBAa55e1B7F3475C20Db74a53b9Fa`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L8)
  - **Summary:** ERC-1967 implementation upgraded to SystemConfig v3.4.0

- **Key:**          `0x52322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906`
  - **Decoded Kind:** `address`
  - **Before:** [`0xe5965Ab5962eDc7477C8520243A95517CD252fA9`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/op.toml#L63)
  - **After:** `0x0000000000000000000000000000000000000000`
  - **Summary:** DisputeGameFactory proxy address cleared (legacy slot deprecated)

  ---

### `0x23b2c62946350f4246f9f9d027e071f0264fd113` (AnchorStateRegistry) - Chain ID: 10 (Newly Deployed)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000229047fed2591dbec1ef1118d64f7af3db9eb2900001`
  - **Summary:** _initialized flag set to 1 and systemConfig address packed in slot 0
  - **Detail:** Packed storage slot containing initialization flag and [SystemConfig](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/op.toml#L58) address

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000e5965ab5962edc7477c8520243a95517cd252fa9`
  - **Summary:** disputeGameFactory set to OP DisputeGameFactory proxy
  - **Detail:** Storage slot 1 holds the [DisputeGameFactory proxy address](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/op.toml#L63) for OP Mainnet

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000003`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** See validation instructions below
  - **Summary:** startingAnchorRoot struct first half initialized for OP Mainnet
  - **Detail:** Storage slot 3 contains the first 32 bytes of the 64-byte startingAnchorRoot [Proposal struct](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v4.0.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L44-L47), which is a Hash.
    The actual value MAY differ based on the most recently finalized L2 output.

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000004`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** See validation instructions below
  - **Summary:** startingAnchorRoot struct second half initialized for OP Mainnet
  - **Detail:** Storage slot 4 contains the second 32 bytes of the 64-byte startingAnchorRoot [Proposal struct](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v4.0.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L44-L47), which is an L2 block number.
    
    **VALIDATION:** To verify the correct values for slots 3 and 4, run the following command using the same block number as your simulation.
      It should return two values, the first being the hash (slot 3) and the second being the block number (slot 4).

    ```
    cast call --block <simulation-block-number> 0x1c68ECfbf9C8B1E6C0677965b3B9Ecf9A104305b 'anchors(uint32)(bytes32,bytes32)' 0
    ```

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000006`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** See validation instructions below
  - **Summary:** Packed slot with respectedGameType and retirementTimestamp initialized for OP Mainnet
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

- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x543bA4AADBAb8f9025686Bd03993043599c6fB04`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/op.toml#L60) - OP ProxyAdmin
  - **Summary:** ERC-1967 admin slot set to ProxyAdmin address

  ---

### `0x25ace71c97b33cc4729cf772ae268934f7ab5fa1` ([L1CrossDomainMessenger](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/op.toml#L54)) - Chain ID: 10

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000010000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000020000000000000000000000000000000000000000`
  - **Summary:** _initialized flag incremented from 1 to 2 (initialization completed)
  - **Detail:** Packed storage slot 0 contains the initialization flag, incremented during contract upgrade

- **Key:**          `0x00000000000000000000000000000000000000000000000000000000000000fe`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000229047fed2591dbec1ef1118d64f7af3db9eb290`
  - **Summary:** systemConfig address set to OP SystemConfig proxy
  - **Detail:** Storage slot 254 holds the [SystemConfig proxy address](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/op.toml#L59)

  ---

### `0x322b47ff1fa8d5611f761e3e275c45b71b294d43` (ETHLockbox) - Chain ID: 10

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000229047fed2591dbec1ef1118d64f7af3db9eb2900001`
  - **Summary:** _initialized flag set to 1 and systemConfig address packed in slot 0
  - **Detail:** Packed storage slot containing initialization flag and [SystemConfig proxy address](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/op.toml#L59) address

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x784d2F03593A42A6E4676A012762F18775ecbBe6`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L15)
  - **Summary:** ERC-1967 implementation upgraded to ETHLockbox v1.2.0

- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x543bA4AADBAb8f9025686Bd03993043599c6fB04`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/op.toml#L60) - OP ProxyAdmin
  - **Summary:** ERC-1967 admin slot set to ProxyAdmin address

- **Key:**          `0xe94ce3e921cb2e9e760f8bafe43e7e1899b19b06eaa1979629b096fe61892398`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** authorizedPortals mapping - OP OptimismPortal authorized
  - **Detail:** Mapping slot authorizing [OP OptimismPortal](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/op.toml#L58) address in ETHLockbox

  ---

### `0x3f7b07a5d638024a37a776fa228fe90b317af6de` (DelayedWETH) - Chain ID: 57073

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** _initialized flag set to 1 (initialization completed)
  - **Detail:** Storage slot 0 contains the initialization flag for the DelayedWETH contract



- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000004`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000000062c0a111929fa32cec2f76adba54c16afb6e8364`
  - **Summary:** Set systemConfig to the [SystemConfig proxy address](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/op.toml#L59)
  - **Detail:** Slot containing SystemConfig address

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x33Dadc2d1aA9BB613A7AE6B28425eA00D44c6998`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L14)
  - **Summary:** ERC-1967 implementation upgraded to DelayedWETH v1.5.0

- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0xd56045E68956FCe2576E680c95a4750cf8241f79`](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/superchain/configs/mainnet/ink.toml#L60) - Ink ProxyAdmin
  - **Summary:** ERC-1967 admin slot set to ProxyAdmin address

  ---

### `0x56ebc5c4870f5367b836081610592241ad3e0734` ([OPContractsManager](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L22)) - Chain ID: 10

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Summary:** The `isRC` flag is set to zero.
  - **Detail:** Storage slot 1 contains the _initializing flag which is cleared after initialization completes



  ---

### `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a` ([ProxyAdminOwner](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/op.toml#L45) (GnosisSafe)) - Chain ID: 10

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `20`
  - **After:** `21`
  - **Summary:** nonce incremented from 20 to 21
  - **Detail:** Safe transaction nonce incremented after executing the upgrade transaction


  ---

### `0x5a7749f83b81b301cab5f48eb8516b986daef23d` ([L1ERC721Bridge](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/op.toml#L56)) - Chain ID: 10

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** _initialized flag incremented from 1 to 2 (re-initialization completed)
  - **Detail:** Packed storage slot 0 contains the initialization flag, incremented during contract upgrade

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000229047fed2591dbec1ef1118d64f7af3db9eb290`
  - **Summary:** systemConfig address set to OP SystemConfig proxy
  - **Detail:** Storage slot 51 holds the [SystemConfig proxy address](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/op.toml#L59)

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** [`0x7aE1d3BD877a4C5CA257404ce26BE93A02C98013`](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/validation/standard/standard-versions-mainnet.toml#L79) - L1ERC721Bridge 2.4.0
  - **After:** [`0x25d6CeDEB277Ad7ebEe71226eD7877768E0B7A2F`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L19)
  - **Summary:** ERC-1967 implementation upgraded to L1ERC721Bridge v2.7.0

  ---

### `0x5d66c1782664115999c47c9fa5cd031f495d3e4f` ([OptimismPortal2](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/ink.toml#L58)) - Chain ID: 57073

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** _initialized flag incremented from 1 to 2 (re-initialization completed)
  - **Detail:** Packed storage slot 0 contains the initialization flag, incremented during contract upgrade

- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000003e`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000ee018baf058227872540ac60efbd38b023d9dae2`
  - **Summary:** anchorStateRegistry address set to Ink AnchorStateRegistry proxy
  - **Detail:** Storage slot 62 holds the AnchorStateRegistry proxy address for Ink

- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000003f`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000bd4abb321138e8eddc399ce64e66451294325a14`
  - **Summary:** ethLockbox address set to Ink ETHLockbox proxy
  - **Detail:** Storage slot 63 holds the ETHLockbox proxy address for Ink

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** [`0xB443Da3e07052204A02d630a8933dAc05a0d6fB4`](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/validation/standard/standard-versions-mainnet.toml#L73) - OptimismPortal 3.14.0
  - **After:** [`0xEFEd7F38BB9BE74bBa583a1A5B7D0fe7C9D5787a`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L12)
  - **Summary:** ERC-1967 implementation upgraded to OptimismPortal v4.6.0

  ---

### `0x62c0a111929fa32cec2f76adba54c16afb6e8364` ([SystemConfig](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/ink.toml#L59)) - Chain ID: 57073

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** _initialized flag incremented from 1 to 2 (re-initialization completed)
  - **Detail:** Packed storage slot 0 contains the initialization flag, incremented during contract upgrade

- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000006b`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000000000000000000000000000000000000000def1`
  - **Summary:** l2ChainId set to 57073 (Ink chain ID)
  - **Detail:** Storage slot 107 holds the L2 chain ID for Ink

- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000006c`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c`
  - **Summary:** superchainConfig set to SuperchainConfig proxy
  - **Detail:** Storage slot 108 holds the [SuperchainConfig proxy address](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/ink.toml#L61)

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** [`0x340f923E5c7cbB2171146f64169EC9d5a9FfE647`](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/validation/standard/standard-versions-mainnet.toml#L69) - SystemConfig 2.5.0
  - **After:** [`0xFaA660bf783CBAa55e1B7F3475C20Db74a53b9Fa`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L8)
  - **Summary:** ERC-1967 implementation upgraded to SystemConfig v3.4.0

- **Key:**          `0x52322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906`
  - **Decoded Kind:** `address`
  - **Before:** `0x10d7B35078d3baabB96Dd45a9143B94be65b12CD`
  - **After:** `0x0000000000000000000000000000000000000000`
  - **Summary:** DisputeGameFactory proxy address
  - **Detail:** Unstructured storage slot for the address of the DisputeGameFactory proxy.


  ---

### `0x661235a238b11191211fa95d4dd9e423d521e0be` ([L1ERC721Bridge](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/ink.toml#L51)) - Chain ID: 57073

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** _initialized flag incremented from 1 to 2 (re-initialization completed)
  - **Detail:** Packed storage slot 0 contains the initialization flag, incremented during contract upgrade

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000000062c0a111929fa32cec2f76adba54c16afb6e8364`
  - **Summary:** systemConfig address set to Ink SystemConfig proxy
  - **Detail:** Storage slot 51 holds the [SystemConfig proxy address](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/ink.toml#L59)

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** [`0x7aE1d3BD877a4C5CA257404ce26BE93A02C98013`](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/validation/standard/standard-versions-mainnet.toml#L79) - L1ERC721Bridge 2.4.0
  - **After:** [`0x25d6CeDEB277Ad7ebEe71226eD7877768E0B7A2F`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L19)
  - **Summary:** ERC-1967 implementation upgraded to L1ERC721Bridge v2.7.0

  ---

### `0x69d3cf86b2bf1a9e99875b7e2d9b6a84426c171f` ([L1CrossDomainMessenger](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/ink.toml#L54)) - Chain ID: 57073

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000010000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000020000000000000000000000000000000000000000`
  - **Summary:** _initialized flag incremented from 1 to 2 (initialization completed)
  - **Detail:** Packed storage slot 0 contains the initialization flag, incremented during contract upgrade

- **Key:**          `0x00000000000000000000000000000000000000000000000000000000000000fe`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000000062c0a111929fa32cec2f76adba54c16afb6e8364`
  - **Summary:** systemConfig address set to Ink SystemConfig proxy
  - **Detail:** Storage slot 254 holds the [SystemConfig proxy address](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/ink.toml#L59)

  ---

### `0x88ff1e5b602916615391f55854588efcbb7663f0` ([L1StandardBridge](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/ink.toml#L56)) - Chain ID: 57073

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** _initialized flag incremented from 1 to 2 (re-initialization completed)
  - **Detail:** Packed storage slot 0 contains the initialization flag, incremented during contract upgrade

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000034`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000000062c0a111929fa32cec2f76adba54c16afb6e8364`
  - **Summary:** systemConfig address set to Ink SystemConfig proxy
  - **Detail:** Storage slot 52 holds the [SystemConfig proxy address](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/ink.toml#L59)

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** [`0x0b09ba359A106C9ea3b181CBc5F394570c7d2a7A`](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/validation/standard/standard-versions-mainnet.toml#L80) - L1StandardBridge 2.3.0
  - **After:** [`0x44AfB7722AF276A601D524F429016A18B6923df0`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L20)
  - **Summary:** ERC-1967 implementation upgraded to L1StandardBridge v2.6.0

  ---

### `0x95703e0982140d16f8eba6d158fccede42f04a4c` ([SuperchainConfig](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/ink.toml#L61)) - Chain ID: 10

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000009f7150d8c019bef34450d6920f6b3608cefdaf20002`
  - **Summary:** _initialized flag incremented from 1 to 2 and guardian address packed in slot 0
  - **Detail:** Packed storage slot containing initialization flag and guardian address [0x09f7150d8c019bef34450d6920f6b3608cefdaf2](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/ink.toml#L46)

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** [`0x4da82a327773965b8d4D85Fa3dB8249b387458E7`](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/validation/standard/standard-versions-mainnet.toml#L83) - SuperchainConfig 1.2.0
  - **After:** [`0xCe28685EB204186b557133766eCA00334EB441E4`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L23)
  - **Summary:** ERC-1967 implementation upgraded to SuperchainConfig v2.3.0

- **Key:**          `0xd30e835d3f35624761057ff5b27d558f97bd5be034621e62240e5c0b784abe68`
  - **Decoded Kind:** `address`
  - **Before:** `0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2`
  - **After:** `0x0000000000000000000000000000000000000000`
  - **Summary:** Guardian address
  - **Detail:** Unstructured storage slot for the address of the superchain guardian, removed as one of the main goals of U16.


  ---

### `0x99c9fc46f92e8a1c0dec1b1747d010903e884be1` ([L1StandardBridge](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/op.toml#L56)) - Chain ID: 10

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** _initialized flag incremented from 1 to 2 (re-initialization completed)
  - **Detail:** Packed storage slot 0 contains the initialization flag, incremented during contract upgrade

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000034`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000229047fed2591dbec1ef1118d64f7af3db9eb290`
  - **Summary:** systemConfig address set to OP SystemConfig proxy
  - **Detail:** Storage slot 52 holds the [SystemConfig proxy address](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/op.toml#L59)

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** [`0x0b09ba359A106C9ea3b181CBc5F394570c7d2a7A`](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/validation/standard/standard-versions-mainnet.toml#L80) - L1StandardBridge 2.3.0
  - **After:** [`0x44AfB7722AF276A601D524F429016A18B6923df0`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L20)
  - **Summary:** ERC-1967 implementation upgraded to L1StandardBridge v2.6.0

  ---

### `0x9b7c9bbd6d540a8a4dedd935819fc4408ba71153` ([AddressManager](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/ink.toml#L53)) - Chain ID: 57073

- **Key:**          `0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e`
  - **Before:** `0x0000000000000000000000005d5a095665886119693f0b41d8dfee78da033e8b`
  - **After:** `0x000000000000000000000000d26bb3aaaa4cb5638a8581a4c4b1d937d8e05c54`
  - **Summary:** _initialized flag set to 1 and systemConfig address packed in slot 0
  - **Detail:** Packed storage slot containing initialization flag and SystemConfig address

  ---

### `0xbd4abb321138e8eddc399ce64e66451294325a14` (ETHLockbox) - Chain ID: 57073

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000062c0a111929fa32cec2f76adba54c16afb6e83640001`
  - **Summary:** _initialized flag set to 1 and [SystemConfig proxy address](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/superchain/configs/mainnet/ink.toml#L59) address packed in slot 0
  - **Detail:** Packed storage slot containing initialization flag and SystemConfig address

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x784d2F03593A42A6E4676A012762F18775ecbBe6`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L15)
  - **Summary:** ERC-1967 implementation upgraded to ETHLockbox v1.2.0

- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0xd56045E68956FCe2576E680c95a4750cf8241f79`](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/superchain/configs/mainnet/ink.toml#L60) - Ink ProxyAdmin
  - **Summary:** ERC-1967 admin slot set to ProxyAdmin address

- **Key:**          `0xca399a74a2e45bc1100aefaa1dae30d0ae51000e349d60206e57bc5c12355f1e`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** authorizedPortals mapping - Ink OptimismPortal authorized
  - **Detail:** Mapping slot authorizing [Ink OptimismPortal](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/ink.toml#L58) address in ETHLockbox

  ---

### `0xbeb5fc579115071764c7423a4f12edde41f106ed` ([OptimismPortal2](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/superchain/configs/mainnet/op.toml#L58)) - Chain ID: 10

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** _initialized flag incremented from 1 to 2 (re-initialization completed)
  - **Detail:** Packed storage slot 0 contains the initialization flag, incremented during contract upgrade

- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000003e`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000000023b2c62946350f4246f9f9d027e071f0264fd113`
  - **Summary:** anchorStateRegistry address set to OP AnchorStateRegistry proxy
  - **Detail:** Storage slot 62 holds the AnchorStateRegistry proxy address for OP

- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000003f`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000322b47ff1fa8d5611f761e3e275c45b71b294d43`
  - **Summary:** ethLockbox address set to OP ETHLockbox proxy
  - **Detail:** Storage slot 63 holds the ETHLockbox proxy address for OP

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** [`0xB443Da3e07052204A02d630a8933dAc05a0d6fB4`](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/validation/standard/standard-versions-mainnet.toml#L73) - OptimismPortal v3.14.0
  - **After:** [`0xEFEd7F38BB9BE74bBa583a1A5B7D0fe7C9D5787a`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L12)
  - **Summary:** ERC-1967 implementation upgraded to OptimismPortal v4.6.0

  ---

### `0xc5f54f934075677fba99b5e43468439cbde88ca7` (DelayedWETH) - Chain ID: 10

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** _initialized flag set to 1 (initialization completed)
  - **Detail:** Storage slot 0 contains the initialization flag for the DelayedWETH contract



- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000004`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000229047fed2591dbec1ef1118d64f7af3db9eb290`
  - **Summary:** systemConfig set to the [SystemConfig proxy address](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/op.toml#L59)
  - **Detail:** Packed storage slot containing initialization flag and SystemConfig address

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x33Dadc2d1aA9BB613A7AE6B28425eA00D44c6998`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L14)
  - **Summary:** ERC-1967 implementation upgraded to DelayedWETH v1.5.0

- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x543bA4AADBAb8f9025686Bd03993043599c6fB04`](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/superchain/configs/mainnet/op.toml#L60) - OP ProxyAdmin
  - **Summary:** ERC-1967 admin slot set to ProxyAdmin address

  ---

### `0xd5d9eb5b1edce381c9f3377264e05c31f3036f32` (DelayedWETH) - Chain ID: 57073

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** _initialized flag set to 1 (initialization completed)
  - **Detail:** Storage slot 0 contains the initialization flag for the DelayedWETH contract



- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000004`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000000062c0a111929fa32cec2f76adba54c16afb6e8364`
  - **Summary:** systemConfig set to the [SystemConfig proxy address](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/ink.toml#L59)
  - **Detail:** Packed storage slot containing initialization flag and SystemConfig address

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x33Dadc2d1aA9BB613A7AE6B28425eA00D44c6998`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L14)
  - **Summary:** ERC-1967 implementation upgraded to DelayedWETH v1.5.0

- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0xd56045E68956FCe2576E680c95a4750cf8241f79`](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/superchain/configs/mainnet/ink.toml#L60) - Ink ProxyAdmin
  - **Summary:** ERC-1967 admin slot set to ProxyAdmin address

  ---

### `0xde1fcfb0851916ca5101820a69b13a4e276bd81f` ([AddressManager](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/superchain/configs/mainnet/op.toml#L53)) - Chain ID: 10

- **Key:**          `0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e`
  - **Before:** `0x0000000000000000000000005d5a095665886119693f0b41d8dfee78da033e8b`
  - **After:** `0x000000000000000000000000d26bb3aaaa4cb5638a8581a4c4b1d937d8e05c54`
  - **Summary:** AddressManager mapping "Proxy__OVM_L1CrossDomainMessenger" updated to L1CrossDomainMessenger v2.9.0
  - **Detail:** Packed storage slot containing initialization flag and SystemConfig address

  ---

### `0xe214879ad573693a4c49f7654449caa455cde34f` (DelayedWETH) - Chain ID: 10

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** _initialized flag set to 1 (initialization completed)
  - **Detail:** Storage slot 0 contains the initialization flag for the DelayedWETH contract



- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000004`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000229047fed2591dbec1ef1118d64f7af3db9eb290`
  - **Summary:** systemConfig set to the [SystemConfig proxy address](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/op.toml#L59)
  - **Detail:** Packed storage slot containing initialization flag and SystemConfig address

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x33Dadc2d1aA9BB613A7AE6B28425eA00D44c6998`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L14)
  - **Summary:** ERC-1967 implementation upgraded to DelayedWETH v1.5.0

- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x543bA4AADBAb8f9025686Bd03993043599c6fB04`](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/superchain/configs/mainnet/op.toml#L60) - OP ProxyAdmin
  - **Summary:** ERC-1967 admin slot set to ProxyAdmin address

  ---

### `0xe5965ab5962edc7477c8520243a95517cd252fa9` ([DisputeGameFactory](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/op.toml#L64)) - Chain ID: 10

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** [`0x4bbA758F006Ef09402eF31724203F316ab74e4a0`](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/validation/standard/standard-versions-mainnet.toml#L76) - DisputeGameFactory v1.0.1
  - **After:** [`0x33D1e8571a85a538ed3D5A4d88f46C112383439D`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L16)
  - **Summary:** ERC-1967 implementation upgraded to DisputeGameFactory v1.2.0

- **Key:**          `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`
  - **Before:** `0x000000000000000000000000a1e0bacde89d899b3f24eef3d179cc335a24e777`
  - **After:** `0x000000000000000000000000ecca4bfbd017002abf25aeebf2b21b903a5fc124`
  - **Summary:** gameImpls mapping - FaultDisputeGame implementation updated (slot calculated from mapping key)
  - **Detail:** Packed storage slot containing initialization flag and SystemConfig address

- **Key:**          `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b`
  - **Before:** `0x00000000000000000000000089d68b1d63aaa0db4af1163e81f56b76934292f8`
  - **After:** `0x000000000000000000000000d73dd0f5665055b03ea0bfcac49bd4d26f1ffa4f`
  - **Summary:** gameImpls mapping - PermissionedDisputeGame implementation updated (slot calculated from mapping key)
  - **Detail:** Packed storage slot containing initialization flag and SystemConfig address

  ---


### `0xee018baf058227872540ac60efbd38b023d9dae2` (AnchorStateRegistry) - Chain ID: 57073 (Newly Deployed)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000062c0a111929fa32cec2f76adba54c16afb6e83640001`
  - **Summary:** _initialized flag set to 1 and systemConfig address packed in slot 0
  - **Detail:** Packed storage slot containing initialization flag and [SystemConfig](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/ink.toml#L59) address

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000000010d7b35078d3baabb96dd45a9143b94be65b12cd`
  - **Summary:** disputeGameFactory set to Ink DisputeGameFactory proxy
  - **Detail:** Storage slot 1 holds the [DisputeGameFactory proxy address](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/ink.toml#L64) for Ink

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000003`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** See validation instructions below
  - **Summary:** startingAnchorRoot struct first half initialized for Ink
  - **Detail:** Storage slot 3 contains the first 32 bytes of the 64-byte startingAnchorRoot [Proposal struct](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v4.0.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L44-L47), which is a Hash.
    The actual value MAY differ based on the most recently finalized L2 output.

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000004`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** See validation instructions below
  - **Summary:** startingAnchorRoot struct second half initialized for Ink
  - **Detail:** Storage slot 4 contains the second 32 bytes of the 64-byte startingAnchorRoot [Proposal struct](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v4.0.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L44-L47), which is an L2 block number.
    
    **VALIDATION:** To verify the correct values for slots 3 and 4, run the following command using the same block number as your simulation.
      It should return two values, the first being the hash (slot 3) and the second being the block number (slot 4).

    ```
    cast call --block <simulation-block-number> 0x2fc99fd16D8D3F6F66d164aA84E244c567E58A3d 'anchors(uint32)(bytes32,bytes32)' 0
    ```

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000006`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** See validation instructions below
  - **Summary:** Packed slot with respectedGameType and retirementTimestamp initialized for Ink
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

- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0xd56045E68956FCe2576E680c95a4750cf8241f79`](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/superchain/configs/mainnet/ink.toml#L60) - Ink ProxyAdmin
  - **Summary:** ERC-1967 admin slot set to ProxyAdmin address

### Nonce increments

- `0x23B2C62946350F4246f9f9D027e071f0264FD113` - AnchorStateRegistry (Chain ID: 10)
- `0x322b47Ff1FA8D5611F761e3E275C45B71b294D43` - ETHLockbox (Chain ID: 10)
- `0x3F7b07A5D638024a37A776FA228fE90b317aF6dE` - DelayedWETH (Chain ID: 57073)
- `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` - ProxyAdminOwner (Chain ID: 10)
- `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` - FoundationOperationsSafe
- `0xbd4AbB321138e8Eddc399cE64E66451294325a14` - ETHLockbox (Chain ID: 57073)
- `0xc5f54F934075677FBA99b5E43468439cbdE88ca7` - DelayedWETH (Chain ID: 10)
- `0xD5d9Eb5B1edce381C9f3377264e05c31f3036F32` - DelayedWETH (Chain ID: 57073)
- `0xe214879aD573693A4C49f7654449Caa455cdE34f` - DelayedWETH (Chain ID: 10)
- `0xEe018bAf058227872540AC60eFbd38b023d9dAe2` - AnchorStateRegistry (Chain ID: 57073)
- `0x1a20c06a80260AA45adA0F9F59b334560eE3FEf1` - PermissionedDisputeGame (Chain ID: 10)
- `0x46DDe051eb4561694DC1F0286eBe940d9E90fbe9` - PermissionlessDisputeGame (Chain ID: 10)
- `0xEcca4BFbD017002abf25Aeebf2B21b903A5fC124` - PermissionedDisputeGame (Chain ID: 57073)
- `0xd73Dd0F5665055B03eA0bFcac49bd4d26F1FFA4F` - PermissionlessDisupteGame (Chain ID: 57073)
- `0xf13D09eD3cbdD1C930d4de74808de1f33B6b3D4f` - Sender address of the Tenderly transaction (Your ledger or first owner on the nested safe).
