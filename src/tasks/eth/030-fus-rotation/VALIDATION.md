# Validation

This document can be used to validate the inputs and result of the execution of the transaction which you are
signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Verifying the transaction input](#understanding-task-calldata)

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Single Safe Signer Data
>
> - Domain Hash: `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0x3895b6a145b0f2e6dd7441c80c3f73260a7d8554b92266e44cb94c14ff00c839`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the signer rotation.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved plan with no unexpected modifications or side effects.

### Inputs to `safe.swapOwner()`

`safe.swapOwner()` function is called with the address to be removed and the previous module:

The address of the new signer: 0x69acfE2096Dfb8d5A041eF37693553c48d9BFd02
The address of the signer to be removed: 0x7cb07fe039a92b3d784f284d919503a381bec54f
The address of the previous signer: 0x4d014f3c5f33aa9cd1dc29ce29618d07ae666d15 (this gets calculated by the template)

Thus, the command to encode the calldata is:

```bash
cast calldata 'swapOwner(address, address, address)' "0x4d014f3c5f33aa9cd1dc29ce29618d07ae666d15" "0x7cb07fe039a92b3d784f284d919503a381bec54f" "0x69acfE2096Dfb8d5A041eF37693553c48d9BFd02"
```

### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the argument to the `Multicall3DelegateCall.aggregate3Value()` function.

This function is called with a tuple of four elements:

Call3 struct for Multicall3DelegateCall:

- `target`: 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 - Foundation Upgrade Safe
- `allowFailure`: false
- `value`: 0
- `callData`: `0xe318b52b0000000000000000000000004d014f3c5f33aa9cd1dc29ce29618d07ae666d150000000000000000000000007cb07fe039a92b3d784f284d919503a381bec54f00000000000000000000000069acfe2096dfb8d5a041ef37693553c48d9bfd02` (output from the previous section)

Command to encode:

```bash
cast calldata 'aggregate3Value((address,bool,uint256,bytes)[])' "[(0x847B5c174615B1B7fDF770882256e2D3E95b9D92,false,0,0xe318b52b0000000000000000000000004d014f3c5f33aa9cd1dc29ce29618d07ae666d150000000000000000000000007cb07fe039a92b3d784f284d919503a381bec54f00000000000000000000000069acfe2096dfb8d5a041ef37693553c48d9bfd02)]"
```

The resulting calldata sent from the ProxyAdminOwner safe is thus:

```
0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000847b5c174615b1b7fdf770882256e2d3e95b9d920000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000064e318b52b0000000000000000000000004d014f3c5f33aa9cd1dc29ce29618d07ae666d150000000000000000000000007cb07fe039a92b3d784f284d919503a381bec54f00000000000000000000000069acfe2096dfb8d5a041ef37693553c48d9bfd0200000000000000000000000000000000000000000000000000000000
```