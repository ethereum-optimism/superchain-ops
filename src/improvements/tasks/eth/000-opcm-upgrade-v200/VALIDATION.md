# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are
signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Verifying the transaction input](#understanding-task-calldata)
3. [Verifying the state changes](#verifying-the-state-changes)

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Security Council
>
> - Domain Hash: `0xdaf670b31fdf41fdaae2643ed0ebe709283539c0e61540c160b5a6403d79073f`
> - Message Hash: `0x15b70e777a7aeac57a0d8a1fc0474253a8988bc0933fcc5962e943ae6e1609df`
>
> ### Optimism Foundation
>
> - Domain Hash: `0xdaf670b31fdf41fdaae2643ed0ebe709283539c0e61540c160b5a6403d79073f`
> - Message Hash: `0x15b70e777a7aeac57a0d8a1fc0474253a8988bc0933fcc5962e943ae6e1609df`
>

## Understanding Task Calldata

The calldata sent from the `ProxyAdminOwner` Safe can be re-derived from data in the `config.toml` file using `cast`.
The accuracy of the data in the config.toml file can be verified by referring to the values in the
[`superchain-registry`](https://github.com/ethereum-optimism/superchain-registry).


1. First tuple (OP Mainnet):
    - SystemConfigProxy: [0x229047fed2591dbec1eF1118d64F7aF3dB9EB290](https://github.com/ethereum-optimism/superchain-registry/blob/b40cf4289c58/superchain/configs/mainnet/op.toml#L58)
    - ProxyAdmin: [0x543bA4AADBAb8f9025686Bd03993043599c6fB04](https://github.com/ethereum-optimism/superchain-registry/blob/b40cf4289c58/superchain/configs/mainnet/op.toml#L59)
    - AbsolutePrestate: [0x03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405](https://github.com/ethereum-optimism/superchain-registry/blob/b40cf4289c58/validation/standard/standard-prestates.toml#L10)

2. Second tuple (Soneium):
    - SystemConfigProxy: [0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3](https://github.com/ethereum-optimism/superchain-registry/blob/b40cf4289c58/superchain/configs/mainnet/soneium.toml#L58)
    - ProxyAdmin: [0x89889B569c3a505f3640ee1Bd0ac1D557f436D2a](https://github.com/ethereum-optimism/superchain-registry/blob/b40cf4289c58/superchain/configs/mainnet/soneium.toml#L59)
    - AbsolutePrestate: [0x03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405](https://github.com/ethereum-optimism/superchain-registry/blob/b40cf4289c58/validation/standard/standard-prestates.toml#L10)

3. Third tuple (Ink):
    - SystemConfigProxy: [0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364](https://github.com/ethereum-optimism/superchain-registry/blob/b40cf4289c58/superchain/configs/mainnet/ink.toml#L58)
    - ProxyAdmin: [0xd56045E68956FCe2576E680c95a4750cf8241f79](https://github.com/ethereum-optimism/superchain-registry/blob/b40cf4289c58/superchain/configs/mainnet/ink.toml#L59)
    - AbsolutePrestate: [0x03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405](https://github.com/ethereum-optimism/superchain-registry/blob/b40cf4289c58/validation/standard/standard-prestates.toml#L10)


### Rederiving the

The calldata sent from the `ProxyAdminOwner` Safe.

```bash
$ cast calldata "upgrade((address,address,bytes32)[])" "[(0x229047fed2591dbec1eF1118d64F7aF3dB9EB290,0x543bA4AADBAb8f9025686Bd03993043599c6fB04,0x03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405),(0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3,0x89889B569c3a505f3640ee1Bd0ac1D557f436D2a,0x03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405),(0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364,0xd56045E68956FCe2576E680c95a4750cf8241f79,0x03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405)]"

0xff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000003000000000000000000000000229047fed2591dbec1ef1118d64f7af3db9eb290000000000000000000000000543ba4aadbab8f9025686bd03993043599c6fb0403ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee4050000000000000000000000007a8ed66b319911a0f3e7288bddab30d9c0c875c300000000000000000000000089889b569c3a505f3640ee1bd0ac1d557f436d2a03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee40500000000000000000000000062c0a111929fa32cec2f76adba54c16afb6e8364000000000000000000000000d56045e68956fce2576e680c95a4750cf8241f7903ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405
```

Then by passing that calldata into the call to `Multicall3DelegateCall`:

```bash
$ cast calldata "aggregate3((address,bool,bytes)[])" "[(0x026b2F158255Beac46c1E7c6b8BbF29A4b6A7B76,false,0xff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000003000000000000000000000000229047fed2591dbec1ef1118d64f7af3db9eb290000000000000000000000000543ba4aadbab8f9025686bd03993043599c6fb0403ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee4050000000000000000000000007a8ed66b319911a0f3e7288bddab30d9c0c875c300000000000000000000000089889b569c3a505f3640ee1bd0ac1d557f436d2a03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee40500000000000000000000000062c0a111929fa32cec2f76adba54c16afb6e8364000000000000000000000000d56045e68956fce2576e680c95a4750cf8241f7903ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee405)]"

0x82ad56cb000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000026b2f158255beac46c1e7c6b8bbf29a4b6a7b76000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000164ff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000003000000000000000000000000229047fed2591dbec1ef1118d64f7af3db9eb290000000000000000000000000543ba4aadbab8f9025686bd03993043599c6fb0403ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee4050000000000000000000000007a8ed66b319911a0f3e7288bddab30d9c0c875c300000000000000000000000089889b569c3a505f3640ee1bd0ac1d557f436d2a03ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee40500000000000000000000000062c0a111929fa32cec2f76adba54c16afb6e8364000000000000000000000000d56045e68956fce2576e680c95a4750cf8241f7903ee2917da962ec266b091f4b62121dc9682bb0db534633707325339f99ee40500000000000000000000000000000000000000000000000000000000
```

This data should also appear in the Tenderly simulation trace, copy it and use `ctrl+f` to verify that
it appears in the tenderly trace as a call to `Multicall3DelegateCall`.


## Tenderly State Changes

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff
are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.
=======
## Understanding Task Calldata

Multicall3DelegateCall calldata:
```bash
0x82ad56cb000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000026b2f158255beac46c1e7c6b8bbf29a4b6a7b76000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000164ff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000003000000000000000000000000229047fed2591dbec1ef1118d64f7af3db9eb290000000000000000000000000543ba4aadbab8f9025686bd03993043599c6fb04039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d90000000000000000000000007a8ed66b319911a0f3e7288bddab30d9c0c875c300000000000000000000000089889b569c3a505f3640ee1bd0ac1d557f436d2a039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d900000000000000000000000062c0a111929fa32cec2f76adba54c16afb6e8364000000000000000000000000d56045e68956fce2576e680c95a4750cf8241f79039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d900000000000000000000000000000000000000000000000000000000
```

### Decode Multicall3DelegateCall calldata:
```bash
cast calldata-decode 'aggregate3((address,bool,bytes)[])' <0x82ad56cb...>

[
    (
        0x026b2F158255Beac46c1E7c6b8BbF29A4b6A7B76,
        false,
        0xff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000003000000000000000000000000229047fed2591dbec1ef1118d64f7af3db9eb290000000000000000000000000543ba4aadbab8f9025686bd03993043599c6fb04039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d90000000000000000000000007a8ed66b319911a0f3e7288bddab30d9c0c875c300000000000000000000000089889b569c3a505f3640ee1bd0ac1d557f436d2a039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d900000000000000000000000062c0a111929fa32cec2f76adba54c16afb6e8364000000000000000000000000d56045e68956fce2576e680c95a4750cf8241f79039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9
    )
]
```

1. First tuple (Call3 struct for Multicall3DelegateCall)
    - `target`: [0x026b2F158255Beac46c1E7c6b8BbF29A4b6A7B76](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/validation/standard/standard-versions-mainnet.toml#L21) - Mainnet OPContractsManager v2.0.0
    - `allowFailure`: false
    - `callData`: `0xff2dd5a1...` See below for decoding.
        - Command to encode: `cast calldata 'aggregate3((address,bool,bytes)[])' "[(0x026b2F158255Beac46c1E7c6b8BbF29A4b6A7B76,false,0xff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000003000000000000000000000000229047fed2591dbec1ef1118d64f7af3db9eb290000000000000000000000000543ba4aadbab8f9025686bd03993043599c6fb04039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d90000000000000000000000007a8ed66b319911a0f3e7288bddab30d9c0c875c300000000000000000000000089889b569c3a505f3640ee1bd0ac1d557f436d2a039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d900000000000000000000000062c0a111929fa32cec2f76adba54c16afb6e8364000000000000000000000000d56045e68956fce2576e680c95a4750cf8241f79039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9)]"`

### Decode upgrade calldata

```bash
cast calldata-decode 'upgrade((address,address,bytes32)[])' <0xff2dd5a1...>

[
    (
        0x229047fed2591dbec1eF1118d64F7aF3dB9EB290,
        0x543bA4AADBAb8f9025686Bd03993043599c6fB04,
        0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9
    ), 
    (
        0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3,
        0x89889B569c3a505f3640ee1Bd0ac1D557f436D2a,
        0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9
    ),
    (
        0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364,
        0xd56045E68956FCe2576E680c95a4750cf8241f79,
        0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9
    )
]
```
1. First tuple (OP Mainnet):
    - SystemConfigProxy: [0x229047fed2591dbec1eF1118d64F7aF3dB9EB290](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/mainnet/op.toml#L58)
    - ProxyAdmin: [0x543bA4AADBAb8f9025686Bd03993043599c6fB04](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/mainnet/op.toml#L59)
    - AbsolutePrestate: [0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9](https://github.com/ethereum-optimism/optimism/blob/63da401391e9be93517d242da5da24905aa5b84c/op-program/prestates/releases.json#L9)

2. Second tuple (Soneium):
    - SystemConfigProxy: [0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/mainnet/soneium.toml#L58)
    - ProxyAdmin: [0x89889B569c3a505f3640ee1Bd0ac1D557f436D2a](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/mainnet/soneium.toml#L59)
    - AbsolutePrestate: [0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9](https://github.com/ethereum-optimism/optimism/blob/63da401391e9be93517d242da5da24905aa5b84c/op-program/prestates/releases.json#L9)

3. Third tuple (Ink):
    - SystemConfigProxy: [0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/mainnet/ink.toml#L58)
    - ProxyAdmin: [0xd56045E68956FCe2576E680c95a4750cf8241f79](https://github.com/ethereum-optimism/superchain-registry/blob/d4bb112dc979fd43ac92252c549d3ed7c4d0eb57/superchain/configs/mainnet/ink.toml#L59)
    - AbsolutePrestate: [0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9](https://github.com/ethereum-optimism/optimism/blob/63da401391e9be93517d242da5da24905aa5b84c/op-program/prestates/releases.json#L9)

- Command to encode: `cast calldata 'upgrade((address,address,bytes32)[])' "[(0x229047fed2591dbec1eF1118d64F7aF3dB9EB290,0x543bA4AADBAb8f9025686Bd03993043599c6fB04,0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9),(0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3,0x89889B569c3a505f3640ee1Bd0ac1D557f436D2a,0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9),(0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364,0xd56045E68956FCe2576E680c95a4750cf8241f79,0x039facea52b20c605c05efb0a33560a92de7074218998f75bcdf61e8989cb5d9)]"`


## Tenderly State Changes
[Link](https://dashboard.tenderly.co/oplabs/eth-mainnet/simulator/ab8d86e3-d143-4e0b-9686-3dcab85a8609)


## Auto Generated Task State Changes

```bash
```
