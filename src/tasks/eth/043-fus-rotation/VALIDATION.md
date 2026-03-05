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
> - Message Hash: `0x05713c62e65436b28fa9ee07eb7a684a64eb7f851b872af392ec907e4bc57f2a`

## Understanding Task Calldata

This document provides a detailed analysis of the final calldata executed on-chain for the signer rotation.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved plan with no unexpected modifications or side effects.

This task rotates 3 signers on the Foundation Upgrade Safe in a single atomic transaction using `Multicall3DelegateCall`.

### Swap 1: `safe.swapOwner()`

- Previous owner: `0x3041ba32f451f5850c147805f5521ac206421623` (calculated by the template)
- Owner to remove: `0xE7dEA1306D9F829bA469d1904c50903b46ebd02e`
- New owner: `0xAAAA000000000000000000000000000000000001`

```bash
cast calldata 'swapOwner(address, address, address)' "0x3041ba32f451f5850c147805f5521ac206421623" "0xE7dEA1306D9F829bA469d1904c50903b46ebd02e" "0xAAAA000000000000000000000000000000000001"
```

### Swap 2: `safe.swapOwner()`

- Previous owner: `0x0000000000000000000000000000000000000001` (SENTINEL, calculated by the template)
- Owner to remove: `0x42d27eEA1AD6e22Af6284F609847CB3Cd56B9c64`
- New owner: `0x6419F81580343DF023E68715C6e269aFb00a2cc7`

```bash
cast calldata 'swapOwner(address, address, address)' "0x0000000000000000000000000000000000000001" "0x42d27eEA1AD6e22Af6284F609847CB3Cd56B9c64" "0x6419F81580343DF023E68715C6e269aFb00a2cc7"
```

### Swap 3: `safe.swapOwner()`

- Previous owner: `0x69acfE2096Dfb8d5A041eF37693553c48d9BFd02` (calculated by the template)
- Owner to remove: `0x9bbFB9919062C29a5eE15aCD93c9D7c3b14d31aa`
- New owner: `0xc222ab08333109243B1f4E2a80e3D0A190714AB5`

```bash
cast calldata 'swapOwner(address, address, address)' "0x69acfE2096Dfb8d5A041eF37693553c48d9BFd02" "0x9bbFB9919062C29a5eE15aCD93c9D7c3b14d31aa" "0xc222ab08333109243B1f4E2a80e3D0A190714AB5"
```

### Inputs to `Multicall3DelegateCall`

The outputs from the three `swapOwner` calls above become the `data` fields in the `Call3Value` structs passed to `Multicall3DelegateCall.aggregate3Value()`.

Each Call3Value struct targets the Foundation Upgrade Safe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`) with `allowFailure: false` and `value: 0`.

```bash
cast calldata 'aggregate3Value((address,bool,uint256,bytes)[])' "[(0x847B5c174615B1B7fDF770882256e2D3E95b9D92,false,0,0xe318b52b0000000000000000000000003041ba32f451f5850c147805f5521ac206421623000000000000000000000000e7dea1306d9f829ba469d1904c50903b46ebd02e000000000000000000000000aaaa000000000000000000000000000000000001),(0x847B5c174615B1B7fDF770882256e2D3E95b9D92,false,0,0xe318b52b000000000000000000000000000000000000000000000000000000000000000100000000000000000000000042d27eea1ad6e22af6284f609847cb3cd56b9c640000000000000000000000006419f81580343df023e68715c6e269afb00a2cc7),(0x847B5c174615B1B7fDF770882256e2D3E95b9D92,false,0,0xe318b52b00000000000000000000000069acfe2096dfb8d5a041ef37693553c48d9bfd020000000000000000000000009bbfb9919062c29a5ee15acd93c9d7c3b14d31aa000000000000000000000000c222ab08333109243b1f4e2a80e3d0a190714ab5)]"
```

The resulting calldata:
```
0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000018000000000000000000000000000000000000000000000000000000000000002a0000000000000000000000000847b5c174615b1b7fdf770882256e2d3e95b9d920000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000064e318b52b0000000000000000000000003041ba32f451f5850c147805f5521ac206421623000000000000000000000000e7dea1306d9f829ba469d1904c50903b46ebd02e000000000000000000000000aaaa00000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000847b5c174615b1b7fdf770882256e2d3e95b9d920000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000064e318b52b000000000000000000000000000000000000000000000000000000000000000100000000000000000000000042d27eea1ad6e22af6284f609847cb3cd56b9c640000000000000000000000006419f81580343df023e68715c6e269afb00a2cc700000000000000000000000000000000000000000000000000000000000000000000000000000000847b5c174615b1b7fdf770882256e2d3e95b9d920000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000064e318b52b00000000000000000000000069acfe2096dfb8d5a041ef37693553c48d9bfd020000000000000000000000009bbfb9919062c29a5ee15acd93c9d7c3b14d31aa000000000000000000000000c222ab08333109243b1f4e2a80e3d0a190714ab500000000000000000000000000000000000000000000000000000000
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

All changes below are to the Safe's [owner linked list](https://github.com/safe-global/safe-contracts/blob/v1.4.1/contracts/libraries/SafeStorage.sol#L15), stored in the `owners` mapping at storage slot `2`. The linked list uses `SENTINEL_ADDRESS` (`0x1`) as both the head and tail marker. Each entry `owners[addr]` points to the next owner in the list. Swapping an owner replaces it in the linked list by updating the pointers of the previous and new owners.

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `52`
  - **After:** `53`
  - **Summary:** Safe nonce increment.
  - **Detail:** The Safe nonce is incremented from 52 to 53 after executing the transaction.

- **Key:**          `0x13ec677f4a9eed971f03ee339771a8e9aa6aae22c19be70509b9b68e479cd12e`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Summary:** `owners[0x9bbFB9919062C29a5eE15aCD93c9D7c3b14d31aa]` is zeroed out.
  - **Detail:** Removes `0x9bbFB9919062C29a5eE15aCD93c9D7c3b14d31aa` from the owner linked list. Previously pointed to `SENTINEL` (`0x1`), meaning it was the last owner in the list. The key can be derived from `cast index address 0x9bbFB9919062C29a5eE15aCD93c9D7c3b14d31aa 2`.

- **Key:**          `0x41befc79513309135fea9e29cf3dc5b3f2e7dd563fea514880d5b68569917821`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x000000000000000000000000bf93d4d727f7ba1f753e1124c3e532dcb04ea2c8`
  - **Summary:** `owners[0xAAAA000000000000000000000000000000000001]` is set.
  - **Detail:** Inserts `0xAAAA000000000000000000000000000000000001` into the owner linked list, pointing to `0xBf93D4d727f7Ba1F753E1124c3E532dCb04Ea2c8` as the next owner. The key can be derived from `cast index address 0xAAAA000000000000000000000000000000000001 2`.

- **Key:**          `0x8bcbe19db1c6ea95cbb6cd465f9aae0cae38f3ac205fee1c478d43f0b4c14349`
  - **Before:** `0x000000000000000000000000bf93d4d727f7ba1f753e1124c3e532dcb04ea2c8`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Summary:** `owners[0xE7dEA1306D9F829bA469d1904c50903b46ebd02e]` is zeroed out.
  - **Detail:** Removes `0xE7dEA1306D9F829bA469d1904c50903b46ebd02e` from the owner linked list. Previously pointed to `0xBf93D4d727f7Ba1F753E1124c3E532dCb04Ea2c8`. The key can be derived from `cast index address 0xE7dEA1306D9F829bA469d1904c50903b46ebd02e 2`.

- **Key:**          `0x9703d6838234d2f1ff439fbcbffdd957558269971337a30fc8ea0e7248a5787d`
  - **Before:** `0x000000000000000000000000e7dea1306d9f829ba469d1904c50903b46ebd02e`
  - **After:** `0x000000000000000000000000aaaa000000000000000000000000000000000001`
  - **Summary:** `owners[0x3041ba32f451f5850c147805f5521ac206421623]` updated.
  - **Detail:** Updates the linked list pointer for `0x3041ba32f451f5850c147805f5521ac206421623`: previously pointed to removed owner `0xE7dEA1306D9F829bA469d1904c50903b46ebd02e`, now points to its replacement `0xAAAA000000000000000000000000000000000001`. The key can be derived from `cast index address 0x3041ba32f451f5850c147805f5521ac206421623 2`.

- **Key:**          `0xdfb03bd8491243d20ce5b43e4b9121018531ba11907ab2b808e61a9617b3ff6e`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000003041ba32f451f5850c147805f5521ac206421623`
  - **Summary:** `owners[0x6419F81580343DF023E68715C6e269aFb00a2cc7]` is set.
  - **Detail:** Inserts `0x6419F81580343DF023E68715C6e269aFb00a2cc7` into the owner linked list, pointing to `0x3041ba32f451f5850c147805f5521ac206421623` as the next owner. The key can be derived from `cast index address 0x6419F81580343DF023E68715C6e269aFb00a2cc7 2`.

- **Key:**          `0xe7e3353d68a7e03f4138977d7f45b7462f2b595cbb1e4f173eba484d73d73833`
  - **Before:** `0x0000000000000000000000009bbfb9919062c29a5ee15acd93c9d7c3b14d31aa`
  - **After:** `0x000000000000000000000000c222ab08333109243b1f4e2a80e3d0a190714ab5`
  - **Summary:** `owners[0x69acfE2096Dfb8d5A041eF37693553c48d9BFd02]` updated.
  - **Detail:** Updates the linked list pointer for `0x69acfE2096Dfb8d5A041eF37693553c48d9BFd02`: previously pointed to removed owner `0x9bbFB9919062C29a5eE15aCD93c9D7c3b14d31aa`, now points to its replacement `0xc222ab08333109243B1f4E2a80e3D0A190714AB5`. The key can be derived from `cast index address 0x69acfE2096Dfb8d5A041eF37693553c48d9BFd02 2`.

- **Key:**          `0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0`
  - **Before:** `0x00000000000000000000000042d27eea1ad6e22af6284f609847cb3cd56b9c64`
  - **After:** `0x0000000000000000000000006419f81580343df023e68715c6e269afb00a2cc7`
  - **Summary:** `owners[SENTINEL(0x1)]` updated.
  - **Detail:** Updates the head of the owner linked list: previously pointed to removed owner `0x42d27eEA1AD6e22Af6284F609847CB3Cd56B9c64`, now points to its replacement `0x6419F81580343DF023E68715C6e269aFb00a2cc7`. The key can be derived from `cast index address 0x0000000000000000000000000000000000000001 2`.

- **Key:**          `0xf87408e7441de59b95281769472fc11649ed37d0b7cea54e4d67e7ec9c19ecb8`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** `owners[0xc222ab08333109243B1f4E2a80e3D0A190714AB5]` is set.
  - **Detail:** Inserts `0xc222ab08333109243B1f4E2a80e3D0A190714AB5` into the owner linked list, pointing to `SENTINEL` (`0x1`) as the next entry, making it the last owner in the list. The key can be derived from `cast index address 0xc222ab08333109243B1f4E2a80e3D0A190714AB5 2`.

- **Key:**          `0xf910e665d88aa8ac9ceb7eb15ee995b4540a315cb9e04ad419161ca8aa36d15d`
  - **Before:** `0x0000000000000000000000003041ba32f451f5850c147805f5521ac206421623`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **Summary:** `owners[0x42d27eEA1AD6e22Af6284F609847CB3Cd56B9c64]` is zeroed out.
  - **Detail:** Removes `0x42d27eEA1AD6e22Af6284F609847CB3Cd56B9c64` from the owner linked list. Previously pointed to `0x3041ba32f451f5850c147805f5521ac206421623`. The key can be derived from `cast index address 0x42d27eEA1AD6e22Af6284F609847CB3Cd56B9c64 2`.
