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
> ### Base Operations (`0x9C4a57Feb77e294Fd7BF5EBE9AB01CAA0a90A110`)
>
> - Domain Hash:  `0xfb308368b8deca582e84a807d31c1bfcec6fda754061e2801b4d6be5cb52a8ac`
> - Message Hash: `0xda46ae8404c84e5ab5a1823b3c4b3379a1c610e7f9c5cfd43c3388c88457023d`
>
> ### Base Council (`0x20AcF55A3DCfe07fC4cecaCFa1628F788EC8A4Dd`)
>
> - Domain Hash:  `0x1fbfdc61ceb715f63cb17c56922b88c3a980f1d83873df2b9325a579753e8aa3`
> - Message Hash: `0x6d55b9a2f22dbc0280930a2800465d93570c7bcf69747baab4cdb6ab03cb48fa`
>
> ### Foundation Operations (`0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`)
>
> - Domain Hash:  `0x4e6a6554de0308f5ece8ff736beed8a1b876d16f5c27cac8e466d7de0c703890`
> - Message Hash: `0xb509e266fe97416f0dc1820a83c4384e11584d4a166dbb5dca348a2a6ac83929`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the OPCM upgrade to v4.1.0.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `opcm.upgrade()`

For each chain being upgraded, the `opcm.upgrade()` function is called with a tuple of three elements:

- SystemConfigProxy: [`0x73a79Fab69143498Ed3712e519A88a918e1f4072`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/base.toml#L49)
- ProxyAdmin: [`0x0475cBCAebd9CE8AfA5025828d5b98DFb67E059E`](https://github.com/ethereum-optimism/superchain-registry/blob/40526b1288534f6b84b7aae21d13c0b5f5b12f47/superchain/extra/addresses/addresses.json#L1238)
- AbsolutePrestate: [`0x03caa1871bb9fe7f9b11217c245c16e4ded33367df5b3ccb2c6d0a847a217d1b`](https://github.com/ethereum-optimism/superchain-registry/blob/9e3f71cee0e4e2acb4864cb00f5fbee3555d8e9f/validation/standard/standard-prestates.toml#L6C7-L6C73)

Thus, the command to encode the calldata is:

```bash
cast calldata 'upgrade((address,address,bytes32)[])' "[(0x73a79Fab69143498Ed3712e519A88a918e1f4072,0x0475cBCAebd9CE8AfA5025828d5b98DFb67E059E,0x03caa1871bb9fe7f9b11217c245c16e4ded33367df5b3ccb2c6d0a847a217d1b)]"
```

### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the argument to the `Multicall3DelegateCall.aggregate3()` function.

This function is called with a tuple of three elements:

Call3 struct for Multicall3DelegateCall:

- `target`: [0xfa1ef97fb02b0da2ee2346b8e310907ab5519449](https://github.com/ethereum-optimism/superchain-registry/blob/9e3f71cee0e4e2acb4864cb00f5fbee3555d8e9f/validation/standard/standard-versions-mainnet.toml#L23C56-L23C98) - OPCM
- `allowFailure`: false
- `callData`: `0xff2dd5a10000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000073a79fab69143498ed3712e519a88a918e1f40720000000000000000000000000475cbcaebd9ce8afa5025828d5b98dfb67e059e03caa1871bb9fe7f9b11217c245c16e4ded33367df5b3ccb2c6d0a847a217d1b` (output from the previous section)

Command to encode:

```bash
cast calldata 'aggregate3((address,bool,bytes)[])' "[(0xfa1ef97fb02b0da2ee2346b8e310907ab5519449,false,0xff2dd5a10000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000073a79fab69143498ed3712e519a88a918e1f40720000000000000000000000000475cbcaebd9ce8afa5025828d5b98dfb67e059e03caa1871bb9fe7f9b11217c245c16e4ded33367df5b3ccb2c6d0a847a217d1b)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x82ad56cb000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000fa1ef97fb02b0da2ee2346b8e310907ab55194490000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a4ff2dd5a10000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000073a79fab69143498ed3712e519a88a918e1f40720000000000000000000000000475cbcaebd9ce8afa5025828d5b98dfb67e059e03caa1871bb9fe7f9b11217c245c16e4ded33367df5b3ccb2c6d0a847a217d1b00000000000000000000000000000000000000000000000000000000
```
