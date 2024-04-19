# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

The following state overrides should be seen:

### `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B` (The Foundation Safe)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B)

Enables the simulation by setting the threshold to 1:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`

## State Changes

### `0x189abaaaa82dfc015a588a7dbad6f13b1d3485bc` (`ProxyAdmin`)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0x189abaaaa82dfc015a588a7dbad6f13b1d3485bc)

State Changes:

- **_owner:** Updated from `0xdee57160aafcf04c34c887b5962d0a69676d3c8b` (Foundation) to `0xeD3d7D9f610a8ACcBe9CACA172B7F3d70530E89D` (2 of 2 Safe)

### `0xc2be75506d5724086deb7245bd260cc9753911be` (`SuperchainConfig`)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0xc2be75506d5724086deb7245bd260cc9753911be)

State Changes:

- **Key:** 0xd30e835d3f35624761057ff5b27d558f97bd5be034621e62240e5c0b784abe68
  **Before:** 0x000000000000000000000000dee57160aafcf04c34c887b5962d0a69676d3c8b
  **After:** 0x000000000000000000000000a87675ebb9501c7bae8570a431c108c1577478fa
  **Meaning:** The Guardian address has been updated from `0xdee57160aafcf04c34c887b5962d0a69676d3c8b` (Foundation) to `0xa87675ebb9501c7bae8570a431c108c1577478fa` (Council).
    The key is `keccak256("superchainConfig.guardian") - 1` ([ref](https://github.com/ethereum-optimism/optimism/blob/maur/sepolia-council/packages/contracts-bedrock/src/L1/SuperchainConfig.sol#L23)),
    which can be verified using `cast keccak "superchainConfig.guardian"`.

### `0xdee57160aafcf04c34c887b5962d0a69676d3c8b` (`GnosisSafe`)

State Changes:

- **Key:** 0x0000000000000000000000000000000000000000000000000000000000000005
  **Before:** 0x000000000000000000000000000000000000000000000000000000000000000a
  **After:** 0x000000000000000000000000000000000000000000000000000000000000000b
The nonce is increased from `0xa` (decimal 10) to `0xb` (decimal 11).


The only other state change is a nonce increment of the owner on the safe that sent the transaction.
