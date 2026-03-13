# Validation

This document can be used to validate the inputs and result of the execution of the transaction which you are
signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Verifying the transaction input](#understanding-task-calldata)
3. [Verifying the state changes](#task-state-changes)

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Foundation Safe (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`)
>
> - Domain Hash: `0x37e1f5dd3b92a004a23589b741196c8a214629d4ea3a690ec8e41ae45c689cbb`
> - Message Hash: `0x858184d66b6aa635a05ad40afc0a8b43df587ef03d9ba003b80e092e3f23a0c7`
>
> ### Security Council Safe (`0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`)
>
> - Domain Hash: `0xbe081970e9fc104bd1ea27e375cd21ec7bb1eec56bfe43347c3e36c5d27b8533`
> - Message Hash: `0x477ecdbab3464ea12f58b5bd915d8f8af3eb7aabb999ab3dfd01597b51788910`

## Understanding Task Calldata

This document provides a detailed analysis of the calldata executed on-chain for this task.

By reconstructing the calldata, we can confirm that the execution precisely implements the approved
plan with no unexpected modifications or side effects.

This task updates the fee vault recipient for Arena-Z Testnet (Chain ID: 9899) from
`0x9648CF2B93DdBbe120812a567294B2954bCc8568` to `0xE75f598754A552841E65f43197C85028874A96a4`.

New fee vault implementations were pre-deployed on L2 before this task. This task only performs
3 proxy upgrade calls via L1→L2 deposit transactions through the OptimismPortal.

### Structure

The task calls `OptimismPortal.depositTransaction` 3 times, once per fee vault. The superchain-ops
framework batches these into a single L1 transaction by having the PAO Safe `delegatecall`
`Multicall3.aggregate3Value`. Each `depositTransaction` produces an independent L2 deposit
transaction that calls `ProxyAdmin.upgrade` on the L2 ProxyAdmin.

### Call 1 — Upgrade SequencerFeeVault

`OptimismPortal.depositTransaction` on `0x90fdce6efff020605462150cde42257193d1e558`:
- `_to`: `0x4200000000000000000000000000000000000018` (L2 ProxyAdmin)
- `_value`: `0`
- `_gasLimit`: `150000` (`0x249f0`)
- `_isCreation`: `false`
- `_data`: `ProxyAdmin.upgrade(proxy, impl)` where:
  - `proxy` = `0x4200000000000000000000000000000000000011` (SequencerFeeVault)
  - `impl`  = `0x1A4898C391a34E2C38B38A3D2CA4cEbF1BBA783e`

To reconstruct and verify the inner `_data`:
```bash
cast calldata "upgrade(address,address)" \
  "0x4200000000000000000000000000000000000011" \
  "0x1A4898C391a34E2C38B38A3D2CA4cEbF1BBA783e"
```

### Call 2 — Upgrade BaseFeeVault

`OptimismPortal.depositTransaction` on `0x90fdce6efff020605462150cde42257193d1e558`:
- `_to`: `0x4200000000000000000000000000000000000018` (L2 ProxyAdmin)
- `_value`: `0`
- `_gasLimit`: `150000` (`0x249f0`)
- `_isCreation`: `false`
- `_data`: `ProxyAdmin.upgrade(proxy, impl)` where:
  - `proxy` = `0x4200000000000000000000000000000000000019` (BaseFeeVault)
  - `impl`  = `0x8dCC1BbE83752DDB79df32D56B3f37758bBac7AE`

To reconstruct and verify the inner `_data`:
```bash
cast calldata "upgrade(address,address)" \
  "0x4200000000000000000000000000000000000019" \
  "0x8dCC1BbE83752DDB79df32D56B3f37758bBac7AE"
```

### Call 3 — Upgrade L1FeeVault

`OptimismPortal.depositTransaction` on `0x90fdce6efff020605462150cde42257193d1e558`:
- `_to`: `0x4200000000000000000000000000000000000018` (L2 ProxyAdmin)
- `_value`: `0`
- `_gasLimit`: `150000` (`0x249f0`)
- `_isCreation`: `false`
- `_data`: `ProxyAdmin.upgrade(proxy, impl)` where:
  - `proxy` = `0x420000000000000000000000000000000000001a` (L1FeeVault)
  - `impl`  = `0x8dCC1BbE83752DDB79df32D56B3f37758bBac7AE`

To reconstruct and verify the inner `_data`:
```bash
cast calldata "upgrade(address,address)" \
  "0x420000000000000000000000000000000000001a" \
  "0x8dCC1BbE83752DDB79df32D56B3f37758bBac7AE"
```

# State Validations

For each contract listed in the state diff, please verify that no contracts or state changes shown in the Tenderly diff are missing from this document. Additionally, please verify that for each contract:

- The following state changes (and none others) are made to that contract. This validates that no unexpected state
  changes occur.
- All addresses (in section headers and storage values) match the provided name, using the Etherscan and Superchain
  Registry links provided. This validates the bytecode deployed at the addresses contains the correct logic.
- All key values match the semantic meaning provided, which can be validated using the storage layout links provided.

### State Overrides

Note: The changes listed below do not include threshold, nonce and owner mapping overrides. These changes are listed and explained in the [NESTED-VALIDATION.md](../../../../../docs/NESTED-VALIDATION.md) file.

### Task State Changes

### [`0x1Eb2fFc903729a0F03966B917003800b145F56E2`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/arena-z.toml) (ProxyAdminOwner (GnosisSafe)) - Chain ID: 11155420

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `50`
  - **After:** `51`
  - **Summary:** Nonce increment for the ProxyAdminOwner Safe.
  - **Detail:** The Safe nonce is incremented from 50 to 51 after executing the transaction.

> [!IMPORTANT]
> Foundation Only

### [`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/op.toml) (Foundation Safe)

If signer is on Foundation Safe: `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`:

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `70`
  - **After:** `71`
  - **Summary:** Nonce increment for the Foundation Safe.
  - **Detail:** The Foundation Safe nonce is incremented from 70 to 71 after executing the `approveHash` transaction.

- **Key:**          `0xaa3c8148acbb5c2087efc623d842bff799789516b10b4697de61a54590456cc0`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** `approveHash(bytes32)` called on ProxyAdminOwner by Foundation Safe.
  - **Detail:** **THIS WAS CAREFULLY VERIFIED BY RUNBOOK REVIEWERS AND NEED NOT BE CHECKED BY SIGNERS.** This slot change reflects the Foundation Safe calling `approveHash` on the ProxyAdminOwner as part of the nested multisig execution flow. The slot is `approvedHashes[0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B][0x0e707e798a78307aab458f4fc0eeb563b54d67393b9d0e8bdd2b2bcdb018653f]` (mapping at slot 8). To verify:
    - `res=$(cast index address 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B 8)`
    - `cast index bytes32 0x0e707e798a78307aab458f4fc0eeb563b54d67393b9d0e8bdd2b2bcdb018653f $res`

> [!IMPORTANT]
> Security Council Only

### [`0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/op.toml) (Security Council Safe)

If signer is on Security Council Safe: `0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`:

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `65`
  - **After:** `66`
  - **Summary:** Nonce increment for the Security Council Safe.
  - **Detail:** The Security Council Safe nonce is incremented from 65 to 66 after executing the `approveHash` transaction.

- **Key:**          `0xdeaf49abaedbfc1c3d37c1f097d5e8088c8af6afe9ad0e58b2ac919d89ee7aca`
  - **Before:** `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** `approveHash(bytes32)` called on ProxyAdminOwner by Security Council Safe.
  - **Detail:** **THIS WAS CAREFULLY VERIFIED BY RUNBOOK REVIEWERS AND NEED NOT BE CHECKED BY SIGNERS.** This slot change reflects the Security Council Safe calling `approveHash` on the ProxyAdminOwner as part of the nested multisig execution flow. The slot is `approvedHashes[0xf64bc17485f0B4Ea5F06A96514182FC4cB561977][0x0e707e798a78307aab458f4fc0eeb563b54d67393b9d0e8bdd2b2bcdb018653f]` (mapping at slot 8). To verify:
    - `res=$(cast index address 0xf64bc17485f0B4Ea5F06A96514182FC4cB561977 8)`
    - `cast index bytes32 0x0e707e798a78307aab458f4fc0eeb563b54d67393b9d0e8bdd2b2bcdb018653f $res`

> [!IMPORTANT]
> Security Council Only

### [`0xc26977310bC89DAee5823C2e2a73195E85382cC7`](https://github.com/ethereum-optimism/optimism/blob/e84868c27776fd04dc77e95176d55c8f6b1cc9a3/packages/contracts-bedrock/src/safe/LivenessGuard.sol) (LivenessGuard)
**THIS STATE DIFF ONLY APPEARS WHEN SIGNING FOR THE COUNCIL AND DOES NOT NEED TO BE CHECKED BY SIGNERS.**

- **Key:**          `0x8b832b208e2b85d2569164b1655368f5b5eddb1c56f6c1acf41053cac08f5141`
  - **Before:**     `0x0000000000000000000000000000000000000000000000000000000000000000`
  - **After:**      Updated to `block.timestamp` at time of execution.
  - **Summary:**    LivenessGuard timestamp update.
  - **Detail:**     **THIS STATE DIFF ONLY APPEARS WHEN SIGNING FOR THE COUNCIL AND DOES NOT NEED TO BE CHECKED BY SIGNERS.**
                    When the security council safe executes a transaction, the liveness timestamps are updated.
                    This is updating at the moment when the transaction is submitted (`block.timestamp`) into the [`lastLive`](https://github.com/ethereum-optimism/optimism/blob/e84868c27776fd04dc77e95176d55c8f6b1cc9a3/packages/contracts-bedrock/src/safe/LivenessGuard.sol#L41) mapping located at the slot 0.

