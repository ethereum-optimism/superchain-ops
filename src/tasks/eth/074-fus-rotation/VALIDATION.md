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
> - Message Hash: `0x11eb752995a83290e9cabef24dad796bfa1b19d5fd98ea75c9e5affb03934873`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the signer rotation.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved plan with no unexpected modifications or side effects.

### Inputs to `safe.swapOwner()`

`safe.swapOwner()` function is called with the address to be removed and the previous owner:

- The address of the new signer: `0xa564C83958f7F9fA5a255a540EF5e49445873104`
- The address of the signer to be removed: `0x7F1D4FE689B73B628285454667B93cfd09409f27`
- The address of the previous signer: `0xC2Db495f5a1F91172A361AAFA6FdE47c41de6dF5` (this gets calculated by the template)

Thus, the command to encode the calldata is:

```bash
cast calldata 'swapOwner(address, address, address)' "0xC2Db495f5a1F91172A361AAFA6FdE47c41de6dF5" "0x7F1D4FE689B73B628285454667B93cfd09409f27" "0xa564C83958f7F9fA5a255a540EF5e49445873104"
```

### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the argument to the `Multicall3DelegateCall.aggregate3Value()` function.

This function is called with a tuple of four elements:

Call3 struct for Multicall3DelegateCall:

- `target`: 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 - Foundation Upgrade Safe
- `allowFailure`: false
- `value`: 0
- `callData`: `0xe318b52b000000000000000000000000c2db495f5a1f91172a361aafa6fde47c41de6df50000000000000000000000007f1d4fe689b73b628285454667b93cfd09409f27000000000000000000000000a564c83958f7f9fa5a255a540ef5e49445873104` (output from the previous section)

Command to encode:

```bash
cast calldata 'aggregate3Value((address,bool,uint256,bytes)[])' "[(0x847B5c174615B1B7fDF770882256e2D3E95b9D92,false,0,0xe318b52b000000000000000000000000c2db495f5a1f91172a361aafa6fde47c41de6df50000000000000000000000007f1d4fe689b73b628285454667b93cfd09409f27000000000000000000000000a564c83958f7f9fa5a255a540ef5e49445873104)]"
```

The resulting calldata sent from the Safe is thus:

```
0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000847b5c174615b1b7fdf770882256e2d3e95b9d920000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000064e318b52b000000000000000000000000c2db495f5a1f91172a361aafa6fde47c41de6df50000000000000000000000007f1d4fe689b73b628285454667b93cfd09409f27000000000000000000000000a564c83958f7f9fa5a255a540ef5e4944587310400000000000000000000000000000000000000000000000000000000
```

## State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

### State Overrides

Note: The changes listed below do not include threshold, nonce and owner mapping overrides. These changes are listed and explained in the [SINGLE-VALIDATION.md](../../../../docs/SINGLE-VALIDATION.md) file.

### Task State Changes

---

### `0x847b5c174615b1b7fdf770882256e2d3e95b9d92` (Foundation Upgrade Safe ([Etherscan](https://etherscan.io/address/0x847B5c174615B1B7fDF770882256e2D3E95b9D92))) - Chain ID: 1

All changes below are to the Safe's [owner linked list](https://github.com/safe-global/safe-contracts/blob/v1.4.1/contracts/libraries/SafeStorage.sol#L15), stored in the `owners` mapping at storage slot `2`. The linked list uses `SENTINEL_ADDRESS` (`0x1`) as both the head and tail marker. Each entry `owners[addr]` points to the next owner in the list. Swapping an owner replaces it in the linked list by updating the pointers of the previous and new owners.

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `73`
  - **After:** `74`
  - **Summary:** Safe nonce increment.
  - **Detail:** The Safe nonce is incremented from 73 to 74 after executing the transaction.

- **Key:**          `0xf04fb3d509ff2ad49e673f16457eebf7555ea5b99df785ff4c720c97186478c5`
  - **Before:** `0x0000000000000000000000007f1d4fe689b73b628285454667b93cfd09409f27`
  - **After:** `0x000000000000000000000000a564c83958f7f9fa5a255a540ef5e49445873104`
  - **Summary:** `owners[0xC2Db495f5a1F91172A361AAFA6FdE47c41de6dF5]` updated.
  - **Detail:** Updates the linked list pointer for `0xC2Db495f5a1F91172A361AAFA6FdE47c41de6dF5`: previously pointed to removed owner `0x7F1D4FE689B73B628285454667B93cfd09409f27`, now points to its replacement `0xa564C83958f7F9fA5a255a540EF5e49445873104`. The key can be derived from `cast index address 0xC2Db495f5a1F91172A361AAFA6FdE47c41de6dF5 2`.

- **Key:**          `0x8a51187ab97cdc11fa004a2d81f3ec1a62e1fbba9f996cba268aa5d2e9a084b7`
  - **Before:** `0x0000000000000000000000004d014f3c5f33aa9cd1dc29ce29618d07ae666d15`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Summary:** `owners[0x7F1D4FE689B73B628285454667B93cfd09409f27]` is zeroed out.
  - **Detail:** Removes `0x7F1D4FE689B73B628285454667B93cfd09409f27` from the owner linked list. Previously pointed to `0x4D014f3c5F33Aa9Cd1Dc29ce29618d07Ae666d15`. The key can be derived from `cast index address 0x7F1D4FE689B73B628285454667B93cfd09409f27 2`.

- **Key:**          `0x7e20ca24f43afeea816f5007fb8142dbf97e30d142d836bd08953dede7f8cfa7`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000004d014f3c5f33aa9cd1dc29ce29618d07ae666d15`
  - **Summary:** `owners[0xa564C83958f7F9fA5a255a540EF5e49445873104]` is set.
  - **Detail:** Inserts `0xa564C83958f7F9fA5a255a540EF5e49445873104` into the owner linked list, pointing to `0x4D014f3c5F33Aa9Cd1Dc29ce29618d07Ae666d15` as the next owner (the entry previously pointed to by the removed owner `0x7F1D4FE689B73B628285454667B93cfd09409f27`). The key can be derived from `cast index address 0xa564C83958f7F9fA5a255a540EF5e49445873104 2`.
