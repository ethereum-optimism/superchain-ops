# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are
signing.

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Security Council Safe (`0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`)
>
> - Domain Hash:  `0xbe081970e9fc104bd1ea27e375cd21ec7bb1eec56bfe43347c3e36c5d27b8533`
> - Message Hash: `0x0ac706408828a9281eb407b62c0f039f791ce44cd61cf7cdb3952ff22548b9fa`
>
> ### Foundation Safe (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`)
>
> - Domain Hash:  `0x37e1f5dd3b92a004a23589b741196c8a214629d4ea3a690ec8e41ae45c689cbb`
> - Message Hash: `0x4f9984269fff3c01d41061bbb20ee77c97b202b1f8b2fd11d445c5e412af75c9`

## Task Calldata
This document provides a detailed analysis of the final calldata executed on-chain for the OPCM upgrade to v4.1.0.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `opcm.upgrade()`

For each chain being upgraded, the `opcm.upgrade()` function is called with a tuple of three elements:

1. OP Sepolia Testnet:

- SystemConfigProxy: [0x034EdD2A225f7f429a63E0f1d2084B9E0a93b538](https://github.com/ethereum-optimism/superchain-registry/blob/eba13665234ec8b40bd15a9e948f3737e27be87f/superchain/configs/sepolia/op.toml#L60)
- ProxyAdmin: [0x189aBAAaa82DfC015A588A7dbaD6F13b1D3485Bc](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/op.toml#L61)
- AbsolutePrestate: [0x038dca684026d946d1d0ddb05d50685d1a0dab350b89d10b6705e83c41ec8755](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/validation/standard/standard-prestates.toml#L6)

2. Ink Sepolia Testnet:

- SystemConfigProxy: [0x05c993e60179f28bf649a2bb5b00b5f4283bd525](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L60)
- ProxyAdmin: [0xd7dB319a49362b2328cf417a934300cCcB442C8d](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/ink.toml#L61)
- AbsolutePrestate: [0x038dca684026d946d1d0ddb05d50685d1a0dab350b89d10b6705e83c41ec8755](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/validation/standard/standard-prestates.toml#L6)

3. Soneium Testnet Minato:

- SystemConfigProxy: [0x4Ca9608Fef202216bc21D543798ec854539bAAd3](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/soneium-minato.toml#L60)
- ProxyAdmin: [0xff9d236641962Cebf9DBFb54E7b8e91F99f10Db0](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/soneium-minato.toml#L61)
- AbsolutePrestate: [0x038dca684026d946d1d0ddb05d50685d1a0dab350b89d10b6705e83c41ec8755](https://github.com/ethereum-optimism/superchain-registry/blob/d82a61168fd1d7ef522ed8e213ce23c853031495/validation/standard/standard-prestates.toml#L6)

Thus, the command to encode the calldata is:

```bash 
cast calldata 'upgrade((address,address,bytes32)[])' "[(0x034edD2A225f7f429A63E0f1D2084B9E0A93b538,0x189aBAAaa82DfC015A588A7dbaD6F13b1D3485Bc,0x038dca684026d946d1d0ddb05d50685d1a0dab350b89d10b6705e83c41ec8755),(0x05C993e60179f28bF649a2Bb5b00b5F4283bD525,0xd7dB319a49362b2328cf417a934300cCcB442C8d,0x038dca684026d946d1d0ddb05d50685d1a0dab350b89d10b6705e83c41ec8755),(0x4Ca9608Fef202216bc21D543798ec854539bAAd3,0xff9d236641962Cebf9DBFb54E7b8e91F99f10Db0,0x038dca684026d946d1d0ddb05d50685d1a0dab350b89d10b6705e83c41ec8755)]"
```

### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the argument to the `Multicall3DelegateCall.aggregate3()` function.

This function is called with a tuple of three elements:

Call3 struct for Multicall3DelegateCall:

- `target`: [0x3bb6437aba031afbf9cb3538fa064161e2bf2d78](https://sepolia.etherscan.io/address/0x3bb6437aba031afbf9cb3538fa064161e2bf2d78) - Sepolia OPContractsManager v4.1.0
- `allowFailure`: false
- `callData`: `0xff2dd5a1...` (output from the previous section)

Command to encode:

```bash
cast calldata 'aggregate3((address,bool,bytes)[])' "[(0x6af7ece7d6506be573841b8cf29096638df5fc4f,false,0xff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000003000000000000000000000000034edd2a225f7f429a63e0f1d2084b9e0a93b538000000000000000000000000189abaaaa82dfc015a588a7dbad6f13b1d3485bc038dca684026d946d1d0ddb05d50685d1a0dab350b89d10b6705e83c41ec875500000000000000000000000005c993e60179f28bf649a2bb5b00b5f4283bd525000000000000000000000000d7db319a49362b2328cf417a934300cccb442c8d038dca684026d946d1d0ddb05d50685d1a0dab350b89d10b6705e83c41ec87550000000000000000000000004ca9608fef202216bc21d543798ec854539baad3000000000000000000000000ff9d236641962cebf9dbfb54e7b8e91f99f10db0038dca684026d946d1d0ddb05d50685d1a0dab350b89d10b6705e83c41ec8755)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

Calldata:
```
0x82ad56cb00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000001200000000000000000000000006af7ece7d6506be573841b8cf29096638df5fc4f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000044b0b807eb000000000000000000000000c2be75506d5724086deb7245bd260cc9753911be000000000000000000000000189abaaaa82dfc015a588a7dbad6f13b1d3485bc000000000000000000000000000000000000000000000000000000000000000000000000000000006af7ece7d6506be573841b8cf29096638df5fc4f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000164ff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000003000000000000000000000000034edd2a225f7f429a63e0f1d2084b9e0a93b538000000000000000000000000189abaaaa82dfc015a588a7dbad6f13b1d3485bc038dca684026d946d1d0ddb05d50685d1a0dab350b89d10b6705e83c41ec875500000000000000000000000005c993e60179f28bf649a2bb5b00b5f4283bd525000000000000000000000000d7db319a49362b2328cf417a934300cccb442c8d038dca684026d946d1d0ddb05d50685d1a0dab350b89d10b6705e83c41ec87550000000000000000000000004ca9608fef202216bc21d543798ec854539baad3000000000000000000000000ff9d236641962cebf9dbfb54e7b8e91f99f10db0038dca684026d946d1d0ddb05d50685d1a0dab350b89d10b6705e83c41ec875500000000000000000000000000000000000000000000000000000000
```