# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Changes

### `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B` (Foundation Safe)

- **Key**: `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000017` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000018`<br/>
  **Meaning**: Foundation Safe nonce has incremented by 1.

### `0xF564eEA7960EA244bfEbCBbB17858748606147bf` (`OPContractsManagerProxy`)

- **Key**: `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103` <br/>
  **Before**: `0x000000000000000000000000dee57160aafcf04c34c887b5962d0a69676d3c8b` <br/>
  **After**: `0x000000000000000000000000189abaaaa82dfc015a588a7dbad6f13b1d3485bc` <br/>
  **Meaning**: Updates the `admin` of the `OPContractsManagerPRoxy` contract to be the `ProxyAdmin` for OP Sepolia. Slot key is the keccak hash of `eip1967.proxy.admin` minus 1. Verify that the new owner is correct as per [the OP Sepolia configuration within the superchain-registry repository](https://github.com/ethereum-optimism/superchain-registry/blob/2c96a89df841013a59269fa7adc12c77b870310e/superchain/configs/sepolia/op.toml#L52).
