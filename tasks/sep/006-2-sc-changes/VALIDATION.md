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

### `0x4416c7Fe250ee49B5a3133146A0BBB8Ec0c6A321` (`LivenessGuard`)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0x4416c7Fe250ee49B5a3133146A0BBB8Ec0c6A321)

State Changes:

- **Key:** 0xee4378be6a15d4c71cb07a5a47d8ddc4aba235142e05cb828bb7141206657e27<br/>
  **Before:** 0x0000000000000000000000000000000000000000000000000000000000000000<br/>
  **After:** 0x00000000000000000000000000000000000000000000000000000000662be90c<br/>
  **Meaning:** This key indicates that the EOA submitting the transaction from the Council owners is an active signer. The key will differ for each signer and can be computed as: `cast index address [yourCouncilSignerAddress] 0`. If you are simulating, `yourCouncilSignerAddress` will be the Multicall `0xca11bde05977b3631167028862be2a173976ca11` address that is used in the state overrides. The after value shown is the timestamp of the transaction or simulation.

### `0x7a50f00e8D05b95F98fE38d8BeE366a7324dCf7E` (1/1 Guardian Safe)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0x7a50f00e8D05b95F98fE38d8BeE366a7324dCf7E)

**Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
**After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
**Meaning:** The nonce has been increased to 1. The key can be validated by the location of the `nonce` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/186a21a74b327f17fc41217a927dea7064f74604/contracts/examples/libraries/GnosisSafeStorage.sol#L17).

The following two changes are both updates to the `modules` mapping, which is in [slot 1](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L10).

**Key:** `0x33da99a51c1b688d5178595aac5396d1190fb91dc97bd61605c54cce5a81e8f8` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
**After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
**Meaning:** The `DeputyGuardianModule` at [`0x4220C5deD9dC2C8a8366e684B098094790C72d3c`](https://sepolia.etherscan.io/address/0x4220C5deD9dC2C8a8366e684B098094790C72d3c) is now pointing to the sentinel module at `0x01`.
  This is `modules[0x4220C5deD9dC2C8a8366e684B098094790C72d3c]`, so the key can be
    derived from `cast index address 0x4220C5deD9dC2C8a8366e684B098094790C72d3c 1`.

**Key:** `0xcc69885fda6bcc1a4ace058b4a62bf5e179ea78fd58a1ccd71c22cc9b688792f` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
**After:** `0x0000000000000000000000007df9594b205041ea4917cb047dc20f84dfe297c7` <br/>
**Meaning:** The sentinel module (`address(0x01)`) is now pointing to the `DeputyGuardianModule` at [`0x4220C5deD9dC2C8a8366e684B098094790C72d3c`](https://sepolia.etherscan.io/address/0x4220C5deD9dC2C8a8366e684B098094790C72d3c).
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
**Meaning:** The `LivenessGuard` address is set to [0xc26977310bC89DAee5823C2e2a73195E85382cC7](https://sepolia.etherscan.io/address/0xc26977310bC89DAee5823C2e2a73195E85382cC7). The key can be validated by the key in the [Guard Manager](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/base/GuardManager.sol#L30).

The following two changes are both updates to the `modules` mapping, which is in [slot 1](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L10).

**Key:** `0xcc69885fda6bcc1a4ace058b4a62bf5e179ea78fd58a1ccd71c22cc9b688792f` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
**After:** `0x000000000000000000000000eb3ef34acf1a6c1630807495bcc07ed3e7b0177e` <br/>
**Meaning:** The sentinel module (`address(0x01)`) is now pointing to the `LivenessModule` at [`0xEB3eF34ACF1a6C1630807495bCC07ED3e7B0177e`](https://sepolia.etherscan.io/address/0xEB3eF34ACF1a6C1630807495bCC07ED3e7B0177e).
  This is `modules[0x1]`, so the key can be
    derived from `cast index address 0x0000000000000000000000000000000000000001 1`.

**Key:** `0x5ebcfc77c53cd2a46ad21b72f1b6a878f7bea47b3baad3c0383053a9361006b8` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
**After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
**Meaning:** The `LivenessModule` at [`0xEB3eF34ACF1a6C1630807495bCC07ED3e7B0177e`](https://sepolia.etherscan.io/address/0xEB3eF34ACF1a6C1630807495bCC07ED3e7B0177e) is now pointing to the sentinel module at `0x01`.
  This is `modules[0xEB3eF34ACF1a6C1630807495bCC07ED3e7B0177e]`, so the key can be
    derived from `cast index address 0xEB3eF34ACF1a6C1630807495bCC07ED3e7B0177e 1`.

The only other state change is a nonce increment for the EOA which sent the transaction.
