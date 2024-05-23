# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

The following state overrides should be seen:

### `0xf64bc17485f0b4ea5f06a96514182fc4cb561977` (Security Council Safe)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0xf64bc17485f0b4ea5f06a96514182fc4cb56197777)

Enables the simulation by setting the threshold to 1:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  **Meaning:** The threshold is set to 1. The key can be validated by the location of the `threshold` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/186a21a74b327f17fc41217a927dea7064f74604/contracts/examples/libraries/GnosisSafeStorage.sol#L14).

## State Changes

### `0x7a50f00e8D05b95F98fE38d8BeE366a7324dCf7E` (1/1 Guardian Safe)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0x7a50f00e8D05b95F98fE38d8BeE366a7324dCf7E)

**Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
**After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
**Meaning:** The nonce has been increased to 1. The key can be validated by the location of the `nonce` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/186a21a74b327f17fc41217a927dea7064f74604/contracts/examples/libraries/GnosisSafeStorage.sol#L17).

The following two changes are both updates to the `modules` mapping, which is in [slot 1](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L10).

**Key:** `0x17ecfd82d924357693965bec7aa8c5d9a3d70f9cf442f2324ab6a67dde8e93aa` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
**After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
**Meaning:** The `DeputyGuardianModule` at [`0x7dF9594B205041Ea4917cb047Dc20F84dfe297c7`](https://sepolia.etherscan.io/address/0x7dF9594B205041Ea4917cb047Dc20F84dfe297c7) is now pointing to the sentinel module at `0x01`.
  This is `modules[0x7dF9594B205041Ea4917cb047Dc20F84dfe297c7]`, so the key can be
    derived from `cast index address 0x7dF9594B205041Ea4917cb047Dc20F84dfe297c7 1`.

**Key:** `0xcc69885fda6bcc1a4ace058b4a62bf5e179ea78fd58a1ccd71c22cc9b688792f` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
**After:** `0x0000000000000000000000007df9594b205041ea4917cb047dc20f84dfe297c7` <br/>
**Meaning:** The sentinel module (`address(0x01)`) is now pointing to the `DeputyGuardianModule` at [`0x7dF9594B205041Ea4917cb047Dc20F84dfe297c7`](https://sepolia.etherscan.io/address/0x7dF9594B205041Ea4917cb047Dc20F84dfe297c7).
  This is `modules[0x1]`, so the key can be
    derived from `cast index address 0x0000000000000000000000000000000000000001 1`.

### `0xf64bc17485f0b4ea5f06a96514182fc4cb561977` (Security Council Safe)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0xf64bc17485f0b4ea5f06a96514182fc4cb561977)

**Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
**After:** `0x0000000000000000000000000000000000000000000000000000000000000003` <br/>
**Meaning:** The threshold has been increased to 3. The key can be validated by the location of the `threshold` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/186a21a74b327f17fc41217a927dea7064f74604/contracts/examples/libraries/GnosisSafeStorage.sol#L14). The before value shown is 1, rather than the actual value of 2, because of the state override.

**Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000007` <br/>
**After:** `0x0000000000000000000000000000000000000000000000000000000000000008` <br/>
**Meaning:** The nonce has been increased to 8. The key can be validated by the location of the `nonce` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/186a21a74b327f17fc41217a927dea7064f74604/contracts/examples/libraries/GnosisSafeStorage.sol#L17).

**Key:** `0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
**After:** `0x0000000000000000000000004416c7fe250ee49b5a3133146a0bbb8ec0c6a321` <br/>
**Meaning:** The `LivenessGuard` address is set to [0x1A2114e5Ca491b919561cd118279040Ab4a1BA4a](https://sepolia.etherscan.io/address/0x1A2114e5Ca491b919561cd118279040Ab4a1BA4a). The key can be validated by the key in the [Guard Manager](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/base/GuardManager.sol#L30).

The following two changes are both updates to the `modules` mapping, which is in [slot 1](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L10).

**Key:** `0xcc69885fda6bcc1a4ace058b4a62bf5e179ea78fd58a1ccd71c22cc9b688792f` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
**After:** `0x000000000000000000000000e4391ba3911299b7a8c0e361ef763190ce4f6222` <br/>
**Meaning:** The sentinel module (`address(0x01)`) is now pointing to the `LivenessModule` at [`0xe4391Ba3911299b7A8C0e361EF763190Ce4f6222`](https://sepolia.etherscan.io/address/0xe4391Ba3911299b7A8C0e361EF763190Ce4f6222).
  This is `modules[0x1]`, so the key can be
    derived from `cast index address 0x0000000000000000000000000000000000000001 1`.

**Key:** `0xd94b9fe9ff6b9f2bdd33e60c54ffff22143c4794aae3d24091fa3ef8ace26714` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
**After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
**Meaning:** The `LivenessModule` at [`0xe4391Ba3911299b7A8C0e361EF763190Ce4f6222`](https://sepolia.etherscan.io/address/0xe4391Ba3911299b7A8C0e361EF763190Ce4f6222) is now pointing to the sentinel module at `0x01`.
  This is `modules[0xe4391Ba3911299b7A8C0e361EF763190Ce4f6222]`, so the key can be
    derived from `cast index address 0xe4391Ba3911299b7A8C0e361EF763190Ce4f6222 1`.

The only other state change is a nonce increment for the EOA which sent the transaction.
