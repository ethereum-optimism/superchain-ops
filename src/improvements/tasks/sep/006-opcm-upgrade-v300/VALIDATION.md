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
> ### Nested Safe 1: `0x6AF0674791925f767060Dd52f7fB20984E8639d8`
>
> - Domain Hash: `0x6f25427e79742a1eb82c103e2bf43c85fc59509274ec258ad6ed841c4a0048aa`
> - Message Hash: `0xbe0ac96269061e1431408a7eae3b3a4fef23875b1bcb2150d1c267055ec67887`
>
> ### Nested Safe 2: `0x646132A1667ca7aD00d36616AFBA1A28116C770A`
>
> - Domain Hash: `0x1d3f2566fd7b1bf017258b03d4d4d435d326d9cb051d5b7993d7c65e7ec78d0e`
> - Message Hash: `0xbe0ac96269061e1431408a7eae3b3a4fef23875b1bcb2150d1c267055ec67887`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the OPCM upgrade to v2.0.0.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `opcm.upgrade()`

For each chain being upgrade, the `opcm.upgrade()` function is called with a tuple of three elements:

1. Base Sepolia Testnet:
   - SystemConfigProxy: [0xf272670eb55e895584501d564AfEB048bEd26194](https://github.com/ethereum-optimism/superchain-registry/blob/2c60e5723c64b5a1b58ab72c5d3816927ff9391a/superchain/configs/sepolia/base.toml#L59)
   - ProxyAdmin: [0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3](https://github.com/ethereum-optimism/superchain-registry/blob/2c60e5723c64b5a1b58ab72c5d3816927ff9391a/superchain/configs/sepolia/base.toml#L60)
   - AbsolutePrestate: [0x03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405](https://github.com/ethereum-optimism/superchain-registry/blob/fb900358ab5016de86f37a23265bd94ce927c9c0/validation/standard/standard-prestates.toml#L18)

Thus, the command to encode the calldata is:

```bash
cast calldata 'upgrade((address,address,bytes32)[])' "[(0xf272670eb55e895584501d564AfEB048bEd26194, 0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3, 0x03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405)]"
```

### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the argument to the `Multicall3DelegateCall.aggregate3()` function.

This function is called with a tuple of three elements:

Call3 struct for Multicall3DelegateCall:

- `target`: [0xfBceeD4DE885645fBdED164910E10F52fEBFAB35](https://github.com/ethereum-optimism/superchain-registry/blob/main/validation/standard/standard-versions-sepolia.toml#L22) - Sepolia OPContractsManager v3.0.0
- `allowFailure`: false
- `callData`: `0xff2dd5a1...` (output from the previous section)

Command to encode:

```bash
cast calldata 'aggregate3((address,bool,bytes)[])' "[(0xfBceeD4DE885645fBdED164910E10F52fEBFAB35,false,0xff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000f272670eb55e895584501d564afeb048bed261940000000000000000000000000389e59aa0a41e4a413ae70f0008e76caa34b1f303ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x82ad56cb000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000fbceed4de885645fbded164910e10f52febfab350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a4ff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000f272670eb55e895584501d564afeb048bed261940000000000000000000000000389e59aa0a41e4a413ae70f0008e76caa34b1f303ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee40500000000000000000000000000000000000000000000000000000000
```

In mainnet runbooks, this calldata should appear in [Action Plan](https://gov.optimism.io/t/upgrade-proposal-14-isthmus-l1-contracts-mt-cannon/9796#p-43948-action-plan-9) section of the Governance proposal.

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

### State Overrides

Note: The changes listed below do not include threshold, nonce and owner mapping overrides. These changes are listed and explained in the [NESTED-VALIDATION.md](../../../../../NESTED-VALIDATION.md) file.

### Task State Changes

---

### [`0x0fe884546476ddd290ec46318785046ef68a0ba9`](https://github.com/ethereum-optimism/superchain-registry/blob/fb900358ab5016de86f37a23265bd94ce927c9c0/superchain/configs/sepolia/base.toml#L46) (ProxyAdminOwner (GnosisSafe)) - Chain ID: 84532

- **Nonce:**
  - **Before:** 4
  - **After:** 6
  - **Detail:** Two new dispute games were deployed by the ProxyAdminOwner during execution, resulting in the account nonce in state being incremented twice.

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:**      `uint256`
  - **Before:** `20`
  - **After:** `21`
  - **Summary:** Nonce update
  - **Detail:** Nonce update for the parent multisig. You can verify manually with the following:
    - Before: `cast --to-dec 0x14` = 20
    - After: `cast --to-dec 0x15` = 21

If signer is on safe: `0x6AF0674791925f767060Dd52f7fB20984E8639d8`:

- **Key:**          `0xe106d26ac9e4f09d68a63c012aa21a9c70e11e1a73a3af0e56b6ac82e85107b7`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:**  `approveHash(bytes32)` called on ProxyAdminOwner by child multisig.
  - **Detail:** **THIS WAS CAREFULLY VERIFIED BY RUNBOOK REVIEWERS AND NEED NOT BE CHECKED BY SIGNERS.** As part of the Tenderly simulation, we want to illustrate the <i>approveHash</i> invocation. This step isn't shown in the local simulation because the parent multisig is invoked directly, bypassing the <i>approveHash</i> calls. This slot change reflects an update to the approvedHashes mapping.
    Specifically, this simulation was ran as the nested safe `0x6AF0674791925f767060Dd52f7fB20984E8639d8`. To verify the slot yourself, run:
    - `res=$(cast index address 0x6AF0674791925f767060Dd52f7fB20984E8639d8 8)`
    - `cast index bytes32 0x08731a4fb5cd8d45ad7b7fb473337694e0ee9f6fa5a25c3f43da991c387e0ecd $res`
    - Please note: the `0x08731a4fb5cd8d45ad7b7fb473337694e0ee9f6fa5a25c3f43da991c387e0ecd` value is taken from the Tenderly simulation and this is the transaction hash of the `approveHash` call.

OR if signer is on safe: `0x646132A1667ca7aD00d36616AFBA1A28116C770A`:

- **Key:**          `0x22054c07d38b900c25edfae39905682bba022fb95e948df1f9da3b426b385e40`

  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:**  `approveHash(bytes32)` called on ProxyAdminOwner by child multisig.
  - **Detail:** **THIS WAS CAREFULLY VERIFIED BY RUNBOOK REVIEWERS AND NEED NOT BE CHECKED BY SIGNERS.** As part of the Tenderly simulation, we want to illustrate the <i>approveHash</i> invocation. This step isn't shown in the local simulation because the parent multisig is invoked directly, bypassing the <i>approveHash</i> calls. This slot change reflects an update to the approvedHashes mapping.
    Specifically, this simulation was ran as the nested safe `0x646132A1667ca7aD00d36616AFBA1A28116C770A`. To verify the slot yourself, run:
    - `res=$(cast index address 0x646132A1667ca7aD00d36616AFBA1A28116C770A 8)`
    - `cast index bytes32 0x08731a4fb5cd8d45ad7b7fb473337694e0ee9f6fa5a25c3f43da991c387e0ecd $res`
    - Please note: the `0x08731a4fb5cd8d45ad7b7fb473337694e0ee9f6fa5a25c3f43da991c387e0ecd` value is taken from the Tenderly simulation and this is the transaction hash of the `approveHash` call.

  ---

### [`0x21efd066e581fa55ef105170cc04d74386a09190`](https://github.com/ethereum-optimism/superchain-registry/blob/fb900358ab5016de86f37a23265bd94ce927c9c0/superchain/configs/sepolia/base.toml#L56) (L1ERC721Bridge) - Chain ID: 84532

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`

  - **Decoded Kind:**     `address`
  - **Before:** `0x276d3730f219f7ec22274f7263180b8452B46d47`
  - **After:** [`0x7aE1d3BD877a4C5CA257404ce26BE93A02C98013`](https://github.com/ethereum-optimism/superchain-registry/blob/fb900358ab5016de86f37a23265bd94ce927c9c0/validation/standard/standard-versions-sepolia.toml#L19)
  - **Summary:**         ERC-1967 implementation slot
  - **Detail:**          Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard. L1ERC721Bridge contract for `op-contracts/v3.0.0-rc.2`.

  ---

### [`0x49f53e41452c74589e85ca1677426ba426459e85`](https://github.com/ethereum-optimism/superchain-registry/blob/fb900358ab5016de86f37a23265bd94ce927c9c0/superchain/configs/sepolia/base.toml#L59) (OptimismPortal2) - Chain ID: 84532

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:**      `address`
  - **Before:** `0x2D7e764a0D9919e16983a46595CfA81fc34fa7Cd`
  - **After:** [`0xB443Da3e07052204A02d630a8933dAc05a0d6fB4`](https://github.com/ethereum-optimism/superchain-registry/blob/fb900358ab5016de86f37a23265bd94ce927c9c0/validation/standard/standard-versions-sepolia.toml#L13)
  - **Summary:**           ERC-1967 implementation slot
  - **Detail:**          Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard. OptimismPortal2 contract for `op-contracts/v3.0.0-rc.2`.

  ---

### `0x6AF0674791925f767060Dd52f7fB20984E8639d8` (GnosisSafe)

**Note: You'll only see this state diff if signer is on safe: `0x6AF0674791925f767060Dd52f7fB20984E8639d8`. Ignore if you're signing for safe: `0x646132A1667ca7aD00d36616AFBA1A28116C770A`.**

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `2`
  - **After:** `3`
  - **Summary:**  Nonce update
  - **Detail:**  Nonce update for the child safe `0x6AF0674791925f767060Dd52f7fB20984E8639d8`.

--- 

### `0x646132A1667ca7aD00d36616AFBA1A28116C770A` (GnosisSafe)

**Note: You'll only see this state diff if signer is on safe: `0x646132A1667ca7aD00d36616AFBA1A28116C770A`. Ignore if you're signing for safe: `0x6AF0674791925f767060Dd52f7fB20984E8639d8`.**

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`

  - **Before:** `2`
  - **After:** `3`
  - **Summary:**  Nonce update
  - **Detail:**  Nonce update for the child safe `0x646132A1667ca7aD00d36616AFBA1A28116C770A`.

  ---

### [`0x709c2b8ef4a9fefc629a8a2c1af424dc5bd6ad1b`](https://github.com/ethereum-optimism/superchain-registry/blob/fb900358ab5016de86f37a23265bd94ce927c9c0/superchain/configs/sepolia/base.toml#L54) (AddressManager) - Chain ID: 84532

- **Key:**          `0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e`
  - **Before:**     `0x0000000000000000000000003ea6084748ed1b2a9b5d4426181f1ad8c93f6231`
  - **After:**     `0x0000000000000000000000005d5a095665886119693f0b41d8dfee78da033e8b`
  - **Summary:**   The name `OVM_L1CrossDomainMessenger` is set to the address of the new 'op-contracts/v3.0.0-rc.2' L1CrossDomainMessenger at [0x5d5a095665886119693f0b41d8dfee78da033e8b](https://github.com/ethereum-optimism/superchain-registry/blob/fb900358ab5016de86f37a23265bd94ce927c9c0/validation/standard/standard-versions-sepolia.toml#L18).
  - **Detail:** **THIS WAS CAREFULLY VERIFIED BY RUNBOOK REVIEWERS AND NEED NOT BE CHECKED BY SIGNERS.**
    This key is complicated to compute, so instead we attest to correctness of the key by
    verifying that the "Before" value currently exists in that slot, as explained below.
    **Before** address matches the following cast call to `AddressManager.getAddress()`:
      - `cast call 0x709c2B8ef4A9feFc629A8a2C1AF424Dc5BD6ad1B 'getAddress(string)(address)' 'OVM_L1CrossDomainMessenger' --rpc-url sepolia`
      - returns: `0x3eA6084748ED1b2A9B5D4426181F1ad8C93F6231`

  ---

### [`0xd6e6dbf4f7ea0ac412fd8b65ed297e64bb7a06e1`](https://github.com/ethereum-optimism/superchain-registry/blob/fb900358ab5016de86f37a23265bd94ce927c9c0/superchain/configs/sepolia/base.toml#L64) (DisputeGameFactory) - Chain ID: 84532

- **Key:**          `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`

  - **Before:**     `0x000000000000000000000000d53394d4f67653074acf0b264954fe5e4f72d24f`
  - **After:**     `0x0000000000000000000000006f67e57c143321e266bac32a0d9d22d88ce1b3e5`
  - **Summary:**     Updates the implementation for game type 1.
  - **Detail:**    This is `gameImpls[1]` -> `0x6f67e57c143321e266bac32a0d9d22d88ce1b3e5`. The [`gameImpls` mapping](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57) is at [storage slot 101](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41) and is keyed by [`GameType` (`uint32`)](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/lib/LibUDT.sol#L224).
    - Confirm the expected key slot with the following:
      ```shell
      cast index uint32 1 101
      0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e
      ```
- **Key:**          `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b`

  - **Before:**     `0x000000000000000000000000861eb6dfe0fde8c8a63e8606fa487ee870f65e72`
  - **After:**     `0x000000000000000000000000340c1364d299ed55b193d4efcecbad8c3fb104c4`
  - **Summary:**  Updates the implementation for game type 0.
  - **Detail:**  This is `gameImpls[0]` -> `0x340c1364d299ed55b193d4efcecbad8c3fb104c4`. The [`gameImpls` mapping](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57) is at [storage slot 101](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41) and is keyed by [`GameType` (`uint32`)](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/lib/LibUDT.sol#L224).
    - Confirm the expected key slot with the following:
      ```shell
      cast index uint32 0 101
      0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b
      ```

  ---

### [`0xf272670eb55e895584501d564afeb048bed26194`](https://github.com/ethereum-optimism/superchain-registry/blob/fb900358ab5016de86f37a23265bd94ce927c9c0/superchain/configs/sepolia/base.toml#L60) (SystemConfig) - Chain ID: 84532

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`

  - **Decoded Kind:**      `address`
  - **Before:** `0x760C48C62A85045A6B69f07F4a9f22868659CbCc`
  - **After:** [`0x340f923E5c7cbB2171146f64169EC9d5a9FfE647`](https://github.com/ethereum-optimism/superchain-registry/blob/fb900358ab5016de86f37a23265bd94ce927c9c0/validation/standard/standard-versions-sepolia.toml#L9)
  - **Summary:**           ERC-1967 implementation slot
  - **Detail:**          Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard. SystemConfig contract for `op-contracts/v3.0.0-rc.2`.

  ---

### [`0xfd0bf71f60660e2f608ed56e1659c450eb113120`](https://github.com/ethereum-optimism/superchain-registry/blob/fb900358ab5016de86f37a23265bd94ce927c9c0/superchain/configs/sepolia/base.toml#L57) (L1StandardBridge) - Chain ID: 84532

- **Key:**          `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  - **Decoded Kind:**      `address`
  - **Before:** `0x78972E88Ab8BBB517a36cAea23b931BAB58AD3c6`
  - **After:** [`0x0b09ba359A106C9ea3b181CBc5F394570c7d2a7A`](https://github.com/ethereum-optimism/superchain-registry/blob/fb900358ab5016de86f37a23265bd94ce927c9c0/validation/standard/standard-versions-sepolia.toml#L20)
  - **Summary:**           ERC-1967 implementation slot
  - **Detail:**          Standard slot for storing the implementation address in a proxy contract that follows the ERC-1967 standard. L1StandardBridge contract for `op-contracts/v3.0.0-rc.2`.

### Nonce increments

The only other state change are three nonce increments:

- `0x340c1364D299ED55B193d4eFcecBAD8c3Fb104c4` - Permissionless GameType Implementation as per [EIP-161](https://eip.tools/eip/eip-161.md)
- `0x6F67E57C143321e266bac32A0D9D22d88cE1b3e5` - Permissioned GameType Implementation as per [EIP-161](https://eip.tools/eip/eip-161.md)
- `<sender-address> e.g. 0x7f10098BD53519c739cA8A404afE127647D94774` - Sender address of the Tenderly transaction (Your ledger or first owner on the nested safe).
