# 081-migrations-sop-1-fee-vault-update

Status: DRAFT — NOT READY TO SIGN

## Objective

Updates the fee vault recipients on `migrations-sop-1` (chainId 420120110) to OP-controlled addresses. This is Migration Log step **15** (post-cutover).

The three L2 fee vault proxies are upgraded to pre-deployed implementations that have the new recipient baked in as an immutable:

- `SequencerFeeVault` (`0x4200000000000000000000000000000000000011`) → impl `<TBD_SEQ_FEE_VAULT_IMPL>` (RECIPIENT immutable = `0xced11d52f2262d51a1f05ef483e5fd24619ad130` seqFee)
- `BaseFeeVault` (`0x4200000000000000000000000000000000000019`) → impl `<TBD_DEFAULT_FEE_VAULT_IMPL>` (RECIPIENT immutable = `0xde7d944a4b6314bbb9da10f89c6a685c2465cfa0` baseFee)
- `L1FeeVault` (`0x420000000000000000000000000000000000001A`) → impl `<TBD_DEFAULT_FEE_VAULT_IMPL>` (RECIPIENT immutable should be `0x1b8dc99ae8142303884eb0e8956007f622279d7e` l1Fee — deploy a third impl if base/l1 recipients differ)

Each upgrade is performed via a `depositTransaction` call through the `migrations-sop-1` `OptimismPortal` (`0xE257b9bf8Ca550B3595978c86d0A358ca4132731`), sending an L1→L2 upgrade message to the L2 `ProxyAdmin` (`0x4200000000000000000000000000000000000018`).

Signed by the L1 ProxyAdminOwner Safe (`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`).

> [!IMPORTANT]
> The L2 fee-vault implementations must be deployed out-of-band on the L2 BEFORE signing this L1 task. The L1 task only upgrades the L2 proxies to point at them.

## Simulation & Signing

Simulation commands:
```bash
cd src/tasks/sep/081-migrations-sop-1-fee-vault-update
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate
```

Signing commands:
```bash
cd src/tasks/sep/081-migrations-sop-1-fee-vault-update
just --dotenv-path $(pwd)/.env sign
```
