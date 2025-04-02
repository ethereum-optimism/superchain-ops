# Validation

This document can be used to validate the state diff resulting from the execution of the transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Changes

### `0x837DE453AD5F21E89771e3c06239d8236c0EFd5E` (FoundationOperationsSafe `GnosisSafe`)

- **Key**: 0x0000000000000000000000000000000000000000000000000000000000000003
  **Before**: 0x0000000000000000000000000000000000000000000000000000000000000008
  **After**: 0x000000000000000000000000000000000000000000000000000000000000000a
  **Meaning**: The owner count will increment by **2** to **10**.

- **Key**: 0x0000000000000000000000000000000000000000000000000000000000000004
  **Before**: 0x0000000000000000000000000000000000000000000000000000000000000001
  **After**: 0x0000000000000000000000000000000000000000000000000000000000000002
  **Meaning**: **Only during simulation**, the threshold is set back to **2**. Otherwise, the threshold remain **2**.

- **Key**: 0x0000000000000000000000000000000000000000000000000000000000000005
  **Before**: 0x0000000000000000000000000000000000000000000000000000000000000000
  **After**: 0x0000000000000000000000000000000000000000000000000000000000000001
  **Meaning**: The nonce of the safe will increase from **0** to **1**.

## Owners

The changes of the owners should be as follows below.
This require multiples storage changes because the owners list is represented by a linked list.

- Key: 0x00e6aef00fdbd2b42a717bf8a7596fb523db8d5582c30496b08056c941430612
  Before: 0x0000000000000000000000001084092ac2f04c866806cf3d4a385afa4f6a6c97
  After: 0x0000000000000000000000000000000000000000000000000000000000000000
  Meaning: To remove the address `0xad70ad7ac30cee75eb9638d377eacd8dfdfe0c3c` from the owners list. We now point to `0x0`.

- Key: 0x731ef62987fe322b3f9f4c6aba97f7d530106638c83990f4b62ff43b1f6e60ce
  Before: 0x0000000000000000000000000000000000000000000000000000000000000000
  After: 0x000000000000000000000000f0871b2f75ecd07e2d709b7a2cc0af6848c1ce76
  Meaning: Make the `0x41fb1d8c3262e88a056ee3099f5718405cc8cade` address point to the address `0xf0871b2f75ecd07e2d709b7a2cc0af6848c1ce76` to be part of the linked list.

- Key: 0xa844827b271b29dbac0d7fedb175e5576d2f0566d49e27e314cb0609e727121b
  Before: 0x000000000000000000000000ad70ad7ac30cee75eb9638d377eacd8dfdfe0c3c
  After: 0x00000000000000000000000095e774787a63f145f7b05028a1479bdc9d055f3d
  Meaning: The pointer will now point on 1 new address `0x95e774787a63f145f7b05028a1479bdc9d055f3d` instead of the old address `0xad70ad7ac30cee75eb9638d377eacd8dfdfe0c3c`.

- Key: 0xac7275083894a2bfce66bfe6389c992881b2ca5e5fefd5d284ca2bccb33727ec
  Before: 0x0000000000000000000000000000000000000000000000000000000000000000
  After: 0x00000000000000000000000041fb1d8c3262e88a056ee3099f5718405cc8cade
  Meaning: Make the `0xa03dafade71f1544f4b0120145eec9b89105951f` address point to `0x41fb1d8c3262e88a056ee3099f5718405cc8cade` to be part of the linked list.

- Key: 0xb772eb4066939c7bc71246d020e9ccdefe1aacb8c9340739bed6bb7e7b3faa6a
  Before: 0x0000000000000000000000000000000000000000000000000000000000000000
  After: 0x0000000000000000000000001084092ac2f04c866806cf3d4a385afa4f6a6c97
  Meaning: Make the `0x95e774787a63f145f7b05028a1479bdc9d055f3d` address point to `0x1084092ac2f04c866806cf3d4a385afa4f6a6c97` to be part of the linked list.

- Key: 0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0
  Before: 0x000000000000000000000000f0871b2f75ecd07e2d709b7a2cc0af6848c1ce76
  After: 0x000000000000000000000000a03dafade71f1544f4b0120145eec9b89105951f
  Meaning: Make the `SENTINEL_ADDRESS` point to the address `0xa03dafade71f1544f4b0120145eec9b89105951f` to be part of the linked list.

To precompute the storage location we need to use the `cast index`:

```shell
cast index address 0x0000000000000000000000000000000000000001 2
0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0 // this is the storage of the SENTINEL_ADDRESS pointing to.
```

The address `0x0000000000000000000000000000000000000001` is the `SENTINEL_ADDRESS` and the `2` is the slot of the mapping (address => address).

We can reproduce the same process for the other addresses.
