# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are
signing.

The steps are:

1. [Expected Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Understanding Task Calldata](#understanding-task-calldata)
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
> - Message Hash: `0x6a96d603024144b2fdc5daf16615399b9b35266b3767040b831363e09255af18`

> [!NOTE]
>
> This is task 2 of 4 of the rotation. It executes after `055-fus-rotation-1`, at FUS nonce 60 (which follows the pending U19 tasks at nonces 57 and 58). The message hash above was generated against the full task stack at that nonce. If the ordering or the FUS nonce changes before signing, re-simulate to regenerate the hash.

> [!IMPORTANT]
>
> Owner `0x7F1D4FE689B73B628285454667B93cfd09409f27` (added to the Foundation Upgrade Safe in `055-fus-rotation-1`) MUST be one of the signers for this task, alongside 4 other current owners to reach the threshold of 5.

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the signer rotation.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved plan with no unexpected modifications or side effects.

This task swaps a single owner on the Foundation Upgrade Safe via `Multicall3DelegateCall`.

### Inputs to `safe.swapOwner()`

`safe.swapOwner()` is called with the previous owner (calculated by the template), the owner to remove, and the new owner:

- Previous owner: `0x0000000000000000000000000000000000000001` (SENTINEL, calculated by the template)
- Owner to remove: `0x6419F81580343DF023E68715C6e269aFb00a2cc7`
- New owner: `0xf1EfbdC2C0BDC4554E0f1639D7fe88cD870a4639`

```bash
cast calldata 'swapOwner(address, address, address)' "0x0000000000000000000000000000000000000001" "0x6419F81580343DF023E68715C6e269aFb00a2cc7" "0xf1EfbdC2C0BDC4554E0f1639D7fe88cD870a4639"
```

### Inputs to `Multicall3DelegateCall`

The output from the previous section becomes the `data` in the single `Call3Value` struct passed to `Multicall3DelegateCall.aggregate3Value()`. The struct targets the Foundation Upgrade Safe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`) with `allowFailure: false` and `value: 0`.

```bash
cast calldata 'aggregate3Value((address,bool,uint256,bytes)[])' "[(0x847B5c174615B1B7fDF770882256e2D3E95b9D92,false,0,0xe318b52b00000000000000000000000000000000000000000000000000000000000000010000000000000000000000006419f81580343df023e68715c6e269afb00a2cc7000000000000000000000000f1efbdc2c0bdc4554e0f1639d7fe88cd870a4639)]"
```

The resulting calldata:
```
0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000847b5c174615b1b7fdf770882256e2d3e95b9d920000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000064e318b52b00000000000000000000000000000000000000000000000000000000000000010000000000000000000000006419f81580343df023e68715c6e269afb00a2cc7000000000000000000000000f1efbdc2c0bdc4554e0f1639d7fe88cd870a463900000000000000000000000000000000000000000000000000000000
```

# State Validations

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

All non-nonce changes below are to the Safe's [owner linked list](https://github.com/safe-global/safe-contracts/blob/v1.4.1/contracts/libraries/SafeStorage.sol#L15), stored in the `owners` mapping at storage slot `2`. The linked list uses `SENTINEL_ADDRESS` (`0x1`) as both the head and tail marker. Each entry `owners[addr]` points to the next owner in the list. Swapping an owner replaces it in the linked list by updating the pointers of the previous and new owners.

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `60`
  - **After:** `61`
  - **Summary:** Safe nonce increment.
  - **Detail:** The Safe nonce is incremented from 60 to 61 after executing the transaction.

- **Key:**          `0x4da02e22593e67e861d321975341b4e2b27b78ae23b297852caf5e6cc21305cd`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000003041ba32f451f5850c147805f5521ac206421623`
  - **Summary:** `owners[0xf1EfbdC2C0BDC4554E0f1639D7fe88cD870a4639]` is set.
  - **Detail:** Inserts `0xf1EfbdC2C0BDC4554E0f1639D7fe88cD870a4639` into the owner linked list, pointing to `0x3041BA32f451F5850c147805F5521AC206421623` as the next owner (the entry previously pointed to by the removed owner `0x6419F81580343DF023E68715C6e269aFb00a2cc7`). The key can be derived from `cast index address 0xf1EfbdC2C0BDC4554E0f1639D7fe88cD870a4639 2`.

- **Key:**          `0xdfb03bd8491243d20ce5b43e4b9121018531ba11907ab2b808e61a9617b3ff6e`
  - **Before:** `0x0000000000000000000000003041ba32f451f5850c147805f5521ac206421623`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Summary:** `owners[0x6419F81580343DF023E68715C6e269aFb00a2cc7]` is zeroed out.
  - **Detail:** Removes `0x6419F81580343DF023E68715C6e269aFb00a2cc7` from the owner linked list. Previously pointed to `0x3041BA32f451F5850c147805F5521AC206421623`. The key can be derived from `cast index address 0x6419F81580343DF023E68715C6e269aFb00a2cc7 2`.

- **Key:**          `0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0`
  - **Before:** `0x0000000000000000000000006419f81580343df023e68715c6e269afb00a2cc7`
  - **After:** `0x000000000000000000000000f1efbdc2c0bdc4554e0f1639d7fe88cd870a4639`
  - **Summary:** `owners[SENTINEL(0x1)]` updated.
  - **Detail:** Updates the head of the owner linked list: previously pointed to removed owner `0x6419F81580343DF023E68715C6e269aFb00a2cc7`, now points to its replacement `0xf1EfbdC2C0BDC4554E0f1639D7fe88cD870a4639`. The key can be derived from `cast index address 0x0000000000000000000000000000000000000001 2`.
