# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

The following state overrides should be seen:

### `0xf64bc17485f0b4ea5f06a96514182fc4cb561977` (The Security Council Safe)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0xf64bc17485f0b4ea5f06a96514182fc4cb56197777)

Enables the simulation by setting the threshold to 1:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  **Meaning:** The threshold is set to 1. The key can be validated by the location of the `threshold` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/186a21a74b327f17fc41217a927dea7064f74604/contracts/examples/libraries/GnosisSafeStorage.sol#L14).

## State Changes

### `0xf64bc17485f0b4ea5f06a96514182fc4cb561977` (`GnosisSafe`)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0xf64bc17485f0b4ea5f06a96514182fc4cb561977)

**Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
**After:** `0x0000000000000000000000000000000000000000000000000000000000000003` <br/>
**Meaning:** The threshold has been increased to 3. The key can be validated by the location of the `threshold` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/186a21a74b327f17fc41217a927dea7064f74604/contracts/examples/libraries/GnosisSafeStorage.sol#L14). The before value shown is 1, rather than the actual value of 2, because of the state override.

**Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000002` <br/>
**After:** `0x0000000000000000000000000000000000000000000000000000000000000003` <br/>
**Meaning:** The nonce has been increased to 1. The key can be validated by the location of the `nonce` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/186a21a74b327f17fc41217a927dea7064f74604/contracts/examples/libraries/GnosisSafeStorage.sol#L17).

**Key:** `0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
**After:** `0x0000000000000000000000004416c7fe250ee49b5a3133146a0bbb8ec0c6a321` <br/>
**Meaning:** The `LivenessGuard` address is set to [0x4416c7fe250ee49b5a3133146a0bbb8ec0c6a321](https://sepolia.etherscan.io/address/0x4416c7fe250ee49b5a3133146a0bbb8ec0c6a321). The key can be validated by the key in the [Guard Manager](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/base/GuardManager.sol#L30).

The following three changes are all updates to the `modules` mapping, which is in the [1-th slot](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L10).

**Key:** `0xacbf9592ae4032ad5c93b5c8322c5e0fca1cc9ae67f551dee5a8b6f78041eabf` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
**After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
**Meaning:** The `LivenessModule` at `0x812b1fa86be61a787705c49fc0fb05ef50c8fedf` is now pointing to the sentinel module at `0x01`.
  This is `modules[0x812b1fa86be61a787705c49fc0fb05ef50c8fedf]`, so the key can be
    derived from `cast index address 0x812b1fa86be61a787705c49fc0fb05ef50c8fedf 1`.

**Key:** `0xcc69885fda6bcc1a4ace058b4a62bf5e179ea78fd58a1ccd71c22cc9b688792f` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
**After:** `0x000000000000000000000000ed12261735ad411a40ea092ff4701a962d25ca21` <br/>
**Meaning:** The sentinel module (`address(0x01)`) is now pointing to the `DeputyGuardianModule` at [0xed12261735aD411A40Ea092FF4701a962d25cA21](https://sepolia.etherscan.io/address/0xed12261735aD411A40Ea092FF4701a962d25cA21).
  This is `modules[0x1]`, so the key can be
    derived from `cast index address 0x0000000000000000000000000000000000000001 1`.

**Key:** `0xfa5b7c957b60505335b308d4cb1897b38d70b1c1ed76638190c5511b8707ee1b` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
**After:** `0x000000000000000000000000812b1fa86be61a787705c49fc0fb05ef50c8fedf` <br/>
**Meaning:** The `DeputyGuardianModule` at `0xed12261735aD411A40Ea092FF4701a962d25cA21` is now pointing to the `LivenessModule` at [0x812b1fa86be61a787705c49fc0fb05ef50c8fedf](https://sepolia.etherscan.io/address/0x812b1fa86be61a787705c49fc0fb05ef50c8fedf).
  This is `modules[0xed12261735aD411A40Ea092FF4701a962d25cA21]`, so the key can be
    derived from `cast index address 0xed12261735aD411A40Ea092FF4701a962d25cA21 1`.
