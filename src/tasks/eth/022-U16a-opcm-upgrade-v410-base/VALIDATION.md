# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are
signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Verifying the state changes via the normalized state diff hash](#normalized-state-diff-hash-attestation)
3. [Verifying the transaction input](#understanding-task-calldata)
4. [Verifying the state changes](#task-state-changes)

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Base Operations (`0x9C4a57Feb77e294Fd7BF5EBE9AB01CAA0a90A110`)
>
> - Domain Hash:  `0xfb308368b8deca582e84a807d31c1bfcec6fda754061e2801b4d6be5cb52a8ac`
> - Message Hash: `0x5ae6e3b8fe66bd6cbe5fae6374222b43a874c13ca850745926ecc430cafdb21a`
>
> ### Base Council (`0x20AcF55A3DCfe07fC4cecaCFa1628F788EC8A4Dd`)
>
> - Domain Hash:  `0x1fbfdc61ceb715f63cb17c56922b88c3a980f1d83873df2b9325a579753e8aa3`
> - Message Hash: `0x520aeeb85997f9db884ae07d1da74b5251550f49ab662b9ada3fa34572ece772`
>
> ### Foundation Operations (`0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`)
>
> - Domain Hash:  `0x4e6a6554de0308f5ece8ff736beed8a1b876d16f5c27cac8e466d7de0c703890`
> - Message Hash: `0x2b7f17c0100e6766aaac289acba0122860a51bdd64810626948b0f986f88efa5`

## Normalized State Diff Hash Attestation

The normalized state diff hash **MUST** match the hash produced by the state changes attested to in the state diff audit report. As a signer, you are responsible for verifying that this hash is correct. Please compare the hash below with the one in the audit report. If no audit report is available for this task, you must still ensure that the normalized state diff hash matches the output in your terminal.

**Normalized hash:** `0x1040a2a57a0fc30a1ff18d3c0e35898dbf98c89dc172945b99a0f3b65508c659`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the OPCM upgrade to v4.1.0.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `opcm.upgrade()`

For each chain being upgraded, the `opcm.upgrade()` function is called with a tuple of three elements:

- SystemConfigProxy: [`0x73a79Fab69143498Ed3712e519A88a918e1f4072`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/base.toml#L49)
- ProxyAdmin: [`0x0475cBCAebd9CE8AfA5025828d5b98DFb67E059E`](https://github.com/ethereum-optimism/superchain-registry/blob/40526b1288534f6b84b7aae21d13c0b5f5b12f47/superchain/extra/addresses/addresses.json#L1238)
- AbsolutePrestate: [`0x03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8`](https://www.notion.so/oplabs/U16a-25bf153ee16280aa9050e03ddb4bbaf5)

Thus, the command to encode the calldata is:

```bash
cast calldata 'upgrade((address,address,bytes32)[])' "[(0x73a79Fab69143498Ed3712e519A88a918e1f4072,0x0475cBCAebd9CE8AfA5025828d5b98DFb67E059E,0x03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8)]"
```

### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the argument to the `Multicall3DelegateCall.aggregate3()` function.

This function is called with a tuple of three elements:

Call3 struct for Multicall3DelegateCall:

- `target`: [0x8123739c1368c2dedc8c564255bc417feeebff9d](https://etherscan.io/address/0x8123739c1368c2dedc8c564255bc417feeebff9d) - OPContractsManager v4.1.0
- `allowFailure`: false
- `callData`: `0xff2dd5a1...` (output from the previous section)

Command to encode:

```bash
cast calldata 'aggregate3((address,bool,bytes)[])' "[(0x8123739c1368c2dedc8c564255bc417feeebff9d,false,0xff2dd5a10000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000073a79fab69143498ed3712e519a88a918e1f40720000000000000000000000000475cbcaebd9ce8afa5025828d5b98dfb67e059e03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc8)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x82ad56cb0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000008123739c1368c2dedc8c564255bc417feeebff9d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a4ff2dd5a10000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000073a79fab69143498ed3712e519a88a918e1f40720000000000000000000000000475cbcaebd9ce8afa5025828d5b98dfb67e059e03eb07101fbdeaf3f04d9fb76526362c1eea2824e4c6e970bdb19675b72e4fc800000000000000000000000000000000000000000000000000000000
```

# Task State Changes

- [Base Council State Changes](./BASE_SC_VALIDATION.md)
- [Base Operations State Changes](./BASE_OPS_VALIDATION.md)
- [Foundation Operations State Changes](./FND_OPS_VALIDATION.md)
