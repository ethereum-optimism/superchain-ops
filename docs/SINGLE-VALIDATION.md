# Validation - Single Safe

This document describes the generic validation steps for running Mainnet or Sepolia tasks for a single safe (ie. one which is not owned by other safes).

## State Overrides

The following state overrides must be present:

### ProxyAdminSafe

The simulated role will also be called the **ProxyAdminSafe** in the remaining document.
The `ProxyAdminOwner` has the following address:

- Sepolia:
  - Unichain: [`0xd363339eE47775888Df411A163c586a8BdEA9dbf`](https://sepolia.etherscan.io/address/0xd363339eE47775888Df411A163c586a8BdEA9dbf)

This address is attested to in the [superchain-registry](https://github.com/ethereum-optimism/superchain-registry/blob/9dc8a7dfb8081291315d0c0ccf871f46c7753b63/superchain/configs/sepolia/unichain.toml#L46).

The following state overrides are necessary to enable the simulation:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000003` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The number of owners is set to 1.
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  **Meaning:** The threshold is set to `1`.
- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Value:** `<current nonce for the safe>` <br/>
  **Meaning:** The nonce is set to `<current nonce for the safe>`. Note: This is only included in the new superchain-ops flow as of 26th March 2025.

The following two overrides are modifications to the [`owners` mapping](https://github.com/safe-global/safe-contracts/blob/v1.4.0/contracts/libraries/SafeStorage.sol#L15). For the purpose of calculating the storage, note that this mapping is in slot `2`.
This mapping implements a linked list for iterating through the list of owners.

Since we'll only have one owner, and the `0x01` address is used as the first and last entry in the linked list, we will see the following overrides. For demonstration purposes, we'll use the `0x1804c8ab1f12e6bbf3894d4083f33e07309d1f38` owner which is used in with`SIMULATE_WITHOUT_LEDGER=1`. If simulating with a different signer address, the first slot below will differ but can be derived using the same method.

- `owners[1] -> 0x1804c8ab1f12e6bbf3894d4083f33e07309d1f38`
- `owners[0x1804c8ab1f12e6bbf3894d4083f33e07309d1f38] -> 1`

And we do indeed see these entries:

- **Key:** `0xd1b0d319c6526317dce66989b393dcfb4435c9a65e399a088b63bbf65d7aee32` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** This is `owners[0x1804c8ab1f12e6bbf3894d4083f33e07309d1f38] -> 1`, so the key can be
  derived from `cast index address 0x1804c8ab1f12e6bbf3894d4083f33e07309d1f38 2`.
- **Key:** `0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0` <br/>
  **Value:** `0x0000000000000000000000000x1804c8ab1f12e6bbf3894d4083f33e07309d1f38` <br/>
  **Meaning:** This is `owners[1] -> 0x1804c8ab1f12e6bbf3894d4083f33e07309d1f38`, so the key can be
  derived from `cast index address 0x0000000000000000000000000000000000000001 2`.

### Nonce increments

The only other state changes related to the nested execution are _three_ nonce increments:

- One increment of the *ProxyAdminSafe* Safe nonce, located as storage slot
  `0x0000000000000000000000000000000000000000000000000000000000000005` on a
  `GnosisSafeProxy`.
- One increment of the **Safe Signer** nonce, located as storage slot
  `0x0000000000000000000000000000000000000000000000000000000000000005` on a
  `GnosisSafeProxy`.
- One increment of the nonce of the EOA that is the first entry in the owner set of the Safe Signer.
