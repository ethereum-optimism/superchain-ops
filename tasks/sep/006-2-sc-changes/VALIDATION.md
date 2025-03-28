# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

The following state overrides should be seen:

### `0xC2Be75506d5724086DEB7245bd260Cc9753911Be` (Superchain Config)

Links:
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/e3004259a4724ad040fe437f219e8e35af391a56/superchain/configs/sepolia/superchain.yaml#L8)
- [Etherscan](https://sepolia.etherscan.io/address/0xC2Be75506d5724086DEB7245bd260Cc9753911Be)

Overrides:

- **Key:** `0xd30e835d3f35624761057ff5b27d558f97bd5be034621e62240e5c0b784abe68` <br/>
  **Value:** `0x0000000000000000000000007a50f00e8d05b95f98fe38d8bee366a7324dcf7e`
  **Meaning:** The Guardian slot of the `SuperchainConfig` is set to the value that it will be set to once [tasks/sep/006-1-guardian-upgrade](../006-1-guardian-upgrade/README.md) is executed. This override will only be present when simulating and signing, not when executing. The slot can be computed as `cast keccak "superchainConfig.guardian"` then subtracting 1 from the result, as seen in the Superchain Config [here](https://github.com/ethereum-optimism/optimism/blob/9047beb54c66a5c572784efec8984f259302ec92/packages/contracts-bedrock/src/L1/SuperchainConfig.sol#L23).

### `0xf64bc17485f0b4ea5f06a96514182fc4cb561977` (Security Council Safe)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0xf64bc17485f0b4ea5f06a96514182fc4cb56197777)

Enables the simulation by setting the threshold to 1:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  **Meaning:** The threshold is set to 1. The key can be validated by the location of the `threshold` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/186a21a74b327f17fc41217a927dea7064f74604/contracts/examples/libraries/GnosisSafeStorage.sol#L14).

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Value:** `0x000000000000000000000000000000000000000000000000000000000000000a`
  **Meaning:** Sets the Safe nonce to the hardcoded value of 10. The key can be validated by the location of the `nonce` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/186a21a74b327f17fc41217a927dea7064f74604/contracts/examples/libraries/GnosisSafeStorage.sol#L17).

## State Changes

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
**After:** `0x0000000000000000000000004220c5ded9dc2c8a8366e684b098094790c72d3c` <br/>
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
**Before:** `0x000000000000000000000000000000000000000000000000000000000000000a` <br/>
**After:** `0x000000000000000000000000000000000000000000000000000000000000000b` <br/>
**Meaning:** The nonce has been increased to 11. The key can be validated by the location of the `nonce` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/186a21a74b327f17fc41217a927dea7064f74604/contracts/examples/libraries/GnosisSafeStorage.sol#L17).

**Key:** `0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
**After:** `0x000000000000000000000000c26977310bc89daee5823c2e2a73195e85382cc7` <br/>
**Meaning:** The `LivenessGuard` address is set to [0xc26977310bC89DAee5823C2e2a73195E85382cC7](https://sepolia.etherscan.io/address/0xc26977310bC89DAee5823C2e2a73195E85382cC7). The key can be validated by the key in the [Guard Manager](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/base/GuardManager.sol#L30).

The following two changes are both updates to the `modules` mapping, which is in [slot 1](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L10).

**Key:** `0x5ebcfc77c53cd2a46ad21b72f1b6a878f7bea47b3baad3c0383053a9361006b8` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
**After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
**Meaning:** The `LivenessModule` at [`0xEB3eF34ACF1a6C1630807495bCC07ED3e7B0177e`](https://sepolia.etherscan.io/address/0xEB3eF34ACF1a6C1630807495bCC07ED3e7B0177e) is now pointing to the sentinel module at `0x01`.
  This is `modules[0xEB3eF34ACF1a6C1630807495bCC07ED3e7B0177e]`, so the key can be
    derived from `cast index address 0xEB3eF34ACF1a6C1630807495bCC07ED3e7B0177e 1`.

**Key:** `0xcc69885fda6bcc1a4ace058b4a62bf5e179ea78fd58a1ccd71c22cc9b688792f` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
**After:** `0x000000000000000000000000eb3ef34acf1a6c1630807495bcc07ed3e7b0177e` <br/>
**Meaning:** The sentinel module (`address(0x01)`) is now pointing to the `LivenessModule` at [`0xEB3eF34ACF1a6C1630807495bCC07ED3e7B0177e`](https://sepolia.etherscan.io/address/0xEB3eF34ACF1a6C1630807495bCC07ED3e7B0177e).
  This is `modules[0x1]`, so the key can be
    derived from `cast index address 0x0000000000000000000000000000000000000001 1`.

The only other state change is a nonce increment for the EOA which sent the transaction.
