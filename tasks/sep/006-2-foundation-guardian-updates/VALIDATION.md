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
- [Etherscan (Council Safe)](https://sepolia.etherscan.io/address/0xf64bc17485f0B4Ea5F06A96514182FC4cB561977). This address is attested to in the [Optimism docs](https://docs.optimism.io/chain/security/privileged-roles#mitigations).
- [Etherscan (Foundation Safe)](https://sepolia.etherscan.io/address/0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B). This address is attested to in the [Optimism docs](https://docs.optimism.io/chain/security/privileged-roles#mitigations).

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
  **Before:** 0x0000000000000000000000000000000000000000000000000000000000000002 <br/>
  **After:** 0x0000000000000000000000000000000000000000000000000000000000000003 <br/>
The nonce is increased from 2 to 3.

#### For the Council:

- **Key:** `0xac95ca0f85a84ae76de93bc97a507b48cfff5f45f6c547867edf776e555f3ef4` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`<br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The GnosisSafe `approvedHashes` mapping is updated to indicate approval of this transaction by the council. The correctness of this slot can be verified as follows:
    - Since this is a nested mapping, we need to use `cast index` twice to confirm that this is the correct slot. The inputs needed are:
      - The location (`8`) of the `approvedHashes` mapping in the [GnosisSafe storage layout](https://github.com/safe-global/safe-contracts/blob/v1.4.0/contracts/libraries/SafeStorage.sol#L23)
      - The address of the Council Safe: `0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`
      - The safe hash to approve: `0x563a53530afacab3f89ccf6740cfa816de3150d50e9283626e3af00babef3d87`
    - The using `cast index`, we can verify that:
      ```shell
        $ cast index address 0xf64bc17485f0B4Ea5F06A96514182FC4cB561977 8
        0x56362ae34e37f50105bd722d564a267a69bbc15ede4cb7136e81afd747b41c4d
        ```
        and
      ```shell
        $ cast index bytes32 0x563a53530afacab3f89ccf6740cfa816de3150d50e9283626e3af00babef3d87 0x56362ae34e37f50105bd722d564a267a69bbc15ede4cb7136e81afd747b41c4d
        0xac95ca0f85a84ae76de93bc97a507b48cfff5f45f6c547867edf776e555f3ef4
        ```
      And so the output of the second command matches the key above.

#### For the Foundation:

- **Key:** `0x5a2e529e7b2feaedb77a6a1784f400f0d0de9ed9f2c41a0e9adaba3d4fce28a6` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`<br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The GnosisSafe `approvedHashes` mapping is updated to indicate approval of this transaction by the council. The correctness of this slot can be verified as follows:
    - Since this is a nested mapping, we need to use `cast index` twice to confirm that this is the correct slot. The inputs needed are:
      - The location (`8`) of the `approvedHashes` mapping in the [GnosisSafe storage layout](https://github.com/safe-global/safe-contracts/blob/v1.4.0/contracts/libraries/SafeStorage.sol#L23)
      - The address of the Foundation Safe: `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`
      - The safe hash to approve: `0x563a53530afacab3f89ccf6740cfa816de3150d50e9283626e3af00babef3d87`
    - The using `cast index`, we can verify that:
      ```shell
        $ cast index address 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B 8
        0xc18fefc0a6b81265cf06017c3f1f91c040dc3227321d73c608cfbcf1c5253e5c
      ```
      and
      ```shell
        $ cast index bytes32 0x563a53530afacab3f89ccf6740cfa816de3150d50e9283626e3af00babef3d87 0xc18fefc0a6b81265cf06017c3f1f91c040dc3227321d73c608cfbcf1c5253e5c
        0x0e26a6631c2709943281f97fec36e17c5580ad223a9f898224313fa217146846
      ```
      And so the output of the second command matches the key above.

### `0x4416c7Fe250ee49B5a3133146A0BBB8Ec0c6A321` (`LivenessGuard`) (Council Only)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0x4416c7Fe250ee49B5a3133146A0BBB8Ec0c6A321)

State Changes:

- **Key:** 0xee4378be6a15d4c71cb07a5a47d8ddc4aba235142e05cb828bb7141206657e27<br/>
  **Before:** 0x0000000000000000000000000000000000000000000000000000000000000000<br/>
  **After:** 0x00000000000000000000000000000000000000000000000000000000662be90c<br/>
  **Meaning:** This key indicates that the EOA submitting the transaction from the Council owners is an active signer. The key will differ for each signer and can be computed as: `cast index address [yourCouncilSignerAddress] 0`. If you are simulating, `yourCouncilSignerAddress` will be the Multicall `0xca11bde05977b3631167028862be2a173976ca11` address that is used in the state overrides. The after value shown is the timestamp of the transaction or simulation.

### `0xc2be75506d5724086deb7245bd260cc9753911be` (`SuperchainConfig`)

Links:
- [Etherscan](https://sepolia.etherscan.io/address/0xc2be75506d5724086deb7245bd260cc9753911be)

State Changes:

- **Key:** 0xd30e835d3f35624761057ff5b27d558f97bd5be034621e62240e5c0b784abe68<br/>
  **Before:** 0x000000000000000000000000dee57160aafcf04c34c887b5962d0a69676d3c8b<br/>
  **After:** 0x000000000000000000000000f64bc17485f0b4ea5f06a96514182fc4cb561977<br/>
  **Meaning:** The Guardian address has been updated from `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B` (Foundation) to `0xf64bc17485f0B4Ea5F06A96514182FC4cB561977` (Council).
    The key is `keccak256("superchainConfig.guardian") - 1` ([ref](https://github.com/ethereum-optimism/optimism/blob/maur/sepolia-council/packages/contracts-bedrock/src/L1/SuperchainConfig.sol#L23)),
    which can be verified using `cast keccak "superchainConfig.guardian"`, then subtracting 1 from the result.

The only other state change are two nonce increments:

- One on the Council or Foundation safe (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B` for Foundation and `0xf64bc17485f0B4Ea5F06A96514182FC4cB561977` for Council). If this is not decoded, it corresponds to key `0x05` on a `GnosisSafeProxy`.
- One on the owner on the safe that sent the transaction.
