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
- [Etherscan (Council Safe)](https://sepolia.etherscan.io/address/0xf64bc17485f0B4Ea5F06A96514182FC4cB561977). This address is attested to the [Optimism docs](https://docs.optimism.io/chain/security/privileged-roles#l1-proxy-admin), as it's one of the signers of the L1 Proxy Admin owner.
- [Etherscan (Foundation Safe)](https://sepolia.etherscan.io/address/0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B). This address is attested to the [Optimism docs](https://docs.optimism.io/chain/security/privileged-roles#l1-proxy-admin), as it's one of the signers of the L1 Proxy Admin owner.

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

### `0x034edD2A225f7f429A63E0f1D2084B9E0A93b538` (`SystemConfigProxy`) for OP Sepolia

- **Key**: `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  **Before**: `0x000000000000000000000000ccdd86d581e40fb5a1c77582247bc493b6c8b169`
  **After**: `0x00000000000000000000000033b83E4C305c908B2Fc181dDa36e230213058d7d`
  **Meaning**: Updates the `SystemConfig` proxy implementation.


### `0x15cd4f6e0CE3B4832B33cB9c6f6Fe6fc246754c2` (`SystemConfigProxy`) for Mode Sepolia

- **Key**: `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  **Before**: `0x000000000000000000000000ba2492e52f45651b60b8b38d4ea5e2390c64ffb1`
  **After**: `0x00000000000000000000000033b83E4C305c908B2Fc181dDa36e230213058d7d`
  **Meaning**: Updates the `SystemConfig` proxy implementation.


### `0x5D63A8Dc2737cE771aa4a6510D063b6Ba2c4f6F2` (`SystemConfigProxy`) for Metal Sepolia

- **Key**: `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  **Before**: `0x000000000000000000000000ba2492e52f45651b60b8b38d4ea5e2390c64ffb1`
  **After**: `0x00000000000000000000000033b83E4C305c908B2Fc181dDa36e230213058d7d`
  **Meaning**: Updates the `SystemConfig` proxy implementation.

### `0xB54c7BFC223058773CF9b739cC5bd4095184Fb08` (`SystemConfigProxy`) for Zora Sepolia

- **Key**: `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
  **Before**: `0x000000000000000000000000ba2492e52f45651b60b8b38d4ea5e2390c64ffb1`
  **After**: `0x00000000000000000000000033b83E4C305c908B2Fc181dDa36e230213058d7d`
  **Meaning**: Updates the `SystemConfig` proxy implementation.

  ### For the Council:

- **Key:** `0x3481a62ac310eecec9b2bcbdfc7f9759c1641b33ec9f302e19c8dc75aa3427bb` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`<br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The GnosisSafe `approvedHashes` mapping is updated to indicate approval of this transaction by the council. The correctness of this slot can be verified as follows:
    - Since this is a nested mapping, we need to use `cast index` twice to confirm that this is the correct slot. The inputs needed are:
      - The location (`8`) of the `approvedHashes` mapping in the [GnosisSafe storage layout](https://github.com/safe-global/safe-contracts/blob/v1.4.0/contracts/libraries/SafeStorage.sol#L23)
      - The address of the Council Safe: `0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`
      - The safe hash to approve: `0x7e8055d58462ab08d75766766252966eda91b23097f8d96aca0547fe7aae078a`
    - The using `cast index`, we can verify that:
      ```shell
        $ cast index address 0xf64bc17485f0B4Ea5F06A96514182FC4cB561977 8
        0x56362ae34e37f50105bd722d564a267a69bbc15ede4cb7136e81afd747b41c4d
        ```
        and
      ```shell
        $ cast index bytes32 0x7e8055d58462ab08d75766766252966eda91b23097f8d96aca0547fe7aae078a 0x56362ae34e37f50105bd722d564a267a69bbc15ede4cb7136e81afd747b41c4d
        0x3481a62ac310eecec9b2bcbdfc7f9759c1641b33ec9f302e19c8dc75aa3427bb
        ```
      And so the output of the second command matches the key above.

### For the Foundation:

- **Key:** `0x66833911cd4988ff9068991368a392dfd91753075a1080eee9ac5b6bf6a4815b` <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`<br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>
  **Meaning:** The GnosisSafe `approvedHashes` mapping is updated to indicate approval of this transaction by the council. The correctness of this slot can be verified as follows:
    - Since this is a nested mapping, we need to use `cast index` twice to confirm that this is the correct slot. The inputs needed are:
      - The location (`8`) of the `approvedHashes` mapping in the [GnosisSafe storage layout](https://github.com/safe-global/safe-contracts/blob/v1.4.0/contracts/libraries/SafeStorage.sol#L23)
      - The address of the Foundation Safe: `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`
      - The safe hash to approve: `0x7e8055d58462ab08d75766766252966eda91b23097f8d96aca0547fe7aae078a`
    - The using `cast index`, we can verify that:
      ```shell
        $ cast index address 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B 8
        0xc18fefc0a6b81265cf06017c3f1f91c040dc3227321d73c608cfbcf1c5253e5c
      ```
      and
      ```shell
        $ cast index bytes32 0x7e8055d58462ab08d75766766252966eda91b23097f8d96aca0547fe7aae078a 0xc18fefc0a6b81265cf06017c3f1f91c040dc3227321d73c608cfbcf1c5253e5c
        0x66833911cd4988ff9068991368a392dfd91753075a1080eee9ac5b6bf6a4815b
      ```
      And so the output of the second command matches the key above.

### Liveness Guard
When the Security Council  (`0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`) execute a transaction, this is updating the liveness timestamp for each owner that signed the tasks.
This is updating at the moment of the transaction is submitted (`block.timestamp`) into the [`lastLive`](https://github.com/ethereum-optimism/optimism/blob/e84868c27776fd04dc77e95176d55c8f6b1cc9a3/packages/contracts-bedrock/src/safe/LivenessGuard.sol#L41) mapping located at the slot `0`.

### Nonce increments

The only other state change are two nonce increments:

- One on the Council or Foundation safe (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B` for Foundation and `0xf64bc17485f0B4Ea5F06A96514182FC4cB561977` for Council). If this is not decoded, it corresponds to key `0x05` on a `GnosisSafeProxy`.
- One on the ProxyAdminOwner (2/2) with address`0x1Eb2fFc903729a0F03966B917003800b145F56E2`.




