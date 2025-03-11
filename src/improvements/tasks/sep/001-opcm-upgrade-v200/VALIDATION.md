# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff
are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## Understanding Task Calldata

Multicall3DelegateCall calldata:
```bash
0x82ad56cb0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000001b25f566336f47bc5e0036d66e142237dcf4640b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a4ff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000f272670eb55e895584501d564afeb048bed261940000000000000000000000000389e59aa0a41e4a413ae70f0008e76caa34b1f3039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d900000000000000000000000000000000000000000000000000000000
```

### Decode Multicall3DelegateCall calldata:
```bash
cast calldata-decode 'aggregate3((address,bool,bytes)[])' <0x82ad56cb...>

[
    (
        0x1B25F566336F47BC5E0036D66E142237DcF4640b,
        false, 
        0xff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000f272670eb55e895584501d564afeb048bed261940000000000000000000000000389e59aa0a41e4a413ae70f0008e76caa34b1f3039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9
    )
]
```

1. First tuple (Call3 struct for Multicall3DelegateCall)
    - `target`: [0x1B25F566336F47BC5E0036D66E142237DcF4640b](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/validation/standard/standard-versions-sepolia.toml#L21) - Sepolia OPContractsManager v2.0.0
    - `allowFailure`: false
    - `callData`: `0xff2dd5a1...` See below for decoding.
        - Command to encode: `cast calldata 'aggregate3((address,bool,bytes)[])' "[(0x1B25F566336F47BC5E0036D66E142237DcF4640b,false,0xff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000f272670eb55e895584501d564afeb048bed261940000000000000000000000000389e59aa0a41e4a413ae70f0008e76caa34b1f3039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9)]"`

### Decode upgrade calldata

```bash
cast calldata-decode 'upgrade((address,address,bytes32)[])' <0xff2dd5a1...>

[
    (
        0xf272670eb55e895584501d564AfEB048bEd26194,
        0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3,
        0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9
    )
]
```
1. First tuple (Base Sepolia Testnet):
    - SystemConfigProxy: [0xf272670eb55e895584501d564AfEB048bEd26194](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/base.toml#L58)
    - ProxyAdmin: [0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/base.toml#L59)
    - AbsolutePrestate: [0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9](https://github.com/ethereum-optimism/optimism/blob/63da401391e9be93517d242da5da24905aa5b84c/op-program/prestates/releases.json#L9)
    - Command to encode: `cast calldata 'upgrade((address,address,bytes32)[])' "[(0xf272670eb55e895584501d564AfEB048bEd26194, 0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3, 0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9)]"`

## Tenderly State Changes
[Link](https://dashboard.tenderly.co/oplabs/sepolia/simulator/6b2420de-81c6-412a-bf55-ff3ccc6a1681)

## Auto Generated Task State Changes

```bash
```