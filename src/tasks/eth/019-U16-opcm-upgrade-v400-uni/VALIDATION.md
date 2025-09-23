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
> ### ChainGovernorSafe - `0xb0c4C487C5cf6d67807Bc2008c66fa7e2cE744EC`
>
> - Domain Hash: `0x4f0b6efb6c01fa7e127a0ff87beefbeb53e056d30d3216c5ac70371b909ca66d`
> - Message Hash: `0xefa479616f22394c003a3d519d2d17265b9d72814c6cc363d980aeb4975765c1`
>
> ### FoundationUpgradeSafe - `0x847B5c174615B1B7fDF770882256e2D3E95b9D92`
>
> - Domain Hash: `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0xf8d89eb1c1001a101376f1ed71979a3e69fd264a4ad450a7daf1324f9d6e3bf6`
>
> ### Security Council - `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`
>
> - Domain Hash: `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0x3cd4e1e20ed9799317d3d89134e07f3ba10b518aa7a4a1b2468e6bdfc99c20a9`


## Normalized State Diff Hash Attestation

The normalized state diff hash **MUST** match the hash produced by the state changes attested to in the state diff audit report. As a signer, you are responsible for verifying that this hash is correct. Please compare the hash below with the one in the audit report. If no audit report is available for this task, you must still ensure that the normalized state diff hash matches the output in your terminal.

**Normalized hash:** `0x3ad69a6ca7730bffecb93714c05dcaa1d32154665e2b183d79531e19abd4bd36`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the OPCM upgrade to v4.0.0.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `opcm.upgrade()`

For each chain being upgrade, the `opcm.upgrade()` function is called with a tuple of three elements:

1. Unichain:
    - SystemConfigProxy: [0xc407398d063f942febbcc6f80a156b47f3f1bda6](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/mainnet/unichain.toml#L58)
    - ProxyAdmin: [0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/mainnet/unichain.toml#L59)
    - AbsolutePrestate: [0x03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8](https://www.notion.so/oplabs/U16-Update-Cannon-for-go1-23-1f4f153ee1628012beb5f016a3bfef0a)

Thus, the command to encode the calldata is:

```bash
cast calldata 'upgrade((address,address,bytes32)[])' "[(0xc407398d063f942febbcc6f80a156b47f3f1bda6,0x3b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a4,0x03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8)]"
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
cast calldata 'aggregate3((address,bool,bytes)[])' "[(0x56ebc5c4870f5367b836081610592241ad3e0734,false,0xff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000c407398d063f942febbcc6f80a156b47f3f1bda60000000000000000000000003b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a403eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x82ad56cb00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000056ebc5c4870f5367b836081610592241ad3e07340000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a4ff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000c407398d063f942febbcc6f80a156b47f3f1bda60000000000000000000000003b73fa8d82f511a3cae17b5a26e4e1a2d5e2f2a403eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc800000000000000000000000000000000000000000000000000000000
```

In mainnet runbooks, this calldata should appear in [Action Plan](https://gov.optimism.io/t/upgrade-16-proposal-interop-contracts-stage-1-and-go-1-23-support-in-cannon/10037) section of the Governance proposal.

## Task Transfers

### Decoded Transfer 0
  - **From:**              `0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2`
  - **To:**                `0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5`
  - **Value:**             `193879089546923487734073`
  - **Token Address:**     `0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE`

## Task State Changes

### `0x08ba0023ed60c7bd040716dd13c45fa0062df5c5` (ETHLockboxProxy) - Chain ID: 130

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000c407398d063f942febbcc6f80a156b47f3f1bda60001`
  - **Summary:** Packed slot with systemConfig ([`0xc407398d063f942febbcc6f80a156b47f3f1bda6`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/unichain.toml#L59)) and _initialized=1

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x784d2F03593A42A6E4676A012762F18775ecbBe6`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L15)
  - **Summary:** ERC-1967 implementation upgraded to ETHLockbox v1.2.0

- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/unichain.toml#L60)
  - **Summary:** Proxy owner set to ProxyAdmin for Unichain

- **Key:**          `0xf451b09ed076ace1a495b612661a3fe9904e13e88b2967fba804b5553eea6895`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** authorizedPortals mapping - OptimismPortal for Unichain authorized (slot calculated from mapping key)

  ---

### `0x0bd48f6b86a26d3a217d0fa6ffe2b491b956a7a2` ([OptimismPortalProxy](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/unichain.toml#L58)) - Chain ID: 130

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** _initialized flag incremented from 1 to 2 (re-initialization completed)

- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000003e`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000000027cf508e4e3aa8d30b3226ac3b5ea0e8bcacaff9`
  - **Summary:** anchorStateRegistry set to AnchorStateRegistryProxy for Unichain

- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000003f`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000000008ba0023ed60c7bd040716dd13c45fa0062df5c5`
  - **Summary:** ethLockbox set to ETHLockboxProxy for Unichain

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0xB443Da3e07052204A02d630a8933dAc05a0d6fB4`
  - **After:** [`0xEFEd7F38BB9BE74bBa583a1A5B7D0fe7C9D5787a`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L12)
  - **Summary:** ERC-1967 implementation upgraded to OptimismPortal v4.6.0

  ---

### `0x27cf508e4e3aa8d30b3226ac3b5ea0e8bcacaff9` ([AnchorStateRegistryProxy](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/unichain.toml#L62)) - Chain ID: 130 (Newly Deployed)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000c407398d063f942febbcc6f80a156b47f3f1bda60001`
  - **Summary:** _initialized flag set to 1 and systemConfig address packed in slot 0
  - **Detail:** Packed storage slot containing initialization flag and [SystemConfig](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/unichain.toml#L58) address

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000002f12d621a16e2d3285929c9996f478508951dfe4`
  - **Summary:** disputeGameFactory set to Unichain DisputeGameFactory proxy
  - **Detail:** Storage slot 1 holds the [DisputeGameFactory proxy address](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/unichain.toml#L64) for Unichain

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000003`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** See validation instructions below the next slot
  - **Summary:** startingAnchorRoot struct first half initialized for Unichain
  - **Detail:** Storage slot 3 contains the first 32 bytes of the 64-byte startingAnchorRoot [Proposal struct](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v4.0.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L44-L47), which is a Hash.
    The actual value MAY differ based on the most recently finalized L2 output.

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000004`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** See validation instructions below
  - **Summary:** startingAnchorRoot struct second half initialized for Unichain
  - **Detail:** Storage slot 4 contains the second 32 bytes of the 64-byte startingAnchorRoot [Proposal struct](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v4.0.0/packages/contracts-bedrock/src/dispute/lib/Types.sol#L44-L47), which is an L2 block number.

    **VALIDATION:** To verify the correct values for slots 3 and 4, run the following command using the same block number as your simulation.
      It should return two values, the first being the hash (slot 3) and the second being the block number (slot 4).

    ```
    cast call --block <simulation-block-number> 0xD5D0e176be44E61eaB3Cf1FA8153758dF603376f 'anchors(uint32)(bytes32,bytes32)' 0
    ```

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000006`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** See validation instructions below
  - **Summary:** Packed slot with respectedGameType and retirementTimestamp initialized for Unichain
  - **Detail:** The non-zero values should correspond to a recent timestamp values, as [set](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v4.0.0/packages/contracts-bedrock/src/dispute/AnchorStateRegistry.sol#L106) in the AnchorStateRegistry's initialize function.

    **VALIDATION:** The value in slots 6 will differ from simulation to simulation based on chain state. The following cast command should return a value
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
  - **After:** [`0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4`](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/superchain/configs/mainnet/unichain.toml#L60) - ProxyAdmin
  - **Summary:** Proxy owner set to ProxyAdmin for Unichain


  ---

### `0x2f12d621a16e2d3285929c9996f478508951dfe4` ([DisputeGameFactoryProxy](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/unichain.toml#L64)) - Chain ID: 130

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x4bbA758F006Ef09402eF31724203F316ab74e4a0`
  - **After:** [`0x33D1e8571a85a538ed3D5A4d88f46C112383439D`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L16)
  - **Summary:** ERC-1967 implementation upgraded to DisputeGameFactory v1.2.0

- **Key:**          `0x4d5a9bd2e4130728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`
  - **Before:** `0x000000000000000000000000485272c0703020e1354328a1aba3ca767997bed3`
  - **After:** `0x000000000000000000000000c56ef9c3f3e9fd6713055b4577ac4af8303e63e1`
  - **Summary:** gameImpls mapping updated - new game implementation for game type 0 (PermissionedDisputeGame)

- **Key:**          `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b`
  - **Before:** `0x00000000000000000000000057a3b42698dc1e4fb905c9ab970154e178296991`
  - **After:** `0x0000000000000000000000004f0f6b7877a174a4fd41df80db80def8883bc772`
  - **Summary:** gameImpls mapping updated - new game implementation for game type 1 (PermissionlessDisputeGame)

  ---

### `0x6d5b183f538abb8572f5cd17109c617b994d5833` (ProxyAdminOwner (GnosisSafe)) - Chain ID: 130

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `5`
  - **After:** `6`
  - **Summary:** GnosisSafe nonce incremented from 5 to 6 after transaction execution

  ---

### `0x8098f676033a377b9defe302e9fe6877cd63d575` (AddressManager) - Chain ID: 130

- **Key:**          `0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e`
  - **Before:** [`0x0000000000000000000000005d5a095665886119693f0b41d8dfee78da033e8b`](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/validation/standard/standard-versions-mainnet.toml#L78) - L1CrossDomainMessenger 2.6.0
  - **After:** `0x000000000000000000000000d26bb3aaaa4cb5638a8581a4c4b1d937d8e05c54`
  - **Summary:** AddressManager mapping "Proxy__OVM_L1CrossDomainMessenger" updated to L1CrossDomainMessenger v2.9.0 ([`0xd26bb3aaaa4cb5638a8581a4c4b1d937d8e05c54`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L18))

  ---

### `0x81014f44b0a345033bb2b3b21c7a1a308b35feea` (L1StandardBridgeProxy) - Chain ID: 130

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** _initialized flag incremented from 1 to 2 (re-initialization completed)



- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000034`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000c407398d063f942febbcc6f80a156b47f3f1bda6`
  - **Summary:** systemConfig set to SystemConfigProxy ([`0xc407398d063f942febbcc6f80a156b47f3f1bda6`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/unichain.toml#L59)) for Unichain



- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** [`0x0b09ba359A106C9ea3b181CBc5F394570c7d2a7A`](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/validation/standard/standard-versions-mainnet.toml#L80) - L1StandardBridge 2.3.0
  - **After:** [`0x44AfB7722AF276A601D524F429016A18B6923df0`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L20)
  - **Summary:** ERC-1967 implementation upgraded to L1StandardBridge v2.6.0


  ---

### `0x9a3d64e386c18cb1d6d5179a9596a4b5736e98a6` (L1CrossDomainMessengerProxy) - Chain ID: 130

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000010000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000020000000000000000000000000000000000000000`
  - **Summary:** _initialized flag incremented from 1 to 2 (re-initialization completed)



- **Key:**          `0x00000000000000000000000000000000000000000000000000000000000000fe`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000c407398d063f942febbcc6f80a156b47f3f1bda6`
  - **Summary:** systemConfig set to SystemConfigProxy ([`0xc407398d063f942febbcc6f80a156b47f3f1bda6`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/unichain.toml#L59)) for Unichain



  ---

### `0xa0157f0730dea8d1a5c358dc1d340a05d8796c23` (DelayedWETHProxy) - Chain ID: 130

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** _initialized flag set to 1 (initialization completed)



- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000004`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000c407398d063f942febbcc6f80a156b47f3f1bda6`
  - **Summary:** systemConfig set to SystemConfigProxy ([`0xc407398d063f942febbcc6f80a156b47f3f1bda6`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/unichain.toml#L59)) for Unichain



- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x33Dadc2d1aA9BB613A7AE6B28425eA00D44c6998`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L14)
  - **Summary:** ERC-1967 implementation upgraded to DelayedWETH v1.5.0


- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4`](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/superchain/configs/mainnet/unichain.toml#L60) - ProxyAdmin
  - **Summary:** Proxy owner set to ProxyAdmin for Unichain


  ---

### `0xbcea39a1f75d7ac8004982efba85f92a693386cb` (DelayedWETHProxy) - Chain ID: 130

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** _initialized flag set to 1 (initialization completed)



- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000004`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000c407398d063f942febbcc6f80a156b47f3f1bda6`
  - **Summary:** systemConfig set to SystemConfigProxy ([`0xc407398d063f942febbcc6f80a156b47f3f1bda6`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/unichain.toml#L59)) for Unichain



- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x33Dadc2d1aA9BB613A7AE6B28425eA00D44c6998`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L14)
  - **Summary:** ERC-1967 implementation upgraded to DelayedWETH v1.5.0


- **Key:**          `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
  - **Decoded Kind:** `address`
  - **Before:** `0x0000000000000000000000000000000000000000`
  - **After:** [`0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4`](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/superchain/configs/mainnet/unichain.toml#L60) - ProxyAdmin
  - **Summary:** Proxy owner set to ProxyAdmin for Unichain


  ---

### `0xc407398d063f942febbcc6f80a156b47f3f1bda6` ([SystemConfigProxy](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/unichain.toml#L59)) - Chain ID: 130

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** _initialized flag incremented from 1 to 2 (re-initialization completed)

- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000006b`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000082`
  - **Summary:** l2ChainId set to 130 (0x82) for Unichain



- **Key:**          `0x000000000000000000000000000000000000000000000000000000000000006c`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x00000000000000000000000095703e0982140d16f8eba6d158fccede42f04a4c`
  - **Summary:** superchainConfig set to SuperchainConfig ([`0x95703e0982140d16f8eba6d158fccede42f04a4c`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/unichain.toml#L61)) for Unichain



- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** [`0x340f923E5c7cbB2171146f64169EC9d5a9FfE647`](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/validation/standard/standard-versions-mainnet.toml#L69) - SystemConfigProxy 2.5.0
  - **After:** [`0xFaA660bf783CBAa55e1B7F3475C20Db74a53b9Fa`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L8) - SystemConfigProxy 3.4.0
  - **Summary:** ERC-1967 implementation upgraded to SystemConfig v3.4.0



- **Key:**          `0x52322a25d9f59ea17656545543306b7aef62bc0cc53a0e65ccfa0c75b97aa906`
  - **Decoded Kind:** `address`
  - **Before:** [`0x2F12d621a16e2d3285929C9996f478508951dFe4`](https://github.com/ethereum-optimism/superchain-registry/blob/6621a0f13ce523fe1bb8deea739fe37abe20f90d/superchain/configs/mainnet/unichain.toml#L64) - DisputeGameFactoryProxy
  - **After:** `0x0000000000000000000000000000000000000000`
  - **Summary:** DisputeGameFactory proxy address cleared (legacy field removed in v3.4.0)


  ---

### `0xd04d0d87e0bd4d2e50286760a3ef323fea6849cf` (L1ERC721BridgeProxy) - Chain ID: 130

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000002`
  - **Summary:** _initialized flag incremented from 1 to 2 (re-initialization completed)

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000c407398d063f942febbcc6f80a156b47f3f1bda6`
  - **Summary:** systemConfig set to SystemConfigProxy ([`0xc407398d063f942febbcc6f80a156b47f3f1bda6`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/unichain.toml#L59)) for Unichain



- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:** `address`
  - **Before:** `0x7aE1d3BD877a4C5CA257404ce26BE93A02C98013`
  - **After:** [`0x25d6CeDEB277Ad7ebEe71226eD7877768E0B7A2F`](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-mainnet.toml#L19)
  - **Summary:** ERC-1967 implementation upgraded to L1ERC721Bridge v2.7.0


### Nonce increments

- `0x08bA0023eD60C7Bd040716dD13C45fA0062df5C5` - Newly deployed ETHLockbox
- `0x27Cf508E4E3Aa8d30b3226aC3b5Ea0e8bcaCAFF9` - Newly deployed AnchorStateRegistryProxy
- `0x6d5B183F538ABB8572F5cD17109c617b994D5833` - ProxyAdminOwner
- `0xa0157F0730Dea8d1a5c358Dc1d340a05D8796C23` - Newly deployed DelayedWETHProxy
- `0xb0c4C487C5cf6d67807Bc2008c66fa7e2cE744EC` - ChainGovernorSafe (Signer on the L1PAO)
- `0xBcEA39a1F75D7AC8004982efBA85F92A693386CB` - Newly deployed DelayedWETHProxy
- `0x4F0f6B7877A174A4fd41DF80dB80DeF8883bc772` - Newly deployed PermissionedDisputeGame
- `0xC56EF9c3F3e9fD6713055b4577AC4AF8303E63e1` - Newly deployed PermissionlessDisputeGame
- `0xf13D09eD3cbdD1C930d4de74808de1f33B6b3D4f` - Sender address of the Tenderly transaction (Your ledger or first owner on the nested safe).
