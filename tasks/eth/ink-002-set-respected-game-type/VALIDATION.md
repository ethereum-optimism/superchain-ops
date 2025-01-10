# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff
are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

The following state overrides should be seen:

### `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A` (The 2/2 `ProxyAdmin` Owner)

Links:
- [Etherscan](https://etherscan.io/address/0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A)

Overrides:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** Enables the simulation by setting the threshold to 1. The key can be validated by the location of the `threshold` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L14).

## State Changes


###  `0x5d66c1782664115999c47c9fa5cd031f495d3e4f` (`OptimismPortalProxy`)

- **Key**: `0x000000000000000000000000000000000000000000000000000000000000003b` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000006753162b00000001` <br/>
  **After**: `0x00000000000000000000000000000000000000000000000TIMESTAMP00000000`
  **Description**: Sets the `respectedGameType` to `0` (permissionless cannon game) and sets the `respectedGameTypeUpdatedAt` timestamp to the time when the upgrade transaction was executed (this will be a dynamic value).

Additionally, the following nonce changes are present:
- The Foundation safe, `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`, has a nonce increment from 98 to 99
- The address of your account should show a nonce increment
