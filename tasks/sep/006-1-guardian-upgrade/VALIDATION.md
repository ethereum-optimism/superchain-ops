# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

The following state overrides should be seen:

### `0x1Eb2fFc903729a0F03966B917003800b145F56E2` (The 2/2 `ProxyAdmin` Owner)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0x1Eb2fFc903729a0F03966B917003800b145F56E2)

Enables the simulation by setting the threshold to 1:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`

### `0xf64bc17485f0B4Ea5F06A96514182FC4cB561977` (Council Safe) or `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B` (Foundation Safe)

Links:
- [Etherscan (Council Safe)](https://sepolia.etherscan.io/address/0xf64bc17485f0B4Ea5F06A96514182FC4cB561977). This address is attested to in the [Optimism docs](https://docs.optimism.io/chain/security/privileged-roles#l1-proxy-admin), as it's one of the signers of the L1 Proxy Admin owner.
- [Etherscan (Foundation Safe)](https://sepolia.etherscan.io/address/0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B). This address is attested to in the [Optimism docs](https://docs.optimism.io/chain/security/privileged-roles#l1-proxy-admin), as it's one of the signers of the L1 Proxy Admin owner.

The Safe you are signing for will have the following overrides which will set the [Multicall](https://sepolia.etherscan.io/address/0xca11bde05977b3631167028862be2a173976ca11#code) contract as the sole owner of the signing safe. This allows simulating both the approve hash and the final tx in a single Tenderly tx.

- **Key:** 0x0000000000000000000000000000000000000000000000000000000000000003 <br/>
  **Value:** 0x0000000000000000000000000000000000000000000000000000000000000001 <br/>
  **Meaning:** The number of owners is set to 1.

- **Key:** 0x0000000000000000000000000000000000000000000000000000000000000004 <br/>
  **Value:** 0x0000000000000000000000000000000000000000000000000000000000000001 <br/>
  **Meaning:** The threshold is set to 1.

The following two overrides are modifications to the [`owners` mapping](https://github.com/safe-global/safe-contracts/blob/v1.4.0/contracts/libraries/SafeStorage.sol#L15). For the purpose of calculating the storage, note that this mapping is in slot `2`.
This mapping implements a linked list for iterating through the list of owners. Since we'll only have one owner (Multicall), and the `0x01` address is used as the first and last entry in the linked list, we will see the following overrides:
- `owners[1] -> 0xca11bde05977b3631167028862be2a173976ca11`
- `owners[0xca11bde05977b3631167028862be2a173976ca11] -> 1`

And we do indeed see these entries:

- **Key:** 0x316a0aac0d94f5824f0b66f5bbe94a8c360a17699a1d3a233aafcf7146e9f11c <br/>
  **Value:** 0x0000000000000000000000000000000000000000000000000000000000000001 <br/>
  **Meaning:** This is `owners[0xca11bde05977b3631167028862be2a173976ca11] -> 1`, so the key can be
    derived from `cast index address 0xca11bde05977b3631167028862be2a173976ca11 2`.

- **Key:** 0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0 <br/>
  **Value:** 0x000000000000000000000000ca11bde05977b3631167028862be2a173976ca11 <br/>
  **Meaning:** This is `owners[1] -> 0xca11bde05977b3631167028862be2a173976ca11`, so the key can be
    derived from `cast index address 0x0000000000000000000000000000000000000001 2`.

## State Changes

### `0x1Eb2fFc903729a0F03966B917003800b145F56E2` (The 2/2 `ProxyAdmin` Owner)

State Changes:

- **Key:** 0x0000000000000000000000000000000000000000000000000000000000000005 <br/>
  **Before:** 0x0000000000000000000000000000000000000000000000000000000000000007 <br/>
  **After:** 0x0000000000000000000000000000000000000000000000000000000000000008 <br/>
  **Meaning:** The nonce is increased from 7 to 8.

#### For the Council:

- **Key:** `0x1bbed5e10c7bba3b6887413996db2f9a940f2032b5feffc5712e963aeeb56763` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`<br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The GnosisSafe `approvedHashes` mapping is updated to indicate approval of this transaction by the council. The correctness of this slot can be verified as follows:
    - Since this is a nested mapping, we need to use `cast index` twice to confirm that this is the correct slot. The inputs needed are:
      - The location (`8`) of the `approvedHashes` mapping in the [GnosisSafe storage layout](https://github.com/safe-global/safe-contracts/blob/v1.4.0/contracts/libraries/SafeStorage.sol#L23)
      - The address of the Council Safe: `0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`
      - The safe hash to approve: `0xedfca432f3badd2831a2436b972ec813df98bf9849ecddf384d23ff70ccc8206`
    - The using `cast index`, we can verify that:
      ```shell
        $ cast index address 0xf64bc17485f0B4Ea5F06A96514182FC4cB561977 8
        0x56362ae34e37f50105bd722d564a267a69bbc15ede4cb7136e81afd747b41c4d
        ```
        and
      ```shell
        $ cast index bytes32 0xedfca432f3badd2831a2436b972ec813df98bf9849ecddf384d23ff70ccc8206 0x56362ae34e37f50105bd722d564a267a69bbc15ede4cb7136e81afd747b41c4d
        0x1bbed5e10c7bba3b6887413996db2f9a940f2032b5feffc5712e963aeeb56763
        ```
      And so the output of the second command matches the key above.

#### For the Foundation:

- **Key:** `0x3586f7df2e6cf61c72cf669a6c5e75aed3055bed7da05829eab7f240c1dab416` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`<br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The GnosisSafe `approvedHashes` mapping is updated to indicate approval of this transaction by the council. The correctness of this slot can be verified as follows:
    - Since this is a nested mapping, we need to use `cast index` twice to confirm that this is the correct slot. The inputs needed are:
      - The location (`8`) of the `approvedHashes` mapping in the [GnosisSafe storage layout](https://github.com/safe-global/safe-contracts/blob/v1.4.0/contracts/libraries/SafeStorage.sol#L23)
      - The address of the Foundation Safe: `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`
      - The safe hash to approve: `0xedfca432f3badd2831a2436b972ec813df98bf9849ecddf384d23ff70ccc8206`
    - The using `cast index`, we can verify that:
      ```shell
        $ cast index address 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B 8
        0xc18fefc0a6b81265cf06017c3f1f91c040dc3227321d73c608cfbcf1c5253e5c
      ```
      and
      ```shell
        $ cast index bytes32 0xedfca432f3badd2831a2436b972ec813df98bf9849ecddf384d23ff70ccc8206 0xc18fefc0a6b81265cf06017c3f1f91c040dc3227321d73c608cfbcf1c5253e5c
        0x3586f7df2e6cf61c72cf669a6c5e75aed3055bed7da05829eab7f240c1dab416
      ```
      And so the output of the second command matches the key above.

### `0xc2be75506d5724086deb7245bd260cc9753911be` (`SuperchainConfig`)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0xc2be75506d5724086deb7245bd260cc9753911be)

State Changes:

- **Key:** 0xd30e835d3f35624761057ff5b27d558f97bd5be034621e62240e5c0b784abe68<br/>
  **Before:** 0x000000000000000000000000dee57160aafcf04c34c887b5962d0a69676d3c8b<br/>
  **After:** 0x0000000000000000000000007a50f00e8D05b95F98fE38d8BeE366a7324dCf7E<br/>
  **Meaning:** The Guardian address has been updated from `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B` (Foundation Upgrades Safe) to `0x7a50f00e8D05b95F98fE38d8BeE366a7324dCf7E` (1/1 Safe owned by the Security Council).
    The key is `keccak256("superchainConfig.guardian") - 1` ([ref](https://github.com/ethereum-optimism/optimism/blob/maur/sepolia-council/packages/contracts-bedrock/src/L1/SuperchainConfig.sol#L23)),
    which can be verified using `cast keccak "superchainConfig.guardian"`, then subtracting 1 from the result.

The only other state changes are two nonce increments:

- One on the Council or Foundation safe (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B` for Foundation and `0xf64bc17485f0B4Ea5F06A96514182FC4cB561977` for Council). If this is not decoded, it corresponds to key `0x05` on a `GnosisSafeProxy`.
- One on the owner on the account that sent the transaction.
