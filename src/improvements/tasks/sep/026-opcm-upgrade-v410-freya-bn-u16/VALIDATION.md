## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> - Domain Hash: `0x07e03428d7125835eca12b6dd1a02903029b456da3a091ecd66fda859fbce61e`
> - Message Hash: `0x0a630e0ea64d271e86faa264330707bfcb954d72f7b0844ea8fea927a4bebb33`

## Normalized State Diff Hash Attestation

The normalized state diff hash MUST match the hash created by the state changes attested to in the state diff audit report.
As a signer, you are responsible for making sure this hash is correct. Please compare the hash below with the hash in the audit report.

**Normalized hash:** `0x20ce75f336aa785affb1db35da18c08acb1b87f69648e104784001d1eb0cde39`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the OPCM upgrade to v4.1.0.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `opcm.upgrade()`

For each chain being upgraded, the `opcm.upgrade()` function is called with a tuple of three elements:

1. freya-u16-0:

- SystemConfigProxy: [0x207BF7d95964Ac655cB60B99c46c5a5AabEA1F8F](https://github.com/ethereum-optimism/devnets/blob/dad7af4615259f941367fcbc45063aa8c03f5193/betanets/freya-u16/freya-u16-0/chain.yaml#L16C25-L16C67)
- ProxyAdmin: [0x7d9b0Aa175dc8769a576C2aD1C791AAAcbe873a9](https://github.com/ethereum-optimism/devnets/blob/dad7af4615259f941367fcbc45063aa8c03f5193/betanets/freya-u16/freya-u16-0/chain.yaml#L12C29-L12C71)
- AbsolutePrestate: [0x03a3ba2e11df6b4fcf0d6e312288ce28aa4a26fd211134927a9f3c0d38bd5aef](https://github.com/ethereum-optimism/devnets/blob/ea0a8e288486ea0059b32d779bb648899abc984c/betanets/freya-u16/op-program/prestates.json#L3C14-L3C80)

2. freya-u16-1:

- SystemConfigProxy: [0xA51cd60345557da1580883dB69E29725Ad465c0a](https://github.com/ethereum-optimism/devnets/blob/dad7af4615259f941367fcbc45063aa8c03f5193/betanets/freya-u16/freya-u16-1/chain.yaml#L16C25-L16C67)
- ProxyAdmin: [0xC9DE4e28835eb48a3AdE88bBC39108b15EdF7efc](https://github.com/ethereum-optimism/devnets/blob/dad7af4615259f941367fcbc45063aa8c03f5193/betanets/freya-u16/freya-u16-1/chain.yaml#L12C29-L12C71)
- AbsolutePrestate: [0x03a3ba2e11df6b4fcf0d6e312288ce28aa4a26fd211134927a9f3c0d38bd5aef](https://github.com/ethereum-optimism/devnets/blob/ea0a8e288486ea0059b32d779bb648899abc984c/betanets/freya-u16/op-program/prestates.json#L3C14-L3C80)

Thus, the command to encode the calldata is:

```bash
cast calldata 'upgrade((address,address,bytes32)[])' "[(0x207BF7d95964Ac655cB60B99c46c5a5AabEA1F8F,0x7d9b0Aa175dc8769a576C2aD1C791AAAcbe873a9,0x03a3ba2e11df6b4fcf0d6e312288ce28aa4a26fd211134927a9f3c0d38bd5aef),(0xA51cd60345557da1580883dB69E29725Ad465c0a,0xC9DE4e28835eb48a3AdE88bBC39108b15EdF7efc,0x03a3ba2e11df6b4fcf0d6e312288ce28aa4a26fd211134927a9f3c0d38bd5aef)]"
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
cast calldata 'aggregate3((address,bool,bytes)[])' "[(0x3bb6437aba031afbf9cb3538fa064161e2bf2d78,false,0xff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000207bf7d95964ac655cb60b99c46c5a5aabea1f8f0000000000000000000000007d9b0aa175dc8769a576c2ad1c791aaacbe873a903a3ba2e11df6b4fcf0d6e312288ce28aa4a26fd211134927a9f3c0d38bd5aef000000000000000000000000a51cd60345557da1580883db69e29725ad465c0a000000000000000000000000c9de4e28835eb48a3ade88bbc39108b15edf7efc03a3ba2e11df6b4fcf0d6e312288ce28aa4a26fd211134927a9f3c0d38bd5aef)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x82ad56cb0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000003bb6437aba031afbf9cb3538fa064161e2bf2d78000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000104ff2dd5a100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000207bf7d95964ac655cb60b99c46c5a5aabea1f8f0000000000000000000000007d9b0aa175dc8769a576c2ad1c791aaacbe873a903a3ba2e11df6b4fcf0d6e312288ce28aa4a26fd211134927a9f3c0d38bd5aef000000000000000000000000a51cd60345557da1580883db69e29725ad465c0a000000000000000000000000c9de4e28835eb48a3ade88bbc39108b15edf7efc03a3ba2e11df6b4fcf0d6e312288ce28aa4a26fd211134927a9f3c0d38bd5aef00000000000000000000000000000000000000000000000000000000
```
