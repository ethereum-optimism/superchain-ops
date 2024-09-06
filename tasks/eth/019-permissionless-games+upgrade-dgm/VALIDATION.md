# Validation

This document can be used to validate the state diff resulting from the execution of resetting the `OptimismPortal` respectedGameType and upgrading the `DeputyGuardianModule`.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

The following state overrides should be seen:

### `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03` (Security Council Safe)

Links:
- [Etherscan](https://etherscan.io/address/0xc2819DC788505Aac350142A7A707BF9D03E3Bd03)

Enables the simulation by setting the threshold to 1:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The threshold is set to 1. The key can be validated by the location of the `threshold` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L14).

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000007`
  **Meaning:** Sets the Safe nonce to the hardcoded value of 7. This is the expected value of the Safe nonce at the time of execution. The key can be validated by the location of the `nonce` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L17).

## State changes

### `0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2` (1/1 Guardian Safe)

Links:
- [Etherscan](https://etherscan.io/address/0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
**Before:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
**After:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
**Meaning:** The nonce has been increased to 4, for `setRespectedGameType`, `disableModule` and `enableModule` operations. The key can be validated by the location of the `nonce` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L17).

- **Key**: `0x122c127b258a6e22748d3f3c38ae3a4c32252b46d3ad49e5d85acb3626c15d39` <br/>
  **Before**: `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After**: `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning**: Sets the `modules` mapping key for the new `DeputyGuardianModule` at [`0xc6901F65369FC59fC1B4D6D6bE7A2318Ff38dB5B`](https://etherscan.io/address/0xc6901F65369FC59fC1B4D6D6bE7A2318Ff38dB5B) to `SENTINEL_MODULES`.
  This is `modules[0xc6901F65369FC59fC1B4D6D6bE7A2318Ff38dB5B]`, so the key can be derived from `cast index address 0xc6901F65369FC59fC1B4D6D6bE7A2318Ff38dB5B 1`.

- **Key:** `0x980c07ea7d4ff68ba3dc1784087a786aa4ab36b4fe0feb273e7b92f4944383de` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **Meaning:** Clears the `modules` mapping key for the old `DeputyGuardianModule` at [`0x5dC91D01290af474CE21DE14c17335a6dEe4d2a8`](https://etherscan.io/address/0x5dC91D01290af474CE21DE14c17335a6dEe4d2a8).
  This is `modules[0x5dC91D01290af474CE21DE14c17335a6dEe4d2a8]`, so the key can be derived from `cast index address 0x5dC91D01290af474CE21DE14c17335a6dEe4d2a8 1`.

- **Key:** `0xcc69885fda6bcc1a4ace058b4a62bf5e179ea78fd58a1ccd71c22cc9b688792f` <br/>
  **Before:** `0x0000000000000000000000005dc91d01290af474ce21de14c17335a6dee4d2a8` <br/>
  **After:** `0x000000000000000000000000c6901f65369fc59fc1b4d6d6be7a2318ff38db5b` <br/>
  **Meaning:** The sentinel module (`address(0x01)`) is now pointing to the `DeputyGuardianModule` at [`0xc6901F65369FC59fC1B4D6D6bE7A2318Ff38dB5B`](https://etherscan.io/address/0xc6901F65369FC59fC1B4D6D6bE7A2318Ff38dB5B).
  This is `modules[0x1]`, so the key can be
    derived from `cast index address 0x0000000000000000000000000000000000000001 1`.

### `0xbEb5Fc579115071764c7423A4f12eDde41f106Ed` (`OptimismPortalProxy`)

State Changes:

- **Key:** `0x000000000000000000000000000000000000000000000000000000000000003b` <br/>
  **Before:** `0x00000000000000000000000000000000000000000000000066bf9c0f00000001` <br/>
  **After:** `0x00000000000000000000000000000000000000000000000066da0dd600000000` <br/>
  **Meaning:** Slot [`0x000000000000000000000000000000000000000000000000000000000000003b`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.6.0-rc.1/packages/contracts-bedrock/snapshots/storageLayout/OptimismPortal2.json#L100C3-L113C5) in the `OptimismPortalProxy` has the following packed layout:

| Offset     | Description                                                  |
| ---------- | ------------------------------------------------------------ |
| `[0, 20)`  | Unused; Should be zero'd out.                                |
| `[20, 28)` | `respectedGameTypeUpdatedAt` timestamp (64 bits, big-endian) |
| `[28, 32)` | `respectedGameType` (32 bits, big-endian)                    |

Note that the offsets in the above table refer to the slot value's big-endian representation. You can compute the offset values with chisel:
```
➜ uint256 x = 0x00000000000000000000000000000000000000000000000066bb70d200000001
➜ uint64 respectedGameTypeUpdatedAt = uint64(x >> 32)
➜ respectedGameTypeUpdatedAt
Type: uint64
├ Hex: 0x
├ Hex (full word): 0x66bb70d2
└ Decimal: 1723560146
➜ uint32 respectedGameType = uint32(x & 0xFFFFFFFF)
➜ respectedGameType
Type: uint32
├ Hex: 0x
├ Hex (full word): 0x1
└ Decimal: 1
```

To verify the diff:

1. Check that the lower 4 bytes equal `0` (`CANNON`) when read as a big-endian 32-bit uint.
1. Check that bytes `[20, 28]` equal the timestamp of the transaction's submission when read as a big-endian 64-bit uint.

### `0x24424336F04440b1c28685a38303aC33C9D14a25` (`LivenessGuard`)

State Changes:

- **Key:** Compute with `cast index address {yourSignerAddress} 0` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000` <br/>
  **After:** `0x000000000000000000000000000000000000000000000000000000006675b61f` <br/>
  **Meaning:** This updates the [`lastLive mapping`](https://github.com/ethereum-optimism/optimism/blob/op-contracts/v1.5.0/packages/contracts-bedrock/src/Safe/LivenessGuard.sol#L36) indicating liveness of an owner that participated in signing. This will be updated to a block timestamp that matches the time when this task was executed. Note that the "before" value may be non-zero for signers that have participated in signing.

### `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03` (Security Council Safe)
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000007` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000008` <br/>
  **Meaning:** The safe nonce increment.
