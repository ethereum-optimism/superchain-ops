## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> - Domain Hash: `0x07e03428d7125835eca12b6dd1a02903029b456da3a091ecd66fda859fbce61e`
> - Message Hash: `0x8729f0c9c165b505fd92ceb5e84abaa1dc652cdabf5f6145af017557978a8582`

## Normalized State Diff Hash Attestation

The normalized state diff hash MUST match the hash created by the state changes attested to in the state diff audit report.
As a signer, you are responsible for making sure this hash is correct. Please compare the hash below with the hash in the audit report.

**Normalized hash:** `0x11365f55bca590ef57aed491accbfca611f82d26a962c6b68d3a93f5c32bdccd`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the OPCM upgrade to v4.1.0.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `opcm.upgradeSuperchainConfig()`

The `opcm.upgradeSuperchainConfig()` function is called with a 2 inputs:

- SuperchainConfig: [0x696093050C25Af778afb3d1c3B371aB236C324E8](https://github.com/ethereum-optimism/devnets/blob/dad7af4615259f941367fcbc45063aa8c03f5193/betanets/freya-u15/freya-u15-0/chain.yaml#L7)
- SuperchainConfigProxyAdmin: [0x282ADE3eE960681Ed3b3E3692bA8b74E878cEE57](https://github.com/ethereum-optimism/devnets/blob/dad7af4615259f941367fcbc45063aa8c03f5193/betanets/freya-u15/freya-u15-0/chain.yaml#L6C32-L6C74)

Thus, the command to encode the calldata is:

```bash
cast calldata 'upgradeSuperchainConfig(address,address)' "0x696093050C25Af778afb3d1c3B371aB236C324E8" "0x282ADE3eE960681Ed3b3E3692bA8b74E878cEE57"
```

### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the argument to the `Multicall3DelegateCall.aggregate3()` function.

This function is called with a tuple of three elements:

Call3 struct for Multicall3DelegateCall:

- `target`: [0x3bb6437aba031afbf9cb3538fa064161e2bf2d78](https://sepolia.etherscan.io/address/0x3bb6437aba031afbf9cb3538fa064161e2bf2d78) - Sepolia OPContractsManager v4.1.0
- `allowFailure`: false
- `callData`: `0xb0b807eb...` (output from the previous section)

Command to encode:

```bash
cast calldata 'aggregate3((address,bool,bytes)[])' "[(0x3bb6437aba031afbf9cb3538fa064161e2bf2d78,false,0xb0b807eb000000000000000000000000696093050c25af778afb3d1c3b371ab236c324e8000000000000000000000000282ade3ee960681ed3b3e3692ba8b74e878cee57)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x82ad56cb0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000003bb6437aba031afbf9cb3538fa064161e2bf2d78000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000044b0b807eb000000000000000000000000696093050c25af778afb3d1c3b371ab236c324e8000000000000000000000000282ade3ee960681ed3b3e3692ba8b74e878cee5700000000000000000000000000000000000000000000000000000000
```
