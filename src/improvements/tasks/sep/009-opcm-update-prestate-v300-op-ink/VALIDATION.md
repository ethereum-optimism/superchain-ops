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
> ### Optimism Foundation
>
> - Domain Hash: `0x37e1f5dd3b92a004a23589b741196c8a214629d4ea3a690ec8e41ae45c689cbb`
> - Message Hash: `0xfb07e7203c346d15eef032fd4f2a701bb8b6d238ddf1bc039e6948679bfbe244`
>
> ### Security Council
>
> - Domain Hash: `0xbe081970e9fc104bd1ea27e375cd21ec7bb1eec56bfe43347c3e36c5d27b8533`
> - Message Hash: `0x6b925fb3038474120f3e0ea58b70c686ce8911846205441dd0d0466d4bab2479`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the OPCM updatePrestate() function.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `opcm.updatePrestate()`

For each chain being updated, the `opcm.updatePrestate()` function is called with a tuple of two elements:

1. OP Sepolia Testnet:
  - SystemConfigProxy: [0x034edD2A225f7f429A63E0f1D2084B9E0A93b538](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/sepolia/op.toml#L58)
  - ProxyAdmin: [0x189aBAAaa82DfC015A588A7dbaD6F13b1D3485Bc](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/sepolia/op.toml#L59)
  - AbsolutePrestate: [0x03682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b6](https://www.notion.so/oplabs/Isthmus-Sepolia-Mainnet-1d2f153ee162800880abe1b47910c071)

2. Ink Sepolia:
  - SystemConfigProxy: [0x05C993e60179f28bF649a2Bb5b00b5F4283bD525](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/sepolia/ink.toml#L58)
  - ProxyAdmin: [0xd7dB319a49362b2328cf417a934300cCcB442C8d](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/sepolia/ink.toml#L59)
  - AbsolutePrestate: [0x03682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b6](https://www.notion.so/oplabs/Isthmus-Sepolia-Mainnet-1d2f153ee162800880abe1b47910c071)


Thus, the command to encode the calldata is:

```bash
cast calldata "updatePrestate((address,address,bytes32)[])" "[(0x034edD2A225f7f429A63E0f1D2084B9E0A93b538,0x189aBAAaa82DfC015A588A7dbaD6F13b1D3485Bc,0x03682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b6),(0x05C993e60179f28bF649a2Bb5b00b5F4283bD525,0xd7dB319a49362b2328cf417a934300cCcB442C8d,0x03682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b6)]"
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
cast calldata 'aggregate3((address,bool,bytes)[])' "[(0xfbceed4de885645fbded164910e10f52febfab35,false,0x9a72745b00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000034edd2a225f7f429a63e0f1d2084b9e0a93b538000000000000000000000000189abaaaa82dfc015a588a7dbad6f13b1d3485bc03682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b600000000000000000000000005c993e60179f28bf649a2bb5b00b5f4283bd525000000000000000000000000d7db319a49362b2328cf417a934300cccb442c8d03682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b6)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x82ad56cb000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000fbceed4de885645fbded164910e10f52febfab350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000001049a72745b00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000034edd2a225f7f429a63e0f1d2084b9e0a93b538000000000000000000000000189abaaaa82dfc015a588a7dbad6f13b1d3485bc03682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b600000000000000000000000005c993e60179f28bf649a2bb5b00b5f4283bd525000000000000000000000000d7db319a49362b2328cf417a934300cccb442c8d03682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b600000000000000000000000000000000000000000000000000000000
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

### [`0x05f9613adb30026ffd634f38e5c4dfd30a197fa1`](https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/superchain/configs/sepolia/op.toml#L63) (DisputeGameFactory) - Chain ID: 11155420

- **Key:**          `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`
  - **Before:**     `0x000000000000000000000000845e5382d60ec16e538051e1876a985c5339cc62`
  - **After:**     `0x0000000000000000000000003dbfb370be95eb598c8b89b45d7c101dc1679ab9`
  - **Summary:** Updates the implementation for game type 1.
  - **Detail:** This is `gameImpls[1]` -> `0x3dbfB370be95Eb598C8b89B45d7c101dC1679AB9`. The [`gameImpls` mapping](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57) is at [storage slot 101](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41) and is keyed by [`GameType` (`uint32`)](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/lib/LibUDT.sol#L224).
    - Confirm the expected key slot with the following:
      ```shell
      cast index uint32 1 101
      0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e
      ```

- **Key:**          `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b`
  - **Before:**     `0x000000000000000000000000d46b939123d5fb1b48ee3f90caebc9d5498ed542`
  - **After:**     `0x00000000000000000000000038c2b9a214cdc3bbbc4915dae8c2f0a7917952dd`
  - **Summary:** Updates the implementation for game type 0.
  - **Detail:** This is `gameImpls[0]` -> `0x38c2b9A214cDc3bBBc4915Dae8c2F0a7917952Dd`. The [`gameImpls` mapping](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57) is at [storage slot 101](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41) and is keyed by [`GameType` (`uint32`)](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/lib/LibUDT.sol#L224).
    - Confirm the expected key slot with the following:
      ```shell
      cast index uint32 0 101
      0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b
      ```

  ---

### [`0x1eb2ffc903729a0f03966b917003800b145f56e2`](https://github.com/ethereum-optimism/superchain-registry/blob/b40cf4289c58e28eb1c791f9ad5724380b7516a7/validation/standard/standard-config-roles-sepolia.toml#L3) (ProxyAdminOwner (GnosisSafe)) - Chain ID: 11155420

- **Nonce:**
  - **Before:** 23
  - **After:** 27
  - **Detail:** Four new dispute games were deployed by the ProxyAdminOwner during execution, resulting in the account nonce in state being incremented four times.

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:**      `uint256`
  - **Before:** `27`
  - **After:** `28`
  - **Summary:** Nonce update
  - **Detail:** Nonce update for the parent multisig. You can verify manually with the following:
    - Before: `cast --to-dec 0x1b` = 27
    - After: `cast --to-dec 0x1c` = 28

If signer is on foundation safe: `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`:

- **Key:**      `0xa42acf5c45ea89094223f328e17a2fb63bef00bc1b66347dc6ade24904c602de`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:**  `approveHash(bytes32)` called on ProxyAdminOwner by child multisig.
  - **Detail:** **THIS WAS CAREFULLY VERIFIED BY RUNBOOK REVIEWERS AND NEED NOT BE CHECKED BY SIGNERS.** As part of the Tenderly simulation, we want to illustrate the <i>approveHash</i> invocation. This step isn't shown in the local simulation because the parent multisig is invoked directly, bypassing the <i>approveHash</i> calls. This slot change reflects an update to the approvedHashes mapping.
    Specifically, this simulation was ran as the nested safe ``. To verify the slot yourself, run:
    - `res=$(cast index address 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B 8)`
    - `cast index bytes32 0x201bd81426da57b8320f972d39a152930df92aeeecceb0bae5afb51b9343a686 $res`
    - Please note: the `0x201bd81426da57b8320f972d39a152930df92aeeecceb0bae5afb51b9343a686` value is taken from the Tenderly simulation and this is the transaction hash of the `approveHash` call.

OR if signer is on council safe: `0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`:

- **Key:**      `0x197170017eeaa81ee156c4184f574f634cd8da0162a1875749a41202771f948b`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:**  `approveHash(bytes32)` called on ProxyAdminOwner by child multisig.
  - **Detail:** **THIS WAS CAREFULLY VERIFIED BY RUNBOOK REVIEWERS AND NEED NOT BE CHECKED BY SIGNERS.** As part of the Tenderly simulation, we want to illustrate the <i>approveHash</i> invocation. This step isn't shown in the local simulation because the parent multisig is invoked directly, bypassing the <i>approveHash</i> calls. This slot change reflects an update to the approvedHashes mapping.
    Specifically, this simulation was ran as the nested safe ``. To verify the slot yourself, run:
    - `res=$(cast index address 0xf64bc17485f0B4Ea5F06A96514182FC4cB561977 8)`
    - `cast index bytes32 0x201bd81426da57b8320f972d39a152930df92aeeecceb0bae5afb51b9343a686 $res`
    - Please note: the `0x201bd81426da57b8320f972d39a152930df92aeeecceb0bae5afb51b9343a686` value is taken from the Tenderly simulation and this is the transaction hash of the `approveHash` call.

  ---

### [`0x860e626c700af381133d9f4af31412a2d1db3d5d`](https://github.com/ethereum-optimism/superchain-registry/blob/08e3fe429c776a532c2b6dc09571fc13e6dba5d4/superchain/configs/sepolia/ink.toml#L64) (DisputeGameFactory) - Chain ID: 763373

- **Key:**          `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`
  - **Before:**     `0x000000000000000000000000de2b69153c42191eb4863a36024d80a1d426d0c8`
  - **After:**     `0x00000000000000000000000097766954baf17e3a2bfa43728830f0fa647f7546`
  - **Summary:** Updates the implementation for game type 1.
  - **Detail:** This is `gameImpls[1]` -> `0x97766954BAF17e3a2BfA43728830f0Fa647F7546`. The [`gameImpls` mapping](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57) is at [storage slot 101](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41) and is keyed by [`GameType` (`uint32`)](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/lib/LibUDT.sol#L224).
    - Confirm the expected key slot with the following:
      ```shell
      cast index uint32 1 101
      0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e
      ```

- **Key:**          `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b`
  - **Before:**     `0x0000000000000000000000000c356f533eb009deb302bc96522e80dea6a16276`
  - **After:**     `0x000000000000000000000000bd72dd2fb74a537b9b47b454614a15b066cc464a`
  - **Summary:** Updates the implementation for game type 0.
  - **Detail:** This is `gameImpls[0]` -> `0xBd72dD2fB74a537B9B47B454614A15B066Cc464a`. The [`gameImpls` mapping](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57) is at [storage slot 101](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41) and is keyed by [`GameType` (`uint32`)](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/lib/LibUDT.sol#L224).
    - Confirm the expected key slot with the following:
      ```shell
      cast index uint32 0 101
      0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b
      ```

  ---

### [`0xc26977310bC89DAee5823C2e2a73195E85382cC7`](https://github.com/ethereum-optimism/superchain-ops/blob/35fee17422ed6fe9dae225362c6704a0baca6fda/tasks/sep/013-fp-granite-prestate/NestedSignFromJson.s.sol#L27) (LivenessGuard)
**THIS STATE DIFF ONLY APPEARS WHEN SIGNING FOR THE COUNCIL AND DOES NOT NEED TO BE CHECKED BY SIGNERS.**

- **Key:**         `0xee4378be6a15d4c71cb07a5a47d8ddc4aba235142e05cb828bb7141206657e27`
  - **Before:**    `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:**     `0x0000000000000000000000000000000000000000000000000000000067f958df`
  - **Summary:**   LivenessGuard timestamp update.
  - **Detail:**    - **Detail:** **THIS STATE DIFF ONLY APPEARS WHEN SIGNING FOR THE COUNCIL AND DOES NOT NEED TO BE CHECKED BY SIGNERS.**
                   When the security council safe executes a transaction, the liveness timestamps are updated.
                   This is updating at the moment when the  transaction is submitted (`block.timestamp`) into the [`lastLive`](https://github.com/ethereum-optimism/optimism/blob/e84868c27776fd04dc77e95176d55c8f6b1cc9a3/packages/contracts-bedrock/src/safe/LivenessGuard.sol#L41) mapping located at the slot 0.

  ---

### `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B` (GnosisSafe) - Sepolia Foundation Safe

**Note: You'll only see this state diff if signer is on foundation safe: `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`. Ignore if you're signing for the council safe: `0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`.**

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `41`
  - **After:** `42`
  - **Summary:**  Nonce update
  - **Detail:**  Nonce update for the child safe `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`. You can verify manually with the following:
    - Before: `cast --to-dec 0x29` = 41
    - After: `cast --to-dec 0x2a` = 42

  ---

### `0xf64bc17485f0B4Ea5F06A96514182FC4cB561977` (GnosisSafe) - Sepolia Council Safe

**Note: You'll only see this state diff if signer is on council safe: `0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`. Ignore if you're signing for the foundation safe: `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`.**

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `36`
  - **After:** `37`
  - **Summary:**  Nonce update
  - **Detail:**  Nonce update for the child safe `0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`. You can verify manually with the following:
    - Before: `cast --to-dec 0x24` = 36
    - After: `cast --to-dec 0x25` = 37

  ---

### Nonce increments

The only other state change are the nonce increments as follows:

- `<sender-address> e.g. 0xA03DaFadE71F1544f4b0120145eEC9b89105951f or 0x1084092Ac2f04c866806CF3d4a385Afa4F6A6C97` - Sender address of the Tenderly transaction (Your ledger or first owner on the nested safe).
- `0x38c2b9A214cDc3bBBc4915Dae8c2F0a7917952Dd` - Permissionless GameType Implementation as per [EIP-161](https://eip.tools/eip/eip-161.md)
- `0x3dbfB370be95Eb598C8b89B45d7c101dC1679AB9` - Permissioned GameType Implementation as per [EIP-161](https://eip.tools/eip/eip-161.md)
- `0x97766954BAF17e3a2BfA43728830f0Fa647F7546` - Permissioned GameType Implementation as per [EIP-161](https://eip.tools/eip/eip-161.md)
- `0xBd72dD2fB74a537B9B47B454614A15B066Cc464a` - Permissionless GameType Implementation as per [EIP-161](https://eip.tools/eip/eip-161.md)
