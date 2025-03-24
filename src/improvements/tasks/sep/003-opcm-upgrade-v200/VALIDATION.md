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
> ### Single Safe Signer Data
>
> - Domain Hash: ``
> - Message Hash: ``


## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the OPCM upgrade to v2.0.0.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `opcm.upgrade()`

For each chain being upgrade, the `opcm.upgrade()` function is called with a tuple of three elements:

1. Unichain Sepolia Testnet:
    - SystemConfigProxy: [0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D](https://github.com/ethereum-optimism/superchain-registry/blob/1ab48707d705ef7100f3ffa549e048f699cb886d/superchain/configs/sepolia/unichain.toml#L59)
    - ProxyAdmin: [0x2BF403E5353A7a082ef6bb3Ae2Be3B866D8D3ea4](https://github.com/ethereum-optimism/superchain-registry/blob/1ab48707d705ef7100f3ffa549e048f699cb886d/superchain/configs/sepolia/unichain.toml#L60)
    - AbsolutePrestate: [0x0354eee87a1775d96afee8977ef6d5d6bd3612b256170952a01bf1051610ee01](https://github.com/ethereum-optimism/superchain-registry/blob/1ab48707d705ef7100f3ffa549e048f699cb886d/validation/standard/standard-prestates.toml#L14)


Thus, the command to encode the calldata is:

```bash
cast calldata 'upgrade((address,address,bytes32)[])' "[(0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D, 0x2BF403E5353A7a082ef6bb3Ae2Be3B866D8D3ea4, 0x0354eee87a1775d96afee8977ef6d5d6bd3612b256170952a01bf1051610ee01)]"
```

### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the argument to the `Multicall3DelegateCall.aggregate3()` function.

This function is called with a tuple of three elements:


Call3 struct for Multicall3DelegateCall:
- `target`: [0x1B25F566336F47BC5E0036D66E142237DcF4640b](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/validation/standard/standard-versions-sepolia.toml#L21) - Sepolia OPContractsManager v2.0.0
- `allowFailure`: false
- `callData`: `0xff2dd5a1...` (output from the previous section)

Command to encode:
```bash
cast calldata 'aggregate3((address,bool,bytes)[])' "[(0x1B25F566336F47BC5E0036D66E142237DcF4640b,false,0xff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000aee94b9ab7752d3f7704bde212c0c6a0b701571d0000000000000000000000002bf403e5353a7a082ef6bb3ae2be3b866d8d3ea40354eee87a1775d96afee8977ef6d5d6bd3612b256170952a01bf1051610ee01)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x82ad56cb0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000001b25f566336f47bc5e0036d66e142237dcf4640b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a4ff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000aee94b9ab7752d3f7704bde212c0c6a0b701571d0000000000000000000000002bf403e5353a7a082ef6bb3ae2be3b866d8d3ea40354eee87a1775d96afee8977ef6d5d6bd3612b256170952a01bf1051610ee0100000000000000000000000000000000000000000000000000000000
```

In mainnet runbooks, this calldata should appear in [Action Plan](https://gov.optimism.io/t/upgrade-proposal-13-opcm-and-incident-response-improvements/9739#p-43725-action-plan-15) section of the Governance proposal.

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

### Task State Changes

<pre>
  <code>
  </code>
 </pre>

# Supplementary Material

## Figure 0.1: Storage Layout of OPContractsManager

![OPContractsManager isRC flag set to false](../000-opcm-upgrade-v200/images/op-contracts-manager-storage-layout.png)

## Figure 0.2: Storage Layout of AnchorStateRegistryProxy

![AnchorStateRegistryProxy](../000-opcm-upgrade-v200/images/anchor-state-registry-storage-layout.png)
