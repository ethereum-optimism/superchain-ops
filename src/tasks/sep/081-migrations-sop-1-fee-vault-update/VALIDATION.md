# Validation

This document can be used to validate the inputs and result of the execution of the upgrade
transaction which you are signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Verifying the transaction input](#understanding-task-calldata)
3. [Verifying the state changes](#task-state-changes)

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the
values on your ledger and the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Migrations-sop-1 1/1 Safe (`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`)
>
> - Domain Hash:  `<TBD_DOMAIN_HASH>`
> - Message Hash: `<TBD_MESSAGE_HASH>`

## Understanding Task Calldata

The task calls `depositTransaction` on the `migrations-sop-1` `OptimismPortal`
(`0xE257b9bf8Ca550B3595978c86d0A358ca4132731`) three times, each targeting the L2
`ProxyAdmin` (`0x4200000000000000000000000000000000000018`) to upgrade one fee vault proxy.

**Call 1 — Upgrade SequencerFeeVault**
- Portal: `0xE257b9bf8Ca550B3595978c86d0A358ca4132731`
- L2 target: `0x4200000000000000000000000000000000000018` (ProxyAdmin)
- L2 calldata: `ProxyAdmin.upgrade(0x4200000000000000000000000000000000000011, <TBD_SEQ_FEE_VAULT_IMPL>)`

**Call 2 — Upgrade BaseFeeVault**
- Portal: `0xE257b9bf8Ca550B3595978c86d0A358ca4132731`
- L2 target: `0x4200000000000000000000000000000000000018` (ProxyAdmin)
- L2 calldata: `ProxyAdmin.upgrade(0x4200000000000000000000000000000000000019, <TBD_DEFAULT_FEE_VAULT_IMPL>)`

**Call 3 — Upgrade L1FeeVault**
- Portal: `0xE257b9bf8Ca550B3595978c86d0A358ca4132731`
- L2 target: `0x4200000000000000000000000000000000000018` (ProxyAdmin)
- L2 calldata: `ProxyAdmin.upgrade(0x420000000000000000000000000000000000001A, <TBD_DEFAULT_FEE_VAULT_IMPL>)`

### Task Calldata

```
<TBD_CALLDATA>
```

## Task State Changes

### L1 State Changes

The ProxyAdminOwner Safe (`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`) nonce increments
by 1 after the transaction executes.

### L2 State Changes (post-deposit relay)

Once the three deposit transactions are included in an L2 block, the following changes
occur on `migrations-sop-1` (chainId 420120110):

- `SequencerFeeVault` (`0x4200000000000000000000000000000000000011`) implementation slot
  updated to `<TBD_SEQ_FEE_VAULT_IMPL>`
- `BaseFeeVault` (`0x4200000000000000000000000000000000000019`) implementation slot
  updated to `<TBD_DEFAULT_FEE_VAULT_IMPL>`
- `L1FeeVault` (`0x420000000000000000000000000000000000001A`) implementation slot
  updated to `<TBD_DEFAULT_FEE_VAULT_IMPL>`

### Verify pre-deployed implementations on L2

Verify the implementations are deployed on `migrations-sop-1` before signing:

```bash
# Check SequencerFeeVault implementation has code
cast code <TBD_SEQ_FEE_VAULT_IMPL> --rpc-url <MIGRATIONS_SOP_1_L2_RPC>

# Check BaseFeeVault / L1FeeVault implementation has code
cast code <TBD_DEFAULT_FEE_VAULT_IMPL> --rpc-url <MIGRATIONS_SOP_1_L2_RPC>

# Check RECIPIENT() on each new impl matches the OP fee recipients
cast call <TBD_SEQ_FEE_VAULT_IMPL> "RECIPIENT()(address)" --rpc-url <MIGRATIONS_SOP_1_L2_RPC>
# Expected: 0xced11d52f2262d51a1f05ef483e5fd24619ad130

cast call <TBD_DEFAULT_FEE_VAULT_IMPL> "RECIPIENT()(address)" --rpc-url <MIGRATIONS_SOP_1_L2_RPC>
# Expected: 0xde7d944a4b6314bbb9da10f89c6a685c2465cfa0 (baseFee) — if a separate impl is used for l1Fee, document accordingly
```

### Post-execution L2 verification

```bash
cast call 0x4200000000000000000000000000000000000011 "RECIPIENT()(address)" --rpc-url <MIGRATIONS_SOP_1_L2_RPC>
# Expected: 0xced11d52f2262d51a1f05ef483e5fd24619ad130

cast call 0x4200000000000000000000000000000000000019 "RECIPIENT()(address)" --rpc-url <MIGRATIONS_SOP_1_L2_RPC>
# Expected: 0xde7d944a4b6314bbb9da10f89c6a685c2465cfa0

cast call 0x420000000000000000000000000000000000001A "RECIPIENT()(address)" --rpc-url <MIGRATIONS_SOP_1_L2_RPC>
# Expected: 0x1b8dc99ae8142303884eb0e8956007f622279d7e
```
