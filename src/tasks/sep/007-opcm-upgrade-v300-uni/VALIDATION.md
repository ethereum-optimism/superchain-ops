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
> - Domain Hash: `0x2fedecce87979400ff00d5cec4c77da942d43ab3b9db4a5ffc51bb2ef498f30b`
> - Message Hash: `0x8e00a56a7c65b5adc299033bd4d7f5b81eeab33393e5eeef3c3c11363b94a908`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the OPCM upgrade to v3.0.0.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `opcm.upgrade()`

For each chain being upgraded, the `opcm.upgrade()` function is called with a tuple of three elements:

1. Unichain Sepolia Testnet:

- SystemConfigProxy: [0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D](https://github.com/ethereum-optimism/superchain-registry/blob/9dc8a7dfb8081291315d0c0ccf871f46c7753b63/superchain/configs/sepolia/unichain.toml#L60)
- ProxyAdmin: [0x2BF403E5353A7a082ef6bb3Ae2Be3B866D8D3ea4](https://github.com/ethereum-optimism/superchain-registry/blob/9dc8a7dfb8081291315d0c0ccf871f46c7753b63/superchain/configs/sepolia/unichain.toml#L61)
- AbsolutePrestate: [0x03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405](https://github.com/ethereum-optimism/superchain-registry/blob/1ab48707d705ef7100f3ffa549e048f699cb886d/validation/standard/standard-prestates.toml#L10)

Thus, the command to encode the calldata is:

```bash
cast calldata 'upgrade((address,address,bytes32)[])' "[(0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D,0x2BF403E5353A7a082ef6bb3Ae2Be3B866D8D3ea4,0x03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405)]"
```

### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the argument to the `Multicall3DelegateCall.aggregate3()` function.

This function is called with a tuple of three elements:

Call3 struct for Multicall3DelegateCall:

- `target`: [0xfbceed4de885645fbded164910e10f52febfab35](https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/validation/standard/standard-versions-sepolia.toml#L22) - Sepolia OPContractsManager v3.0.0
- `allowFailure`: false
- `callData`: `0xff2dd5a1...` (output from the previous section)

Command to encode:

```bash
cast calldata 'aggregate3((address,bool,bytes)[])' "[(0xfbceed4de885645fbded164910e10f52febfab35,false,0xff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000aee94b9ab7752d3f7704bde212c0c6a0b701571d0000000000000000000000002bf403e5353a7a082ef6bb3ae2be3b866d8d3ea403ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x82ad56cb000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000fbceed4de885645fbded164910e10f52febfab350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a4ff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000aee94b9ab7752d3f7704bde212c0c6a0b701571d0000000000000000000000002bf403e5353a7a082ef6bb3ae2be3b866d8d3ea403ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee40500000000000000000000000000000000000000000000000000000000
```

In mainnet runbooks, this calldata should appear in [Action Plan](https://gov.optimism.io/t/upgrade-proposal-14-isthmus-l1-contracts-mt-cannon/9796#p-43948-action-plan-9) section of the Governance proposal.

# State Changes

## Single Safe State Overrides and Changes

This task is executed by the single `ProxyAdminOwner` Safe. Refer to the [generic single Safe execution validation document](../../../../../SINGLE-VALIDATION.md)
for the expected state overrides and changes.

Additionally, Safe-related nonces [will increment by one](../../../../../SINGLE-VALIDATION.md#nonce-increments).

## Other Nonces

In addition to the Safe-related nonces mentioned [previously](#single-safe-state-overrides-and-changes), new contracts will also have a nonce value increment from 0 to 1.
This is due to [EIP-161](https://eips.ethereum.org/EIPS/eip-161) which activated in 2016.

This affects the newly deployed dispute games mentioned in ["State Diffs"](#state-diffs).

## State Diffs

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

  ---

### [`0x0d83dab629f0e0f9d36c0cbc89b69a489f0751bd`](https://github.com/ethereum-optimism/superchain-registry/blob/9dc8a7dfb8081291315d0c0ccf871f46c7753b63/superchain/configs/sepolia/unichain.toml#L59)  (OptimismPortal2) - Chain ID: 1301

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`

  - **Decoded Kind:**      `address`
  - **Before:** `0x2D7e764a0D9919e16983a46595CfA81fc34fa7Cd`
  - **After:** [`0xB443Da3e07052204A02d630a8933dAc05a0d6fB4`](https://github.com/ethereum-optimism/superchain-registry/blob/9dc8a7dfb8081291315d0c0ccf871f46c7753b63/validation/standard/standard-versions-sepolia.toml#L13)
  - **Summary:**           ERC-1967 implementation slot
  - **Detail:**            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
                           OptimismPortal2 contract for `op-contracts/v3.0.0-rc.2`.

  ---

### [`0x4696b5e042755103fe558738bcd1ecee7a45ebfe`](https://github.com/ethereum-optimism/superchain-registry/blob/9dc8a7dfb8081291315d0c0ccf871f46c7753b63/superchain/configs/sepolia/unichain.toml#L56)  (L1ERC721Bridge) - Chain ID: 1301

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`

  - **Decoded Kind:**      `address`
  - **Before:** `0x276d3730f219f7ec22274f7263180b8452B46d47`
  - **After:** [`0x7aE1d3BD877a4C5CA257404ce26BE93A02C98013`](https://github.com/ethereum-optimism/superchain-registry/blob/9dc8a7dfb8081291315d0c0ccf871f46c7753b63/validation/standard/standard-versions-sepolia.toml#L19)
  - **Summary:**           ERC-1967 implementation slot
  - **Detail:**            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
                           OptimismPortal2 contract for `op-contracts/v3.0.0-rc.2`.

  ---

### [`0xaee94b9ab7752d3f7704bde212c0c6a0b701571d`](https://github.com/ethereum-optimism/superchain-registry/blob/9dc8a7dfb8081291315d0c0ccf871f46c7753b63/superchain/configs/sepolia/unichain.toml#L60)  (SystemConfig) - Chain ID: 1301

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`

  - **Decoded Kind:**      `address`
  - **Before:** `0x760C48C62A85045A6B69f07F4a9f22868659CbCc`
  - **After:** [`0x340f923E5c7cbB2171146f64169EC9d5a9FfE647`](https://github.com/ethereum-optimism/superchain-registry/blob/9dc8a7dfb8081291315d0c0ccf871f46c7753b63/validation/standard/standard-versions-sepolia.toml#L9)
  - **Summary:**           ERC-1967 implementation slot
  - **Detail:**            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
                           SystemConfig contract for `op-contracts/v3.0.0-rc.2`.

  ---

### [`0xd363339ee47775888df411a163c586a8bdea9dbf`](https://github.com/ethereum-optimism/superchain-registry/blob/9dc8a7dfb8081291315d0c0ccf871f46c7753b63/superchain/configs/sepolia/unichain.toml#L46)  (ProxyAdminOwner (GnosisSafe)) - Chain ID: 1301

- **Account Nonce in State:**
  - **Before:** 4
  - **After:** 6
  - **Detail:** Two new dispute games were deployed by the ProxyAdminOwner during execution, resulting in the account nonce in state being incremented twice.

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`

  - **Decoded Kind:** `uint256`
  - **Before:** `29`
  - **After:** `30`
  - **Summary:** nonce
  - **Detail:**  The nonce of the ProxyAdminOwner contract is updated.

  ---

### [`0xea58fca6849d79ead1f26608855c2d6407d54ce2`](https://github.com/ethereum-optimism/superchain-registry/blob/9dc8a7dfb8081291315d0c0ccf871f46c7753b63/superchain/configs/sepolia/unichain.toml#L57)  (L1StandardBridge) - Chain ID: 1301

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:**      `address`
  - **Before:** `0x78972E88Ab8BBB517a36cAea23b931BAB58AD3c6`
  - **After:** [`0x0b09ba359A106C9ea3b181CBc5F394570c7d2a7A`](https://github.com/ethereum-optimism/superchain-registry/blob/9dc8a7dfb8081291315d0c0ccf871f46c7753b63/validation/standard/standard-versions-sepolia.toml#L20)
  - **Summary:**           ERC-1967 implementation slot
  - **Detail:**            Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard.
                           L1StandardBridge contract for `op-contracts/v3.0.0-rc.2`.

---

### [`0xef1295ed471dfec101691b946fb6b4654e88f98a`](https://github.com/ethereum-optimism/superchain-registry/blob/9dc8a7dfb8081291315d0c0ccf871f46c7753b63/superchain/configs/sepolia/unichain.toml#L54)  (AddressManager) - Chain ID: 1301

- **Key:**          `0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e`

  - **Before:**     `0x3ea6084748ed1b2a9b5d4426181f1ad8c93f6231`
  - **After:**     `0x5d5a095665886119693f0b41d8dfee78da033e8b`
  - **Summary:**  The name `OVM_L1CrossDomainMessenger` is set to the address of the new `op-contracts/v3.0.0-rc.2` L1CrossDomainMessenger implementation at [0x5d5a095665886119693f0b41d8dfee78da033e8b](https://github.com/ethereum-optimism/superchain-registry/blob/1a5d7a208cea9b0ea175df1fe71bdc4da7f4c04c/validation/standard/standard-versions-sepolia.toml#L18).
  - **Detail:** **THIS WAS CAREFULLY VERIFIED BY RUNBOOK REVIEWERS AND NEED NOT BE CHECKED BY SIGNERS.**
    This key is complicated to compute, so instead we attest to correctness of the key by
    verifying that the "Before" value currently exists in that slot, as explained below.
    **Before** address matches the following cast call to `AddressManager.getAddress()`:
    - `cast call 0xef1295ed471dfec101691b946fb6b4654e88f98a 'getAddress(string)(address)' 'OVM_L1CrossDomainMessenger' --rpc-url sepolia`
      And what is currently stored at the key:
    - `cast storage 0xef1295ed471dfec101691b946fb6b4654e88f98a 0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e --rpc-url mainnet`
    - returns: `0x3eA6084748ED1b2A9B5D4426181F1ad8C93F6231`

  ---

### [`0xeff73e5aa3b9aec32c659aa3e00444d20a84394b`](https://github.com/ethereum-optimism/superchain-registry/blob/9dc8a7dfb8081291315d0c0ccf871f46c7753b63/superchain/configs/sepolia/unichain.toml#L64)  (DisputeGameFactory) - Chain ID: 1301

- **Key:**          `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`
  - **Before:**     `0x2275d0c824116ad516987048fffabac6b0c3a29b`
  - **After:**     `0x8660219fa74a537e6f3665e30708962b968b7b77`
  - **Summary:**  Set a new game implementation for game type [PERMISSIONED_CANNON](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/lib/Types.sol#L52)
  - **Detail:** **THIS WAS CAREFULLY VERIFIED BY RUNBOOK REVIEWERS AND NEED NOT BE CHECKED BY SIGNERS.**
    You can verify this slot corresponds to the game implementation for game type 0 by deriving the slot value as follows:
    - Notice that [`gameImpls`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57) is a map from a `GameType` to a dispute game address.
    - Notice that `GameType` is [equivalent to a](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/lib/LibUDT.sol#L224-L224) `uint32`.
    - Notice that the `gameImpls` is [stored at slot 101](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41-L41).
    - Calculate the expected slot for game type 1 using `cast index <KEY_TYPE> <KEY> <SLOT_NUMBER>`:
      - `cast index uint32 1 101`
    - You should derive a value matching the "Raw Slot" here: `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`

- **Key:**          `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b`
  - **Before:**     `0x0000000000000000000000004745808cc649f290439763214fc40ac905806d8d`
  - **After:**     `0x000000000000000000000000c70a7e66c13caf0f770afb01fb701d148791d53d`
  - **Summary:**  Set a new game implementation for game type [CANNON](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/lib/Types.sol#L52)
  - **Detail:** **THIS WAS CAREFULLY VERIFIED BY RUNBOOK REVIEWERS AND NEED NOT BE CHECKED BY SIGNERS.**
    You can verify this slot corresponds to the game implementation for game type 0 by deriving the slot value as follows:
    - Notice that [`gameImpls`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57) is a map from a `GameType` to a dispute game address.
    - Notice that `GameType` is [equivalent to a](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/src/dispute/lib/LibUDT.sol#L224-L224) `uint32`.
    - Notice that the `gameImpls` is [stored at slot 101](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v2.0.0-rc.1/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41-L41).
    - Calculate the expected slot for game type 1 using `cast index <KEY_TYPE> <KEY> <SLOT_NUMBER>`:
      - `cast index uint32 0 101`
    - You should derive a value matching the "Raw Slot" here: `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b`
