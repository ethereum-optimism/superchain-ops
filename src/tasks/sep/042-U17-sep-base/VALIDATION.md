# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are
signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Base Operations (`0x6AF0674791925f767060Dd52f7fB20984E8639d8`)
>
> - Domain Hash:  `0x6f25427e79742a1eb82c103e2bf43c85fc59509274ec258ad6ed841c4a0048aa`
> - Message Hash: `0x7e3f1098b920980a54a4229ea9ed1e3bdaf574a1b6a5473ad3c317bde0153d42`
>
> ### Base Council (`0x5dfEB066334B67355A15dc9b67317fD2a2e1f77f`)
>
> - Domain Hash:  `0x0127bbb910536860a0757a9c0ffcdf9e4452220f566ed83af1f27f9e833f0e23`
> - Message Hash: `0x1410609732b5c870459041e7c1557d1e6442e2ffaadaf66dc36592185510d443`
>
> ### Base Operations (`0x6AF0674791925f767060Dd52f7fB20984E8639d8`) - Second Approve Hash Transaction
>
> - Domain Hash:  `0x6f25427e79742a1eb82c103e2bf43c85fc59509274ec258ad6ed841c4a0048aa`
> - Message Hash: `0x5ebd0e919700d0bd2d507988be826cd586115117d8f8bcb02386c1efd30722bf`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the OPCM upgrade to v4.1.0.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `opcm.upgrade()`

For each chain being upgraded, the `opcm.upgrade()` function is called with a tuple of three elements:

- SystemConfigProxy: [0xf272670eb55e895584501d564AfEB048bEd26194](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/base.toml#L60)
- ProxyAdmin: [0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/base.toml#L61)
- AbsolutePrestate: [0x03799051d2bfe459127d4597f469f535ff1bd2a6e1e2134443167620871c11f3](https://www.notion.so/oplabs/U16a-25bf153ee16280aa9050e03ddb4bbaf5)


Thus, the command to encode the calldata is:

```bash
cast calldata 'upgrade((address,address,bytes32)[])' "[(0xf272670eb55e895584501d564AfEB048bEd26194,0x0389E59Aa0a41E4A413Ae70f0008e76CAA34b1F3,0x03799051d2bfe459127d4597f469f535ff1bd2a6e1e2134443167620871c11f3)]"
```

### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the argument to the `Multicall3DelegateCall.aggregate3()` function.

This function is called with a tuple of three elements:

Call3 struct for Multicall3DelegateCall:

- `target`: [0x6af7ece7d6506be573841b8cf29096638df5fc4f](https://sepolia.etherscan.io/address/0x3bb6437aba031afbf9cb3538fa064161e2bf2d78) - Sepolia OPContractsManager v4.1.0
- `allowFailure`: false
- `callData`: `0xff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000f272670eb55e895584501d564afeb048bed261940000000000000000000000000389e59aa0a41e4a413ae70f0008e76caa34b1f303799051d2bfe459127d4597f469f535ff1bd2a6e1e2134443167620871c11f3` (output from the previous section)

Command to encode:

```bash
cast calldata 'aggregate3((address,bool,bytes)[])' "[(0x6af7ece7d6506be573841b8cf29096638df5fc4f,false,0xff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000f272670eb55e895584501d564afeb048bed261940000000000000000000000000389e59aa0a41e4a413ae70f0008e76caa34b1f303799051d2bfe459127d4597f469f535ff1bd2a6e1e2134443167620871c11f3)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x82ad56cb0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000006af7ece7d6506be573841b8cf29096638df5fc4f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a4ff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000f272670eb55e895584501d564afeb048bed261940000000000000000000000000389e59aa0a41e4a413ae70f0008e76caa34b1f303799051d2bfe459127d4597f469f535ff1bd2a6e1e2134443167620871c11f300000000000000000000000000000000000000000000000000000000
```
