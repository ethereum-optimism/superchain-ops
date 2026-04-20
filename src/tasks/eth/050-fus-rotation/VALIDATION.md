# Validation

This document can be used to validate the inputs and result of the execution of the transaction which you are
signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Verifying the transaction input](#understanding-task-calldata)
3. [Task State Changes](#task-state-changes)

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Foundation Upgrade Safe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0x0a2dbde3b31ab9ea8754abdaec5f44209ad318e09c2743edbd8d7562480d6178`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the signer rotation.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved plan with no unexpected modifications or side effects.

### Inputs to `safe.swapOwner()`

`safe.swapOwner()` function is called with the address to be removed and the previous owner:

- The address of the new signer: `0xa2A58E31C03C59e34ab4d996d811DA0C035BfDea`
- The address of the signer to be removed: `0xc222ab08333109243B1f4E2a80e3D0A190714AB5`
- The address of the previous signer: `0x69acfE2096Dfb8d5A041eF37693553c48d9BFd02` (this gets calculated by the template)

Thus, the command to encode the calldata is:

```bash
cast calldata 'swapOwner(address, address, address)' "0x69acfE2096Dfb8d5A041eF37693553c48d9BFd02" "0xc222ab08333109243B1f4E2a80e3D0A190714AB5" "0xa2A58E31C03C59e34ab4d996d811DA0C035BfDea"
```

### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the argument to the `Multicall3DelegateCall.aggregate3Value()` function.

This function is called with a tuple of four elements:

Call3 struct for Multicall3DelegateCall:

- `target`: 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 - Foundation Upgrade Safe
- `allowFailure`: false
- `value`: 0
- `callData`: `0xe318b52b00000000000000000000000069acfe2096dfb8d5a041ef37693553c48d9bfd02000000000000000000000000c222ab08333109243b1f4e2a80e3d0a190714ab5000000000000000000000000a2a58e31c03c59e34ab4d996d811da0c035bfdea` (output from the previous section)

Command to encode:

```bash
cast calldata 'aggregate3Value((address,bool,uint256,bytes)[])' "[(0x847B5c174615B1B7fDF770882256e2D3E95b9D92,false,0,0xe318b52b00000000000000000000000069acfe2096dfb8d5a041ef37693553c48d9bfd02000000000000000000000000c222ab08333109243b1f4e2a80e3d0a190714ab5000000000000000000000000a2a58e31c03c59e34ab4d996d811da0c035bfdea)]"
```

The resulting calldata sent from the Safe is thus:

```
0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000847b5c174615b1b7fdf770882256e2d3e95b9d920000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000064e318b52b00000000000000000000000069acfe2096dfb8d5a041ef37693553c48d9bfd02000000000000000000000000c222ab08333109243b1f4e2a80e3d0a190714ab5000000000000000000000000a2a58e31c03c59e34ab4d996d811da0c035bfdea00000000000000000000000000000000000000000000000000000000
```

## State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

### State Overrides

Note: The changes listed below do not include threshold, nonce and owner mapping overrides. These changes are listed and explained in the [SINGLE-VALIDATION.md](../../../../../docs/SINGLE-VALIDATION.md) file.

### Task State Changes

---

### `0x847b5c174615b1b7fdf770882256e2d3e95b9d92` (Foundation Upgrade Safe ([Etherscan](https://etherscan.io/address/0x847B5c174615B1B7fDF770882256e2D3E95b9D92))) - Chain ID: 1

All changes below are to the Safe's [owner linked list](https://github.com/safe-global/safe-contracts/blob/v1.4.1/contracts/libraries/SafeStorage.sol#L15), stored in the `owners` mapping at storage slot `2`. The linked list uses `SENTINEL_ADDRESS` (`0x1`) as both the head and tail marker. Each entry `owners[addr]` points to the next owner in the list. Swapping an owner replaces it in the linked list by updating the pointers of the previous and new owners.

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `55`
  - **After:** `56`
  - **Summary:** Safe nonce increment.
  - **Detail:** The Safe nonce is incremented from 55 to 56 after executing the transaction.

- **Key:**          `0xe7e3353d68a7e03f4138977d7f45b7462f2b595cbb1e4f173eba484d73d73833`
  - **Before:** `0x000000000000000000000000c222ab08333109243b1f4e2a80e3d0a190714ab5`
  - **After:** `0x000000000000000000000000a2a58e31c03c59e34ab4d996d811da0c035bfdea`
  - **Summary:** `owners[0x69acfE2096Dfb8d5A041eF37693553c48d9BFd02]` updated.
  - **Detail:** Updates the linked list pointer for `0x69acfE2096Dfb8d5A041eF37693553c48d9BFd02`: previously pointed to removed owner `0xc222ab08333109243B1f4E2a80e3D0A190714AB5`, now points to its replacement `0xa2A58E31C03C59e34ab4d996d811DA0C035BfDea`. The key can be derived from `cast index address 0x69acfE2096Dfb8d5A041eF37693553c48d9BFd02 2`.

- **Key:**          `0xf87408e7441de59b95281769472fc11649ed37d0b7cea54e4d67e7ec9c19ecb8`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Summary:** `owners[0xc222ab08333109243B1f4E2a80e3D0A190714AB5]` is zeroed out.
  - **Detail:** Removes `0xc222ab08333109243B1f4E2a80e3D0A190714AB5` from the owner linked list. Previously pointed to `SENTINEL` (`0x1`), meaning it was the last owner in the list. The key can be derived from `cast index address 0xc222ab08333109243B1f4E2a80e3D0A190714AB5 2`.

- **Key:**          `0xc0ff7eea133487ecb495cee399a61899dc3f2f8899801556906be42a3c48d775`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** `owners[0xa2A58E31C03C59e34ab4d996d811DA0C035BfDea]` is set.
  - **Detail:** Inserts `0xa2A58E31C03C59e34ab4d996d811DA0C035BfDea` into the owner linked list, pointing to `SENTINEL` (`0x1`) as the next entry, making it the last owner in the list. The key can be derived from `cast index address 0xa2A58E31C03C59e34ab4d996d811DA0C035BfDea 2`.
