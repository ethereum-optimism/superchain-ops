# Validation - Nested Safe

This document describes the generic validation steps for running a Mainnet or Sepolia tasks for the
nested 2/2 Security Council/Foundation Safe.

## State Overrides

The following state overrides related to the nested Safe execution must be seen:

### `GnosisSafeProxy` - the 2/2 `ProxyAdminOwner` Safe

The `ProxyAdminOwner` has the following address:
- Mainnet: [`0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`](https://etherscan.io/address/0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A)
- Sepolia: [`0x1Eb2fFc903729a0F03966B917003800b145F56E2`](https://sepolia.etherscan.io/address/0x1Eb2fFc903729a0F03966B917003800b145F56E2)

These addresses are attested to in the [Optimism Docs](https://docs.optimism.io/chain/security/privileged-roles#addresses).

Enables the simulation by setting the threshold to 1:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  **Meaning:** The threshold is set to 1.

### Security Council Safe or Foundation Safe

Depending on which role (Security Council or Foundation) the task was simulated for,
you must see the following overrides for the following address:
- Mainnet
    - Council Safe: [`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`](https://etherscan.io/address/0xc2819DC788505Aac350142A7A707BF9D03E3Bd03)
    - Foundation Safe: [`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`](https://etherscan.io/address/0x847B5c174615B1B7fDF770882256e2D3E95b9D92)
- Sepolia
    - Council Safe: [`0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`](https://sepolia.etherscan.io/address/0xf64bc17485f0B4Ea5F06A96514182FC4cB561977)
    - Foundation Safe: [`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`](https://sepolia.etherscan.io/address/0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B)

The simulated role will also be called the **Safe Signer** in the remaining document.

These addresses can be verified as the owners of the 2/2 `ProxyAdminOwner` Safe described above.

The Safe Signer will have the following overrides which will set the [Multicall](https://sepolia.etherscan.io/address/0xca11bde05977b3631167028862be2a173976ca11#code) contract as the sole owner of the signing Safe. This allows simulating both the approve hash and the final tx in a single Tenderly tx.

- **Key:** 0x0000000000000000000000000000000000000000000000000000000000000003 <br/>
  **Value:** 0x0000000000000000000000000000000000000000000000000000000000000001 <br/>
  **Meaning:** The number of owners is set to 1.

- **Key:** 0x0000000000000000000000000000000000000000000000000000000000000004 <br/>
  **Value:** 0x0000000000000000000000000000000000000000000000000000000000000001 <br/>
  **Meaning:** The threshold is set to 1.

The following two overrides are modifications to the [`owners` mapping](https://github.com/safe-global/safe-contracts/blob/v1.4.0/contracts/libraries/SafeStorage.sol#L15). For the purpose of calculating the storage, note that this mapping is in slot `2`.
This mapping implements a linked list for iterating through the list of owners. Since we'll only have one owner, `Multicall3` (`0xca11bde05977b3631167028862be2a173976ca11` on [Mainnet](https://etherscan.io/address/0xca11bde05977b3631167028862be2a173976ca11) and [Sepolia](https://sepolia.etherscan.io/address/0xca11bde05977b3631167028862be2a173976ca11)), and the `0x01` address is used as the first and last entry in the linked list, we will see the following overrides:
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

The following state changes related to the nested Safe execution must be seen, either for the
Security Council, or the Foundation Safe, depending on which role the simulation was run for:

### `GnosisSafeProxy` - `approvedHashes` mapping update

- **Key:** _Needs to be computed._ <br/>
  **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`<br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000001` <br/>

#### Key Computation

The GnosisSafe `approvedHashes` mapping is updated to indicate approval of this transaction by the Safe Signer. The correctness of this slot can be verified as follows:
- Since this is a nested mapping, we need to use `cast index` twice to confirm that this is the correct slot. The inputs needed are:
    - The location (`8`) of the `approvedHashes` mapping in the [GnosisSafe storage layout](https://github.com/safe-global/safe-contracts/blob/v1.4.0/contracts/libraries/SafeStorage.sol#L23)
    - The address of the Safe Signer, stored at the env var `$SAFE_SIGNER` in the following cast script command.
    - The safe hash to approve, stored at the env var `$SAFE_HASH` in the following cast script command.
      It's the value after "Nested hash:" in the simulation output logs.
- Then using `cast index`, we can compute the key with
    ```shell
      $ cast index bytes32 $SAFE_HASH $(cast index address $SAFE_SIGNER 8)
    ```
    The output of this command must match the key of the state change.

### Liveness Guard

When the Security Council executes a transaction, the liveness timestamp are updated for each owner that signed the tasks.
This is updating at the moment of the transaction is submitted (`block.timestamp`) into the [`lastLive`](https://github.com/ethereum-optimism/optimism/blob/e84868c27776fd04dc77e95176d55c8f6b1cc9a3/packages/contracts-bedrock/src/safe/LivenessGuard.sol#L41) mapping located at the slot `0`.

### Nonce increments

The only other state changes related to the nested execution are _three_ nonce increments:

- One on the `ProxyAdminOwner` 2/2. If this is not decoded, it corresponds to key `0x05` on a `GnosisSafeProxy`.
- One on the Council or Foundation Safe. If this is not decoded, it corresponds to key `0x05` on a `GnosisSafeProxy`.
- One of the EOA that is the first entry in the owner set of the simulated role.
