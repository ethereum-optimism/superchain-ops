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
> - Domain Hash: ``
> - Message Hash: ``
>
> ### Security Council
>
> - Domain Hash: ``
> - Message Hash: ``

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


### Nonce increments

The only other state change are the nonce increments as follows:

- `<sender-address> e.g. 0xA03DaFadE71F1544f4b0120145eEC9b89105951f or 0x1084092Ac2f04c866806CF3d4a385Afa4F6A6C97` - Sender address of the Tenderly transaction (Your ledger or first owner on the nested safe).
- `0x38c2b9A214cDc3bBBc4915Dae8c2F0a7917952Dd` - Permissionless GameType Implementation as per [EIP-161](https://eip.tools/eip/eip-161.md)
- `0x3dbfB370be95Eb598C8b89B45d7c101dC1679AB9` - Permissioned GameType Implementation as per [EIP-161](https://eip.tools/eip/eip-161.md)
- `0x97766954BAF17e3a2BfA43728830f0Fa647F7546` - Permissioned GameType Implementation as per [EIP-161](https://eip.tools/eip/eip-161.md)
- `0xBd72dD2fB74a537B9B47B454614A15B066Cc464a` - Permissionless GameType Implementation as per [EIP-161](https://eip.tools/eip/eip-161.md)
