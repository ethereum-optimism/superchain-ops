# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

## State Overrides

The following state overrides should be seen:

### `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (The 2/2 `ProxyAdmin` Owner)

Links:
- [Etherscan](https://etherscan.io/address/0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A)

Overrides:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** Enables the simulation by setting the threshold to 1. The key can be validated by the location of the `threshold` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L14).

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000003` <br/>
  **Meaning:** Sets the nonce to 3 for simulation and signing, since this is the expected nonce of the Safe at the time of execution. The key can be validated by the location of the `nonce` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L17).

### `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03` (Council Safe) or `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (Foundation Safe)

Links:
- [Etherscan (Council Safe)](https://etherscan.io/address/0xc2819DC788505Aac350142A7A707BF9D03E3Bd03). This address is attested to in the [Optimism docs](https://docs.optimism.io/chain/security/privileged-roles#l1-proxy-admin), as it's one of the signers of the L1 Proxy Admin owner.
- [Etherscan (Foundation Safe)](https://etherscan.io/address/0x847B5c174615B1B7fDF770882256e2D3E95b9D92). This address is attested to in the [Optimism docs](https://docs.optimism.io/chain/security/privileged-roles#l1-proxy-admin), as it's one of the signers of the L1 Proxy Admin owner.

The Safe you are signing for will have the following overrides which will set the [Multicall](https://etherscan.io/address/0xca11bde05977b3631167028862be2a173976ca11#code) contract as the sole owner of the signing safe. This allows simulating both the approve hash and the final tx in a single Tenderly tx.

- **Key:** 0x0000000000000000000000000000000000000000000000000000000000000003 <br/>
  **Value:** 0x0000000000000000000000000000000000000000000000000000000000000001 <br/>
  **Meaning:** The number of owners is set to 1. The key can be validated by the location of the `ownerCount` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L13).

- **Key:** 0x0000000000000000000000000000000000000000000000000000000000000004 <br/>
  **Value:** 0x0000000000000000000000000000000000000000000000000000000000000001 <br/>
  **Meaning:** The threshold is set to 1. The key can be validated by the location of the `threshold` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L14).

- **Key:** 0x0000000000000000000000000000000000000000000000000000000000000005 <br/>
  **Value:** 0x0000000000000000000000000000000000000000000000000000000000000003 <br/>
  **Meaning:** Sets the nonce to 3 for simulation and signing, since this is the expected nonce of the Safe at the time of execution. The key can be validated by the location of the `nonce` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L17).

The following two overrides are modifications to the [`owners` mapping](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L12). For the purpose of calculating the storage, note that this mapping is in slot `2`.
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

### `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (The 2/2 `ProxyAdmin` Owner)

State Changes:

- **Key:** 0x0000000000000000000000000000000000000000000000000000000000000005 <br/>
  **Before:** 0x0000000000000000000000000000000000000000000000000000000000000003 <br/>
  **After:** 0x0000000000000000000000000000000000000000000000000000000000000004 <br/>
  **Meaning:** The nonce is increased from 3 to 4. The key can be validated by the location of the `nonce` variable in the [Safe's Storage Layout](https://github.com/safe-global/safe-smart-account/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L17).

#### For the Council:

- **Key:** `0x81e0d4aeef77664a42055404dac0d53d73782f19253d3d4faa4adfb0a05c44ff` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`<br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The GnosisSafe `approvedHashes` mapping is updated to indicate approval of this transaction by the council. The correctness of this slot can be verified as follows:
    - Since this is a nested mapping, we need to use `cast index` twice to confirm that this is the correct slot. The inputs needed are:
      - The location (`8`) of the `approvedHashes` mapping in the [GnosisSafe storage layout](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L20)
      - The address of the Council Safe: `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`
      - The safe hash to approve: `0xdf2a3aeca4b1cd128382510b6c124106e5ee616405a19b1324371a5fa6240289`
    - The using `cast index`, we can verify that:
      ```shell
        $ cast index address 0xc2819DC788505Aac350142A7A707BF9D03E3Bd03 8
        0xaaf2b641eaf0bae063c4f2e5670f905e1fb7334436b902d1d880b05bd6228fbd
        ```
        and
      ```shell
        $ cast index bytes32 0xdf2a3aeca4b1cd128382510b6c124106e5ee616405a19b1324371a5fa6240289 0xaaf2b641eaf0bae063c4f2e5670f905e1fb7334436b902d1d880b05bd6228fbd
        0x81e0d4aeef77664a42055404dac0d53d73782f19253d3d4faa4adfb0a05c44ff
        ```
      And so the output of the second command matches the key above.

#### For the Foundation:

- **Key:** `0x6a15d729bf4b9fb22dcb9ab39059d403e85fffd74d9194df0adece336a38c5f0` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`<br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The GnosisSafe `approvedHashes` mapping is updated to indicate approval of this transaction by the council. The correctness of this slot can be verified as follows:
    - Since this is a nested mapping, we need to use `cast index` twice to confirm that this is the correct slot. The inputs needed are:
      - The location (`8`) of the `approvedHashes` mapping in the [GnosisSafe storage layout](https://github.com/safe-global/safe-contracts/blob/v1.3.0/contracts/examples/libraries/GnosisSafeStorage.sol#L20)
      - The address of the Foundation Safe: `0x847B5c174615B1B7fDF770882256e2D3E95b9D92`
      - The safe hash to approve: `0xdf2a3aeca4b1cd128382510b6c124106e5ee616405a19b1324371a5fa6240289`
    - The using `cast index`, we can verify that:
      ```shell
        $ cast index address 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 8
        0x13908ba1c0e379ab58c6445554ab471f3d4efb06e3c4cf966c4f5e918eca67bd
      ```
      and
      ```shell
        $ cast index bytes32 0xdf2a3aeca4b1cd128382510b6c124106e5ee616405a19b1324371a5fa6240289 0x13908ba1c0e379ab58c6445554ab471f3d4efb06e3c4cf966c4f5e918eca67bd
        0x6a15d729bf4b9fb22dcb9ab39059d403e85fffd74d9194df0adece336a38c5f0
      ```
      And so the output of the second command matches the key above.

### `0x95703e0982140D16f8ebA6d158FccEde42f04a4C` (`SuperchainConfig`)

Links:
- [Etherscan](https://etherscan.io/address/0x95703e0982140D16f8ebA6d158FccEde42f04a4C)

State Changes:

- **Key:** 0xd30e835d3f35624761057ff5b27d558f97bd5be034621e62240e5c0b784abe68<br/>
  **Before:** 0x0000000000000000000000009ba6e03d8b90de867373db8cf1a58d2f7f006b3a<br/>
  **After:** 0x00000000000000000000000009f7150d8c019bef34450d6920f6b3608cefdaf2<br/>
  **Meaning:** The Guardian address has been updated from `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A` (Foundation Operations Safe) to `0x09f7150D8c019BeF34450d6920f6B3608ceFdAf2` (1/1 Safe owned by the Security Council).
    The key is `keccak256("superchainConfig.guardian") - 1` ([ref](https://github.com/ethereum-optimism/optimism/blob/9047beb54c66a5c572784efec8984f259302ec92/packages/contracts-bedrock/src/L1/SuperchainConfig.sol#L23)),
    which can be verified using `cast keccak "superchainConfig.guardian"`, then subtracting 1 from the result.

The only other state changes are two nonce increments:

- One on the Council or Foundation safe (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03` for Council and `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` for Foundation). If this is not decoded, it corresponds to key `0x05` on a `GnosisSafeProxy`.
- One on the owner on the account that sent the transaction.
