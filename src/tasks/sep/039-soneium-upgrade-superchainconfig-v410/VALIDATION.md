## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Proxy Admin Owner for Soneium Devnet (`0xFB0F8937A0d6999C67E8a01310eBf7fe1859205F`):
>
> - Domain Hash: `0xbb7710987add9bc4f5949e44bc3405df5cbd2c021caeb85ef000e46a8ef2c077`
> - Message Hash: `0x8861bd404ba0669b1125aeee4bdb651d45f6c58532e0e5ee60366f42214c86c0`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the OPCM upgrade to v4.1.0.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved upgrade plan with no unexpected modifications or side effects.

### Inputs to `opcm.upgradeSuperchainConfig()`

The `opcm.upgradeSuperchainConfig()` function is called with a 2 inputs:

- SuperchainConfig: [0xc92831eB4544053Dc330AB2cD4164e1EB3157A8E]
- SuperchainConfigProxyAdmin: [0x664e70e3d58eee0eef8b6b192015f43ab7323007]

Thus, the command to encode the calldata is:

```bash
cast calldata 'upgradeSuperchainConfig(address,address)' "0xc92831eB4544053Dc330AB2cD4164e1EB3157A8E" "0x664e70e3d58eee0eef8b6b192015f43ab7323007"
```

### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the argument to the `Multicall3DelegateCall.aggregate3()` function.

This function is called with a tuple of three elements:

Call3 struct for Multicall3DelegateCall:

- `target`: [0xd07a89cf19869ce185a5ec173568ae8acd5d8c02] - Sepolia OPContractsManager v4.1.0
- `allowFailure`: false
- `callData`: `0xb0b807eb000000000000000000000000c92831eb4544053dc330ab2cd4164e1eb3157a8e000000000000000000000000664e70e3d58eee0eef8b6b192015f43ab7323007` (output from the previous section)

Command to encode:

```bash
cast calldata 'aggregate3((address,bool,bytes)[])' "[(0xd07a89cf19869ce185a5ec173568ae8acd5d8c02,false,0xb0b807eb000000000000000000000000c92831eb4544053dc330ab2cd4164e1eb3157a8e000000000000000000000000664e70e3d58eee0eef8b6b192015f43ab7323007)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x82ad56cb000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000d07a89cf19869ce185a5ec173568ae8acd5d8c02000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000044b0b807eb000000000000000000000000c92831eb4544053dc330ab2cd4164e1eb3157a8e000000000000000000000000664e70e3d58eee0eef8b6b192015f43ab732300700000000000000000000000000000000000000000000000000000000
```
