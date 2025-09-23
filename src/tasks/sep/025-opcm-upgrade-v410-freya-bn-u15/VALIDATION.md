## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> - Domain Hash: `0x07e03428d7125835eca12b6dd1a02903029b456da3a091ecd66fda859fbce61e`
> - Message Hash: `0x39fb866390c69a0f90939e4060326d613c443cb8e3dcfd3ae8d0a02684fd296a`

## Normalized State Diff Hash Attestation

The normalized state diff hash MUST match the hash created by the state changes attested to in the state diff audit report.
As a signer, you are responsible for making sure this hash is correct. Please compare the hash below with the hash in the audit report.

**Normalized hash:** `0x2947dcb936f43d5c5a895dec1a0a4c14d92a36b6a2627f1044ee95f7caeb1148`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the OPCM upgrade to v4.1.0.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `opcm.upgrade()`

For each chain being upgraded, the `opcm.upgrade()` function is called with a tuple of three elements:

1. freya-u15-0:

- SystemConfigProxy: [0xc9907767C474D0DB28a50cC0d2ec124CC20FF339](https://github.com/ethereum-optimism/devnets/blob/ea0a8e288486ea0059b32d779bb648899abc984c/betanets/freya-u15/freya-u15-0/chain.yaml#L16C25-L16C67)
- ProxyAdmin: [0xE63E65F0d4Dfbcf89aeA8948E02961ece5529C91](https://github.com/ethereum-optimism/devnets/blob/ea0a8e288486ea0059b32d779bb648899abc984c/betanets/freya-u15/freya-u15-0/chain.yaml#L12)
- AbsolutePrestate: [0x03f0fcd170d6538082f38fd2911a7169162f1f0922253325851a5b0b97b920d8]()

2. freya-u15-1:

- SystemConfigProxy: [0xfF2E59D1dce5519eFE8194d8d8d76958B51893a1](https://github.com/ethereum-optimism/devnets/blob/dad7af4615259f941367fcbc45063aa8c03f5193/betanets/freya-u15/freya-u15-1/chain.yaml#L16C25-L16C67)
- ProxyAdmin: [0x1849564EAd5Cc223b0549962a30d9E67649a1a0c](https://github.com/ethereum-optimism/devnets/blob/dad7af4615259f941367fcbc45063aa8c03f5193/betanets/freya-u15/freya-u15-1/chain.yaml#L12C29-L12C71)
- AbsolutePrestate: [0x03f0fcd170d6538082f38fd2911a7169162f1f0922253325851a5b0b97b920d8]()

Thus, the command to encode the calldata is:

```bash
cast calldata 'upgrade((address,address,bytes32)[])' "[(0xc9907767C474D0DB28a50cC0d2ec124CC20FF339,0xE63E65F0d4Dfbcf89aeA8948E02961ece5529C91,0x03f0fcd170d6538082f38fd2911a7169162f1f0922253325851a5b0b97b920d8),(0xfF2E59D1dce5519eFE8194d8d8d76958B51893a1,0x1849564EAd5Cc223b0549962a30d9E67649a1a0c,0x03f0fcd170d6538082f38fd2911a7169162f1f0922253325851a5b0b97b920d8)]"
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
cast calldata 'aggregate3((address,bool,bytes)[])' "[(0x3bb6437aba031afbf9cb3538fa064161e2bf2d78,false,0xff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000c9907767c474d0db28a50cc0d2ec124cc20ff339000000000000000000000000e63e65f0d4dfbcf89aea8948e02961ece5529c9103f0fcd170d6538082f38fd2911a7169162f1f0922253325851a5b0b97b920d8000000000000000000000000ff2e59d1dce5519efe8194d8d8d76958b51893a10000000000000000000000001849564ead5cc223b0549962a30d9e67649a1a0c03f0fcd170d6538082f38fd2911a7169162f1f0922253325851a5b0b97b920d8)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x82ad56cb0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000003bb6437aba031afbf9cb3538fa064161e2bf2d78000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000104ff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000c9907767c474d0db28a50cc0d2ec124cc20ff339000000000000000000000000e63e65f0d4dfbcf89aea8948e02961ece5529c9103f0fcd170d6538082f38fd2911a7169162f1f0922253325851a5b0b97b920d8000000000000000000000000ff2e59d1dce5519efe8194d8d8d76958b51893a10000000000000000000000001849564ead5cc223b0549962a30d9e67649a1a0c03f0fcd170d6538082f38fd2911a7169162f1f0922253325851a5b0b97b920d800000000000000000000000000000000000000000000000000000000
```
