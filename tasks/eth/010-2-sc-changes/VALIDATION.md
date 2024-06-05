# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

The following state overrides should be seen:

### `0x95703e0982140d16f8eba6d158fccede42f04a4c` (Superchain Config)

Links:
- [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry/blob/e3004259a4724ad040fe437f219e8e35af391a56/superchain/configs/mainnet/superchain.yaml#L8)
- [Etherscan](https://etherscan.io/address/0x95703e0982140d16f8eba6d158fccede42f04a4c)

Overrides:

- **Key:** `0xd30e835d3f35624761057ff5b27d558f97bd5be034621e62240e5c0b784abe68` <br/>
  **Value:** `0x00000000000000000000000009f7150d8c019bef34450d6920f6b3608cefdaf2` <br/>
  **Meaning:** The Guardian slot of the `SuperchainConfig` is set to the value that it will be set to once [tasks/eth/010-1-guardian-upgrade](../010-1-guardian-upgrade/README.md) is executed. This override will only be present when simulating and signing, not when executing. The slot can be computed as `cast keccak "superchainConfig.guardian"` then subtracting 1 from the result, as seen in the Superchain Config [here](https://github.com/ethereum-optimism/optimism/blob/9047beb54c66a5c572784efec8984f259302ec92/packages/contracts-bedrock/src/L1/SuperchainConfig.sol#L23).

### `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03` (Security Council Safe)

Links:
- [Etherscan](https://etherscan.io/address/0xc2819DC788505Aac350142A7A707BF9D03E3Bd0377)

Enables the simulation by setting the threshold to 1:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The threshold is set to 1. The key can be validated by the location of the `threshold` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L14).

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000004`
  **Meaning:** Sets the Safe nonce to the hardcoded value of 4. This is the expected value of the Safe nonce at the time of execution. The key can be validated by the location of the `nonce` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L17).

## State Changes

### `0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2` (1/1 Guardian Safe)

Links:
- [Etherscan](https://etherscan.io/address/0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2)

**Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
**After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
**Meaning:** The nonce has been increased to 1. The key can be validated by the location of the `nonce` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L17).

The following two changes are both updates to the `modules` mapping, which is in [slot 1](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L10).

**Key:** `0x980c07ea7d4ff68ba3dc1784087a786aa4ab36b4fe0feb273e7b92f4944383de` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
**After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
**Meaning:** The `DeputyGuardianModule` at [`0x5dC91D01290af474CE21DE14c17335a6dEe4d2a8`](https://etherscan.io/address/0x5dC91D01290af474CE21DE14c17335a6dEe4d2a8) is now pointing to the sentinel module at `0x01`.
  This is `modules[0x5dC91D01290af474CE21DE14c17335a6dEe4d2a8]`, so the key can be
    derived from `cast index address 0x5dC91D01290af474CE21DE14c17335a6dEe4d2a8 1`.

**Key:** `0xcc69885fda6bcc1a4ace058b4a62bf5e179ea78fd58a1ccd71c22cc9b688792f` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
**After:** `0x0000000000000000000000005dc91d01290af474ce21de14c17335a6dee4d2a8` <br/>
**Meaning:** The sentinel module (`address(0x01)`) is now pointing to the `DeputyGuardianModule` at [`0x5dC91D01290af474CE21DE14c17335a6dEe4d2a8`](https://etherscan.io/address/0x5dC91D01290af474CE21DE14c17335a6dEe4d2a8).
  This is `modules[0x1]`, so the key can be
    derived from `cast index address 0x0000000000000000000000000000000000000001 1`.

### `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03` (Security Council Safe)

Links:
- [Etherscan](https://etherscan.io/address/0xc2819DC788505Aac350142A7A707BF9D03E3Bd03)

**Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
**After:** `0x000000000000000000000000000000000000000000000000000000000000000a` <br/>
**Meaning:** The threshold has been increased to 10. The key can be validated by the location of the `threshold` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L14). The before value shown is 1, rather than the actual value of 4, because of the state override.

**Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
**After:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
**Meaning:** The nonce has been increased to 5. The key can be validated by the location of the `nonce` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L17).

**Key:** `0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
**After:** `0x00000000000000000000000024424336f04440b1c28685a38303ac33c9d14a25` <br/>
**Meaning:** The `LivenessGuard` address is set to [0x24424336F04440b1c28685a38303aC33C9D14a25](https://etherscan.io/address/0x24424336F04440b1c28685a38303aC33C9D14a25). The key can be validated by the key in the [Guard Manager](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/base/GuardManager.sol#L30).

The following two changes are both updates to the `modules` mapping, which is in [slot 1](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L10).

**Key:** `0x22cc68d2069e96450932da7f18b2ea603fd6793d379da5b149646d9cc62b355d` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
**After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
**Meaning:** The `LivenessModule` at [`0x0454092516c9A4d636d3CAfA1e82161376C8a748`](https://etherscan.io/address/0x0454092516c9A4d636d3CAfA1e82161376C8a748) is now pointing to the sentinel module at `0x01`.
  This is `modules[0x0454092516c9A4d636d3CAfA1e82161376C8a748]`, so the key can be
    derived from `cast index address 0x0454092516c9A4d636d3CAfA1e82161376C8a748 1`.

**Key:** `0xcc69885fda6bcc1a4ace058b4a62bf5e179ea78fd58a1ccd71c22cc9b688792f` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
**After:** `0x0000000000000000000000000454092516c9a4d636d3cafa1e82161376c8a748` <br/>
**Meaning:** The sentinel module (`address(0x01)`) is now pointing to the `LivenessModule` at [`0x0454092516c9A4d636d3CAfA1e82161376C8a748`](https://etherscan.io/address/0x0454092516c9A4d636d3CAfA1e82161376C8a748).
  This is `modules[0x1]`, so the key can be
    derived from `cast index address 0x0000000000000000000000000000000000000001 1`.

The only other state change is a nonce increment for the EOA which sent the transaction.
