# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

The following state overrides should be seen:

### `0xE5bd017934F4c00Fa5653857ebE70A1939fBD169` (The Security Council Safe)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0xE5bd017934F4c00Fa5653857ebE70A1939fBD169)

Enables the simulation by setting the threshold to 1:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  **Meaning:** The threshold is set to 1. The key can be validated by the location of the `threshold` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/186a21a74b327f17fc41217a927dea7064f74604/contracts/examples/libraries/GnosisSafeStorage.sol#L14).

## State Changes

### `0xe5bd017934f4c00fa5653857ebe70a1939fbd169` (`GnosisSafe`)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0xe5bd017934f4c00fa5653857ebe70a1939fbd169) (not verified)

**Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
**After:** `0x0000000000000000000000000000000000000000000000000000000000000003` <br/>
**Meaning:** The threshold has been increased to 3. The key can be validated by the location of the `threshold` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/186a21a74b327f17fc41217a927dea7064f74604/contracts/examples/libraries/GnosisSafeStorage.sol#L14). The before value shown is 1, rather than the actual value of 2, because of the state override.

**Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
**After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
**Meaning:** The nonce has been increased to 1. The key can be validated by the location of the `nonce` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/186a21a74b327f17fc41217a927dea7064f74604/contracts/examples/libraries/GnosisSafeStorage.sol#L17).

**Key:** `0x39ead0e6be1167a8c3acf9d6eec70b5b0f4d9e3dc111ef31bd39447081125e31` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
**After:** `0x0000000000000000000000009b3a60522995f90996d97a094878a7529ff00be1` <br/>
**Meaning:** The LivenessModule is inserted into the modules mapping.

**Key:** `0x58efc98e5ba3d3b4ab5f75c89f88f196af75a46acf856be87add4013d6d6b26c` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
**After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
**Meaning:** One of the modules addresses pointing to the sentinel module. TODO expand on this.

**Key:** `0xcc69885fda6bcc1a4ace058b4a62bf5e179ea78fd58a1ccd71c22cc9b688792f` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
**After:** `0x000000000000000000000000999b254d5138d93640a40d7bdd9872a5646d0774` <br/>
**Meaning:** The sentinel module is pointing to one of the modules. TODO expand on this.

**Key:** `0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
**After:** `0x0000000000000000000000008185fa3be4608adfae19537f75a323fe6d464a3d` <br/>
**Meaning:** The Guard address is set. The key can be validated by the key in the [Guard Manager](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/base/GuardManager.sol#L30).
