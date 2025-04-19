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
> - Message Hash: `0xae2f771c19884236a99b653504109a869d048a9782ff69d28788ac73dae52a2f`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the OPCM updatePrestate() function.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `opcm.updatePrestate()`

For each chain being updated, the `opcm.updatePrestate()` function is called with a single tuple:

1. Unichain Sepolia Testnet:
- SystemConfigProxy: [0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D](https://github.com/ethereum-optimism/superchain-registry/blob/9dc8a7dfb8081291315d0c0ccf871f46c7753b63/superchain/configs/sepolia/unichain.toml#L60)
- ProxyAdmin: [0x2BF403E5353A7a082ef6bb3Ae2Be3B866D8D3ea4](https://github.com/ethereum-optimism/superchain-registry/blob/9dc8a7dfb8081291315d0c0ccf871f46c7753b63/superchain/configs/sepolia/unichain.toml#L61)
- AbsolutePrestate: [0x03682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b6](https://www.notion.so/oplabs/Isthmus-Sepolia-Mainnet-1d2f153ee162800880abe1b47910c071)


Thus, the command to encode the calldata is:

```bash
cast calldata "updatePrestate((address,address,bytes32)[])" "[(0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D,0x2BF403E5353A7a082ef6bb3Ae2Be3B866D8D3ea4,0x03682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b6)]"
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
cast calldata 'aggregate3((address,bool,bytes)[])' "[(0xfbceed4de885645fbded164910e10f52febfab35,false,0x9a72745b00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000aee94b9ab7752d3f7704bde212c0c6a0b701571d0000000000000000000000002bf403e5353a7a082ef6bb3ae2be3b866d8d3ea403682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b6)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x82ad56cb000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000fbceed4de885645fbded164910e10f52febfab350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a49a72745b00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000aee94b9ab7752d3f7704bde212c0c6a0b701571d0000000000000000000000002bf403e5353a7a082ef6bb3ae2be3b866d8d3ea403682932cec7ce0a3874b19675a6bbc923054a7b321efc7d3835187b172494b600000000000000000000000000000000000000000000000000000000
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

Note: The changes listed below do not include threshold, nonce and owner mapping overrides. These changes are listed and explained in the [SINGLE-VALIDATION.md](../../../../../SINGLE-VALIDATION.md) file.

### Task State Changes

  ---
  
### [`0xd363339ee47775888df411a163c586a8bdea9dbf`](https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/superchain/configs/sepolia/unichain.toml#L45) (ProxyAdminOwner (GnosisSafe)) - Chain ID: 1301

- **Nonce:**
  - **Before:** 6
  - **After:** 8
  - **Detail:** Two new dispute games were deployed by the ProxyAdminOwner during execution, resulting in the account nonce in state being incremented two times.
  
- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:**      `uint256`
  - **Before:** `31`
  - **After:** `32`
  - **Summary:** Nonce update
  - **Detail:** Nonce update for the parent multisig. You can verify manually with the following:
    - Before: `cast --to-dec 0x1f` = 31
    - After: `cast --to-dec 0x20` = 32

  ---
  
### [`0xeff73e5aa3b9aec32c659aa3e00444d20a84394b`](https://github.com/ethereum-optimism/superchain-registry/blob/00208555c3c356d6596feedb619da989de478ed7/superchain/configs/sepolia/unichain.toml#L63) (DisputeGameFactory) - Chain ID: 1301
  
- **Key:**          `0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e`
  - **Before:**     `0x0000000000000000000000008660219fa74a537e6f3665e30708962b968b7b77` 
  - **After:**     `0x0000000000000000000000005acc5b2da22463eb8a54851dc0ac80a193f4039a` 
  - **Summary:** Updates the implementation for game type 1.
  - **Detail:** This is `gameImpls[1]` -> `0x5acC5B2DA22463EB8a54851dC0Ac80A193F4039a`. The [`gameImpls` mapping](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57) is at [storage slot 101](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41) and is keyed by [`GameType` (`uint32`)](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/lib/LibUDT.sol#L224).
    - Confirm the expected key slot with the following:
      ```shell
      cast index uint32 1 101
      0x4d5a9bd2e41301728d41c8e705190becb4e74abe869f75bdb405b63716a35f9e
      ```      
  
- **Key:**          `0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b`
  - **Before:**     `0x000000000000000000000000c70a7e66c13caf0f770afb01fb701d148791d53d`
  - **After:**     `0x000000000000000000000000a84cf3aab33a5ac812f46a46601b0e39a03e07f1`
  - **Summary:** Updates the implementation for game type 0.
  - **Detail:** This is `gameImpls[0]` -> `0xA84cF3aAB33A5Ac812F46A46601b0E39A03E07F1`. The [`gameImpls` mapping](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/DisputeGameFactory.sol#L57) is at [storage slot 101](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/snapshots/storageLayout/DisputeGameFactory.json#L41) and is keyed by [`GameType` (`uint32`)](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v3.0.0-rc.2/packages/contracts-bedrock/src/dispute/lib/LibUDT.sol#L224).
    - Confirm the expected key slot with the following:
      ```shell
      cast index uint32 0 101
      0xffdfc1249c027f9191656349feb0761381bb32c9f557e01f419fd08754bf5a1b
      ```

### Nonce increments

The only other state change are the nonce increments as follows:

- `<sender-address> e.g. 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38` - Sender address of the Tenderly transaction (Your ledger address).
- `0x5acC5B2DA22463EB8a54851dC0Ac80A193F4039a` - Permissioned GameType Implementation as per [EIP-161](https://eip.tools/eip/eip-161.md)
- `0xA84cF3aAB33A5Ac812F46A46601b0E39A03E07F1` - Permissionless GameType Implementation as per [EIP-161](https://eip.tools/eip/eip-161.md)
