# Validaton

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.



## Expected Domain and Message Hashes

> [!CAUTION]
> Before signing, ensure the below hashes match what is on your ledger.
> ### Optimism Foundation
  Domain Hash:     0xe84ad8db37faa1651b140c17c70e4c48eaa47a635e0db097ddf4ce1cc14b9ecb
  Message Hash:    0x7568016a89da160340bf4ce9379793da5e0573cd09c7c5d38bca8826179e802f


## State Overrides

The following state overrides should be seen:

### `0x837DE453AD5F21E89771e3c06239d8236c0EFd5E` (The Optimism Foundation Operations Safe)

Links:

- [Etherscan](https://sepolia.etherscan.io/address/0x837DE453AD5F21E89771e3c06239d8236c0EFd5E)

Enables the simulation by setting the threshold to 1:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`<br/>
  **Meaning:** Override the nonce with the value of the current nonce of the safe. This is not required by this is present in the current version of the superchain for now and would be fixed in the future upgrade.

## State Changes

### `0x837DE453AD5F21E89771e3c06239d8236c0EFd5E` (The Optimism Foundation Operations Safe)

Links:

- [Etherscan](https://sepolia.etherscan.io/address/0x837DE453AD5F21E89771e3c06239d8236c0EFd5E)

State changes:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`<br/>
  **After:**  `0x0000000000000000000000000000000000000000000000000000000000000002`<br/>
  **Meaning:** The Safe nonce is updated.
- **Key:** `0xd7fc5947853ef89905479c05a14a6f31b6840377e20c6a80d49f7b7b9bb18c44` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`<br/>
  **After:**  `0x0000000000000000000000000000000000000000000000000000000000000001`<br/>
  **Meaning**: Add the [DeputyPauseModule](https://sepolia.etherscan.io/address/0x62f3972c56733aB078F0764d2414DfCaa99d574c#code) `0x62f3972c56733aB078F0764d2414DfCaa99d574c` by *closing* the linked list by the `SENTINEL_MODULES` (0x1). Thus `0x62f3972c56733aB078F0764d2414DfCaa99d574c` -> `0x1`. Key can be derived from `cast index address 0x62f3972c56733aB078F0764d2414DfCaa99d574c 1`.
- **Key:** `0xcc69885fda6bcc1a4ace058b4a62bf5e179ea78fd58a1ccd71c22cc9b688792f` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000001`<br/>
  **After:**  `0x00000000000000000000000062f3972c56733aB078F0764d2414DfCaa99d574c`<br/>
  **Meaning:** The sentinel module (`address(0x01)`) is now pointing to the `DeputyPauseModule` at [`0x62f3972c56733aB078F0764d2414DfCaa99d574c`](https://sepolia.etherscan.io/address/0x62f3972c56733aB078F0764d2414DfCaa99d574c). This is `modules[0x1]`, so the key can be derived from `cast index address 0x0000000000000000000000000000000000000001 1`.
