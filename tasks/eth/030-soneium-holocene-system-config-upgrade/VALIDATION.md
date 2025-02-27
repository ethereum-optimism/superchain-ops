# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## Expected Domain and Message Hashes

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Optimism Foundation
>
> - Domain Hash: `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0xa6d60aba6b1426cec097593348a9d36ed42ddd1ac52f1b05a5f46a9c0401a11a`
>
> ### Security Council
>
> - Domain Hash: `df53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `089f920bf3a366aa1d63665ae46959257d474c0c75091126db70c8fd4e01c63e`

## State Changes

### `0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3` (`SystemConfigProxy`)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000068`
  **Before**: `0x0000000000000000000000000000000000000000000000000000000002625a00`
  **After**: `0x0000000000000000000000000000000000177fef000026080000000002625a00`
  **Meaning**: Updates the basefeeScalar and blobbasefeeScalar storage variables to 9736 (cast td 0x00002608) and 1540079 (cast td 0x00177fef) respectively. These share a slot with the gasLimit which remains at 40000000 (cast td 0x0000000002625a00).

and

- **Key**: `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  **Before**: `0x000000000000000000000000f56d96b2535b932656d3c04ebf51babff241d886`
  **After**: `0x000000000000000000000000ab9d6cb7a427c0765163a7f45bb91cafe5f2d375`
  **Meaning**: Updates the `SystemConfig` proxy implementation.
