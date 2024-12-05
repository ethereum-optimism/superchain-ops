# Validation

This document can be used to validate the state diff resulting from the execution of the transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Changes

### `0xc26977310bC89DAee5823C2e2a73195E85382cC7` (`LivenessGuard`)

- **Key**: 0x39099d5c6e8943c9b1cb45b371daa80a1c6571b8d7598c4a1c9aa3aa98a2d715
  **Before**: 0x0000000000000000000000000000000000000000000000000000000066bfc07c
  **After**: 0x0000000000000000000000000000000000000000000000000000000000000000
  **Meaning**: Set the liveness timestamp to `0` of the address `0xad70ad7ac30cee75eb9638d377eacd8dfdfe0c3c`.

- **Key**: 0x469c687eed4a2321c43edddca66a279757c13045315736c5b4aef71e0c60653a
  **Before**: 0x0000000000000000000000000000000000000000000000000000000000000000
  **After**: 0x0000000000000000000000000000000000000000000000000000000067519d75
  **Meaning**: Set the liveness timestamp to the current `block.timestamp` of the address `0x41fb1d8c3262e88a056ee3099f5718405cc8cade`.

- **Key**: 0x56ee16ca3ade18209faccff732edefbb77524a2f2c0c642df2abe4924871e783
  **Before**: 0x0000000000000000000000000000000000000000000000000000000066561b10
  **After**: 0x0000000000000000000000000000000000000000000000000000000000000000
  **Meaning**: Set the liveness timestamp to `0` of the address `0x78339d822c23d943e4a2d4c3dd5408f66e6d662d`.

- **Key**: 0x8b832b208e2b85d2569164b1655368f5b5eddb1c56f6c1acf41053cac08f5141
  **Before**: 0x0000000000000000000000000000000000000000000000000000000066561b10
  **After**: 0x0000000000000000000000000000000000000000000000000000000067519d75
  **Meaning**: [Only during simulation] the address `0x1084092ac2f04c866806cf3d4a385afa4f6a6c97` will be set to the current `block.timestamp` since we are executing the simulation from this address.

- **Key**: 0x918861783ab45836f1fa81ac70d801c660e20fc205429a163129e933eed11b59
  **Before**: 0x0000000000000000000000000000000000000000000000000000000066561b10
  **After**: 0x0000000000000000000000000000000000000000000000000000000000000000
  **Meaning**: Set the liveness timestamp to `0` of the address `0xe09d881a1a13c805ed2c6823f0c7e4443a260f2f`.

- **Key**: 0xa563a25c73689413382dc6229640ac64d0f7adcc900a76d3efa4b407755549c6
  **Before**: 0x0000000000000000000000000000000000000000000000000000000000000000
  **After**: 0x0000000000000000000000000000000000000000000000000000000067519d75
  **Meaning**: Set the liveness timestamp to the current `block.timestamp` of the address `0xa03dafade71f1544f4b0120145eec9b89105951f`.

- **Key**: 0xd9f6815e6bf76c7dcbd38f589dfc2ef8deef1ee9123252314e2e80fcde9f4078
  **Before**: 0x0000000000000000000000000000000000000000000000000000000000000000
  **After**: 0x0000000000000000000000000000000000000000000000000000000067519d75
  **Meaning**: Set the liveness timestamp to the current `block.timestamp` of the address `0x95e774787a63f145f7b05028a1479bdc9d055f3d`.

To precompute the storage location we need to use the `cast index`:

```shell
cast index address 0x1084092ac2f04c866806cf3d4a385afa4f6a6c97 0
0x8b832b208e2b85d2569164b1655368f5b5eddb1c56f6c1acf41053cac08f5141
```

## `0xf64bc17485f0B4Ea5F06A96514182FC4cB561977` (FakeSecurityCouncil `GnosisSafe`)

### Nonces

- **Key**: 0x0000000000000000000000000000000000000000000000000000000000000005
  **Before**: 0x0000000000000000000000000000000000000000000000000000000000000012
  **After**: 0x0000000000000000000000000000000000000000000000000000000000000013
  **Meaning**: The nonce of the safe will increase from **18** to **19**.

### Owners

The changes of the owners should be as follows below.
This require multiples storage changes because the owners list is represented by a linked list.

- Key: 0x00e6aef00fdbd2b42a717bf8a7596fb523db8d5582c30496b08056c941430612
  Before: 0x000000000000000000000000f0871b2f75ecd07e2d709b7a2cc0af6848c1ce76
  After: 0x0000000000000000000000000000000000000000000000000000000000000000
  Meaning: To remove the address `0xad70ad7ac30cee75eb9638d377eacd8dfdfe0c3c` from the owners list. We now point to `0x0`.

- Key: 0x08dff6893f2a37dde66796f17032759252c00a1f4ade9918c4ded35450b8b0de
  Before: 0x00000000000000000000000078339d822c23d943e4a2d4c3dd5408f66e6d662d
  After: 0x000000000000000000000000a03dafade71f1544f4b0120145eec9b89105951f
  Meaning: the pointer will now point on 1 new address `0xa03dafade71f1544f4b0120145eec9b89105951f` instead of the old address `0x78339d822c23d943e4a2d4c3dd5408f66e6d662d`.

- Key: 0x1766faf9c381105993d15464f882a01ed4dc7884a8181f075960bd30c6a9a556
  Before: 0x000000000000000000000000e09d881a1a13c805ed2c6823f0c7e4443a260f2f
  After: 0x00000000000000000000000041fb1d8c3262e88a056ee3099f5718405cc8cade
  Meaning: Make the `0x2e2e33fedd27fdecfc851ae98e45a5ecb76904fe` address point to the address `0x41fb1d8c3262e88a056ee3099f5718405cc8cade` to be part of the linked list.

- Key: 0x6a893420fa61cee16053e747f52b48285baaad2df4457e404b96ef1b39326daa
  Before: 0x0000000000000000000000000000000000000000000000000000000000000001
  After: 0x0000000000000000000000000000000000000000000000000000000000000000
  Meaning: To remove the address `0x78339d822c23d943e4a2d4c3dd5408f66e6d662d` from the owners list, we now point to `0x0`.

- Key: 0x6f61ddabce3d1c468ed3160ef2e2c327f4eae7ae60ddb2356493c3511c00b205
  Before: 0x00000000000000000000000010303fe151a505be8afd23e1d285d3c733bdc721
  After: 0x0000000000000000000000000000000000000000000000000000000000000000
  Meaning: To remove the address `0xe09d881a1a13c805ed2c6823f0c7e4443a260f2f` from the owners list, we now point to `0x0`.

- Key: 0x731ef62987fe322b3f9f4c6aba97f7d530106638c83990f4b62ff43b1f6e60ce
  Before: 0x0000000000000000000000000000000000000000000000000000000000000000
  After: 0x00000000000000000000000010303fe151a505be8afd23e1d285d3c733bdc721
  Meaning: Make the `0x41fb1d8c3262e88a056ee3099f5718405cc8cade` address point to the address `0x10303fe151a505be8afd23e1d285d3c733bdc721` to be part of the linked list.

- Key: 0xa844827b271b29dbac0d7fedb175e5576d2f0566d49e27e314cb0609e727121b
  Before: 0x000000000000000000000000ad70ad7ac30cee75eb9638d377eacd8dfdfe0c3c
  After: 0x00000000000000000000000095e774787a63f145f7b05028a1479bdc9d055f3d
  Meaning: The pointer will now point on 1 new address `0x95e774787a63f145f7b05028a1479bdc9d055f3d` instead of the old address `0xad70ad7ac30cee75eb9638d377eacd8dfdfe0c3c`.

- Key: 0xac7275083894a2bfce66bfe6389c992881b2ca5e5fefd5d284ca2bccb33727ec
  Before: 0x0000000000000000000000000000000000000000000000000000000000000000
  After: 0x0000000000000000000000000000000000000000000000000000000000000001
  Meaning: Make the `0xa03dafade71f1544f4b0120145eec9b89105951f` address point to `SENTINEL_ADDRESS` to be part of the linked list.

- Key: 0xb772eb4066939c7bc71246d020e9ccdefe1aacb8c9340739bed6bb7e7b3faa6a
  Before: 0x0000000000000000000000000000000000000000000000000000000000000000
  After: 0x000000000000000000000000f0871b2f75ecd07e2d709b7a2cc0af6848c1ce76
  Meaning: Make the `0x95e774787a63f145f7b05028a1479bdc9d055f3d` address point to `0xf0871b2f75ecd07e2d709b7a2cc0af6848c1ce76` to be part of the linked list.

To precompute the storage location we need to use the `cast index`:

```shell
cast index address 0x95e774787a63f145f7b05028a1479bdc9d055f3d 2
0xb772eb4066939c7bc71246d020e9ccdefe1aacb8c9340739bed6bb7e7b3faa6a // this is the storage of the 0x95e774787a63f145f7b05028a1479bdc9d055f3d  pointing to.
```

We can reproduce the same process for the other addresses.
