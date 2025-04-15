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
> - Message Hash: `0xff5166e1a86ea2e7a78192844ea6332b1357d136f1de36bd4230a70fc952d1c4`
>
> ### Nested Safe 2: `0x646132A1667ca7aD00d36616AFBA1A28116C770A`
>
> - Domain Hash: `0x1d3f2566fd7b1bf017258b03d4d4d435d326d9cb051d5b7993d7c65e7ec78d0e`
> - Message Hash: `0xff5166e1a86ea2e7a78192844ea6332b1357d136f1de36bd4230a70fc952d1c4`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the OPCM upgrade to v2.0.0.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `opcm.updatePrestate()`

For each chain being upgrade, the `opcm.updatePrestate()` function is called with a tuple of three elements:

1. Base Sepolia Testnet:
   - SystemConfigProxy: [0xf272670eb55e895584501d564AfEB048bEd26194](https://github.com/ethereum-optimism/superchain-registry/blob/2c60e5723c64b5a1b58ab72c5d3816927ff9391a/superchain/configs/sepolia/base.toml#L59)
   - ProxyAdmin: [0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3](https://github.com/ethereum-optimism/superchain-registry/blob/2c60e5723c64b5a1b58ab72c5d3816927ff9391a/superchain/configs/sepolia/base.toml#L60)
   - AbsolutePrestate: [0x03682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b6](https://github.com/ethereum-optimism/superchain-registry/blob/712a84f44501322ca61901c2729aa3a56726a602/validation/standard/standard-prestates.toml#L10)

Thus, the command to encode the calldata is:

```bash
cast calldata 'updatePrestate((address,address,bytes32)[])' "[(0xf272670eb55e895584501d564AfEB048bEd26194, 0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3, 0x03682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b6)]"
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
cast calldata 'aggregate3((address,bool,bytes)[])' "[(0xfBceeD4DE885645fBdED164910E10F52fEBFAB35,false,0x9a72745b00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000f272670eb55e895584501d564afeb048bed261940000000000000000000000000389e59aa0a41e4a413ae70f0008e76caa34b1f303682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b6)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x82ad56cb000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000fbceed4de885645fbded164910e10f52febfab350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a49a72745b00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000f272670eb55e895584501d564afeb048bed261940000000000000000000000000389e59aa0a41e4a413ae70f0008e76caa34b1f303682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b600000000000000000000000000000000000000000000000000000000
```

In mainnet runbooks, this calldata should appear in [Action Plan](https://gov.optimism.io/t/upgrade-proposal-15-isthmus-hard-fork/9804) section of the Governance proposal.

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

### [`0x0fe884546476ddd290ec46318785046ef68a0ba9`](https://github.com/ethereum-optimism/superchain-registry/blob/08e3fe429c776a532c2b6dc09571fc13e6dba5d4/superchain/configs/sepolia/base.toml#L45)  (ProxyAdminOwner (GnosisSafe)) - Chain ID: 84532

- **Nonce:**
  - **Before:** 6
  - **After:** 8
  - **Detail:** Two new dispute games were deployed by the ProxyAdminOwner during execution, resulting in the account nonce in state being incremented twice.

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:**      `uint256`
  - **Before:** `21`
  - **After:** `22`
  - **Summary:** Nonce update
  - **Detail:** Nonce update for the parent multisig. You can verify manually with the following:
    - Before: `cast --to-dec 0x15` = 21
    - After: `cast --to-dec 0x16` = 22

If signer is on Child Safe 1: `0x6AF0674791925f767060Dd52f7fB20984E8639d8`:

- **Key:**      `0x791fae0bcf3dd62c15434661e854630af982fdfefb63ed5ff80632964121d8ac`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:**  `approveHash(bytes32)` called on ProxyAdminOwner by child multisig.
  - **Detail:** **THIS WAS CAREFULLY VERIFIED BY RUNBOOK REVIEWERS AND NEED NOT BE CHECKED BY SIGNERS.** As part of the Tenderly simulation, we want to illustrate the <i>approveHash</i> invocation. This step isn't shown in the local simulation because the parent multisig is invoked directly, bypassing the <i>approveHash</i> calls. This slot change reflects an update to the approvedHashes mapping.
    To verify the slot yourself, run:
    - `res=$(cast index address 0x6AF0674791925f767060Dd52f7fB20984E8639d8 8)`
    - `cast index bytes32 0xf7f42d9617b2d58b07ebbba60ac231142f29f643c82bef5752250bcaa0ef9b34 $res`
    - Please note: the `0xf7f42d9617b2d58b07ebbba60ac231142f29f643c82bef5752250bcaa0ef9b34` value is taken from the Tenderly simulation and this is the transaction hash of the `approveHash` call.

OR if signer is on Child Safe 2: `0x646132A1667ca7aD00d36616AFBA1A28116C770A`:

- **Key:**      `0x8d756791beca7e82f4f71d8867bfa1c3217415c53f415e97b015e82ea7fd001c`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:**  `approveHash(bytes32)` called on ProxyAdminOwner by child multisig.
  - **Detail:** **THIS WAS CAREFULLY VERIFIED BY RUNBOOK REVIEWERS AND NEED NOT BE CHECKED BY SIGNERS.** As part of the Tenderly simulation, we want to illustrate the <i>approveHash</i> invocation. This step isn't shown in the local simulation because the parent multisig is invoked directly, bypassing the <i>approveHash</i> calls. This slot change reflects an update to the approvedHashes mapping.
    To verify the slot yourself, run:
    - `res=$(cast index address 0x646132A1667ca7aD00d36616AFBA1A28116C770A 8)`
    - `cast index bytes32 0xf7f42d9617b2d58b07ebbba60ac231142f29f643c82bef5752250bcaa0ef9b34 $res`
    - Please note: the `0xf7f42d9617b2d58b07ebbba60ac231142f29f643c82bef5752250bcaa0ef9b34` value is taken from the Tenderly simulation and this is the transaction hash of the `approveHash` call.

  ---

### `0x6AF0674791925f767060Dd52f7fB20984E8639d8` (GnosisSafe) - Child Safe 1

**Note: You'll only see this state diff if signer is on Child Safe 1: `0x6AF0674791925f767060Dd52f7fB20984E8639d8`. Ignore if you're signing for Child Safe 2: `0x646132A1667ca7aD00d36616AFBA1A28116C770A`.**

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `3`
  - **After:** `4`
  - **Summary:**  Nonce update
  - **Detail:**  Nonce update for the child safe. You can verify manually with the following:
    - Before: `cast --to-dec 0x3` = 3
    - After: `cast --to-dec 0x4` = 4

---

### `0x646132A1667ca7aD00d36616AFBA1A28116C770A` (GnosisSafe) - Child Safe 2

**Note: You'll only see this state diff if signer is on Child Safe 2: `0x646132A1667ca7aD00d36616AFBA1A28116C770A`. Ignore if you're signing for Child Safe 1: `0x6AF0674791925f767060Dd52f7fB20984E8639d8`.**

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `3`
  - **After:** `4`
  - **Summary:**  Nonce update
  - **Detail:**  Nonce update for the child safe. You can verify manually with the following:
    - Before: `cast --to-dec 0x3` = 3
    - After: `cast --to-dec 0x4` = 4

---

### [`0xd6e6dbf4f7ea0ac412fd8b65ed297e64bb7a06e1`](https://github.com/ethereum-optimism/superchain-registry/blob/08e3fe429c776a532c2b6dc09571fc13e6dba5d4/superchain/configs/sepolia/base.toml#L63)  (DisputeGameFactory) - Chain ID: 84532

- **Key:**          `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`
  - **Before:**     `0x0000000000000000000000006f67e57c143321e266bac32a0d9d22d88ce1b3e5`
  - **After:**     `0x00000000000000000000000057893745965a135800ef124a16718cfe1380379f`
  - **Summary:** Updates the implementation for game type 1.
  - **Detail:** This is `gameImpls[1]` -> `0x57893745965a135800ef124a16718cfe1380379f`. The [`gameImpls` mapping](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57) is at [storage slot 101](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41) and is keyed by [`GameType` (`uint32`)](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/lib/LibUDT.sol#L224).
    - Confirm the expected key slot with the following:
      ```shell
      cast index uint32 1 101
      0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e
      ```

- **Key:**          `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b`
  - **Before:**     `0x000000000000000000000000340c1364d299ed55b193d4efcecbad8c3fb104c4`
  - **After:**     `0x00000000000000000000000000ce6dba88c8f3a95671fec55609c04f83ff6c09`
  - **Detail:** This is `gameImpls[0]` -> `0x00ce6dba88c8f3a95671fec55609c04f83ff6c09`. The [`gameImpls` mapping](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57) is at [storage slot 101](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41) and is keyed by [`GameType` (`uint32`)](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/lib/LibUDT.sol#L224).
    - Confirm the expected key slot with the following:
      ```shell
      cast index uint32 0 101
      0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b
      ```

### Nonce increments

The only other state change are three nonce increments:

- `0x00ce6dba88c8f3a95671fec55609c04f83ff6c09` - Permissionless GameType Implementation as per [EIP-161](https://eip.tools/eip/eip-161.md)
- `0x57893745965a135800ef124a16718cfe1380379f` - Permissioned GameType Implementation as per [EIP-161](https://eip.tools/eip/eip-161.md)
- `<sender-address> e.g. 0x7f10098BD53519c739cA8A404afE127647D94774` - Sender address of the Tenderly transaction (Your ledger or first owner on the nested safe).
