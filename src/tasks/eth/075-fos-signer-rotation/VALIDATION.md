# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the
pinned nonce in [config.toml](./config.toml) (FoundationOperationsSafe 122) and move only if that nonce
moves.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### FoundationOperationsSafe (`0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`)
>
> - Domain Hash:  `0x2e5ad244d335c45fbace4ebd1736b0fad81b01591a2819baedad311ead5bce76`
> - Message Hash: `0x81fb3909d59bc12f8aa772c46fc7ee1ec88a2f7c0123ac46ef4223f15eafe082`

Safe transaction hash: `0x96d188acb079f08088614054de2cb4ca333db6a09ecfa62288d9bfe41492b258`

## Understanding Task Calldata

The task swaps a single owner on the FoundationOperationsSafe via `Multicall3DelegateCall`.

### Inputs to `safe.swapOwner()`

`swapOwner(prevOwner, oldOwner, newOwner)` takes the owner that points to the removed owner in the
Safe's owner linked list (computed by the template):

- Previous owner: `0xC2Db495f5a1F91172A361AAFA6FdE47c41de6dF5`
- Owner to remove: `0x7F1D4FE689B73B628285454667B93cfd09409f27`
- Owner to add: `0xa564C83958f7F9fA5a255a540EF5e49445873104`

```bash
cast calldata 'swapOwner(address,address,address)' "0xC2Db495f5a1F91172A361AAFA6FdE47c41de6dF5" "0x7F1D4FE689B73B628285454667B93cfd09409f27" "0xa564C83958f7F9fA5a255a540EF5e49445873104"
```

```
0xe318b52b000000000000000000000000c2db495f5a1f91172a361aafa6fde47c41de6df50000000000000000000000007f1d4fe689b73b628285454667b93cfd09409f27000000000000000000000000a564c83958f7f9fa5a255a540ef5e49445873104
```

### Inputs to `Multicall3DelegateCall`

The output above is the `data` of the single `Call3Value` struct passed to
`Multicall3DelegateCall.aggregate3Value()`, targeting the FoundationOperationsSafe (`0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`) with
`allowFailure: false` and `value: 0`.

```bash
cast calldata 'aggregate3Value((address,bool,uint256,bytes)[])' "[(0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A,false,0,0xe318b52b000000000000000000000000c2db495f5a1f91172a361aafa6fde47c41de6df50000000000000000000000007f1d4fe689b73b628285454667b93cfd09409f27000000000000000000000000a564c83958f7f9fa5a255a540ef5e49445873104)]"
```

The resulting calldata:
```
0x174dea710000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000009ba6e03d8b90de867373db8cf1a58d2f7f006b3a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000064e318b52b000000000000000000000000c2db495f5a1f91172a361aafa6fde47c41de6df50000000000000000000000007f1d4fe689b73b628285454667b93cfd09409f27000000000000000000000000a564c83958f7f9fa5a255a540ef5e4944587310400000000000000000000000000000000000000000000000000000000
```

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes
shown in the Tenderly diff are missing from this document. Additionally, please verify that for
each contract:

- The following state changes (and none others) are made to that contract. This validates that
  no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the
  Etherscan links provided.
- All key values match the semantic meaning provided, which can be validated using the storage
  layout links provided.

### State Overrides

Note: The changes listed below do not include threshold, nonce and owner mapping overrides.
These changes are listed and explained in the
[SINGLE-VALIDATION.md](../../../../docs/SINGLE-VALIDATION.md) file.

### Task State Changes

---

### `0x9ba6e03d8b90de867373db8cf1a58d2f7f006b3a` (FoundationOperationsSafe ([Etherscan](https://etherscan.io/address/0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A))) - Chain ID: 1

All non-nonce changes below are to the Safe's
[owner linked list](https://github.com/safe-global/safe-contracts/blob/v1.4.1/contracts/libraries/SafeStorage.sol#L15),
stored in the `owners` mapping at storage slot `2`. Each entry `owners[addr]` points to the next
owner in the list; `swapOwner` replaces the removed owner's entry with the new owner's.

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `122`
  - **After:** `123`
  - **Summary:** Safe nonce increment.

- **Key:**          `0x8a51187ab97cdc11fa004a2d81f3ec1a62e1fbba9f996cba268aa5d2e9a084b7`
  - **Before:** `0x0000000000000000000000004d014f3c5f33aa9cd1dc29ce29618d07ae666d15`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Summary:** `owners[0x7F1D4FE689B73B628285454667B93cfd09409f27]` is zeroed out (owner removed).
  - **Detail:** `cast index address 0x7F1D4FE689B73B628285454667B93cfd09409f27 2`

- **Key:**          `0x7e20ca24f43afeea816f5007fb8142dbf97e30d142d836bd08953dede7f8cfa7`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000004d014f3c5f33aa9cd1dc29ce29618d07ae666d15`
  - **Summary:** `owners[0xa564C83958f7F9fA5a255a540EF5e49445873104]` is set to the removed owner's next pointer (owner added).
  - **Detail:** `cast index address 0xa564C83958f7F9fA5a255a540EF5e49445873104 2`

- **Key:**          `0xf04fb3d509ff2ad49e673f16457eebf7555ea5b99df785ff4c720c97186478c5`
  - **Before:** `0x0000000000000000000000007f1d4fe689b73b628285454667b93cfd09409f27`
  - **After:** `0x000000000000000000000000a564c83958f7f9fa5a255a540ef5e49445873104`
  - **Summary:** `owners[0xC2Db495f5a1F91172A361AAFA6FdE47c41de6dF5]` now points to the new owner instead of the removed one.
  - **Detail:** `cast index address 0xC2Db495f5a1F91172A361AAFA6FdE47c41de6dF5 2`
