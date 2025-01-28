# Validaton

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

The following state overrides should be seen:

### `0x837DE453AD5F21E89771e3c06239d8236c0EFd5E` (The Optimism Foundation Operations Safe)

Links:

- [Etherscan](https://sepolia.etherscan.io/address/0x837DE453AD5F21E89771e3c06239d8236c0EFd5E)

Enables the simulation by setting the threshold to 1:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`

## State Changes

### `0x837DE453AD5F21E89771e3c06239d8236c0EFd5E` (The Optimism Foundation Operations Safe)

Links:

- [Etherscan](https://sepolia.etherscan.io/address/0x0fe884546476ddd290ec46318785046ef68a0ba9)

State changes:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`<br/>
  **After:**  `0x0000000000000000000000000000000000000000000000000000000000000002`<br/>
  **Meaning:** The Safe nonce is updated.
- **Key:** `0xd7fc5947853ef89905479c05a14a6f31b6840377e20c6a80d49f7b7b9bb18c44` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`<br/>
  **After:**  `0x0000000000000000000000000000000000000000000000000000000000000001`<br/>
  **Meaning**: Sets the `modules` mapping key for the new `DeputyPauseModule` at [`0x62f3972c56733aB078F0764d2414DfCaa99d574c`](https://sepolia.etherscan.io/address/0xc6f7c07047ba37116a3fdc444afb5018f6df5758) to `SENTINEL_MODULES`.
  This is `modules[0x62f3972c56733aB078F0764d2414DfCaa99d574c]`, so the key can be derived from `cast index address 0x62f3972c56733aB078F0764d2414DfCaa99d574c 1`.
- **Key:** `0xcc69885fda6bcc1a4ace058b4a62bf5e179ea78fd58a1ccd71c22cc9b688792f` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`<br/>
  **After:**  `0x00000000000000000000000062f3972c56733aB078F0764d2414DfCaa99d574c`<br/>
  **Meaning:** The sentinel module (`address(0x01)`) is now pointing to the `DeputyPauseModule` at [`0x62f3972c56733aB078F0764d2414DfCaa99d574c`](https://sepolia.etherscan.io/address/0x62f3972c56733aB078F0764d2414DfCaa99d574c).
  This is `modules[0x1]`, so the key can be
    derived from `cast index address 0x0000000000000000000000000000000000000001 1`.
