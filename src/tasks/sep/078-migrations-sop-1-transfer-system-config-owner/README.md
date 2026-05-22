# 078-migrations-sop-1-transfer-system-config-owner

Status: DRAFT, NOT READY TO SIGN

> Note: this task is **EOA-signed** by the current Partner-EOA `SystemConfig` owner, not via a Safe. See [README.md](#why-this-task-does-not-use-just-simulatesign) below and [VALIDATION.md](./VALIDATION.md) for the calldata fingerprint.

## Objective

Transfers ownership of the `migrations-sop-1` (chainId 420120110) `SystemConfigProxy` from the current Partner EOA to the OPE Admin Safe, per step 1 of the [Chain Migration Log](https://www.notion.so/oplabs/Chain-Migration-Log-367f153ee16280be835deeb764aca44e).

- **Current owner** (signer): `0x2c9b39d22340b8de532ab5c548e0c773da05a487` (Partner EOA)
- **New owner**: `0x8E851F7d8bAeaD95F592847a020cAC7A062dafd9` (OPE Admin Safe on Sepolia)
- **Target**: `SystemConfigProxy` `0xc771958aF69D4fa44deC2555c41c48800Ca1F9Fc`

> [!CAUTION]
> This transfer is **irreversible**. Per the Migration Log, the receiving Safe must be verified by **≥3 OP Labs engineers** before executing.

## Why this task does NOT use `just simulate/sign`

The superchain-ops framework is built around Safe multisig signing. The current `SystemConfig` owner is an **EOA**, not a Safe, so the standard `just simulate` / `just sign` flow does not apply to this step. The framework's `TransferSystemConfigOwnership.sol` template still asserts the structure (current owner == rootSafe, newOwner != current owner) and can be used in a fork simulation, but the actual on-chain execution must be signed by the EOA directly.

## Execution

### 1. Verify the calldata

The transaction calls `SystemConfig.transferOwnership(newOwner)`:

```bash
cast calldata "transferOwnership(address)" 0x8E851F7d8bAeaD95F592847a020cAC7A062dafd9
# Expected: 0xf2fde38b0000000000000000000000008e851f7d8baead95f592847a020cac7a062dafd9
```

### 2. Verify the current owner on-chain

```bash
cast call 0xc771958aF69D4fa44deC2555c41c48800Ca1F9Fc "owner()(address)" --rpc-url <SEPOLIA_RPC>
# Expected: 0x2c9b39d22340b8de532ab5c548e0c773da05a487
```

### 3. Sign and send (EOA)

```bash
cast send \
  --private-key <PARTNER_EOA_PRIVATE_KEY> \
  --rpc-url <SEPOLIA_RPC> \
  0xc771958aF69D4fa44deC2555c41c48800Ca1F9Fc \
  "transferOwnership(address)" \
  0x8E851F7d8bAeaD95F592847a020cAC7A062dafd9
```

If signing from a hardware wallet (Frame, Ledger via Foundry), substitute the appropriate `--ledger` / `--trezor` / `--from` flags.

### 4. Verify the transfer

```bash
cast call 0xc771958aF69D4fa44deC2555c41c48800Ca1F9Fc "owner()(address)" --rpc-url <SEPOLIA_RPC>
# Expected: 0x8E851F7d8bAeaD95F592847a020cAC7A062dafd9
```

Record the tx hash in the [Chain Migration Log](https://www.notion.so/oplabs/Chain-Migration-Log-367f153ee16280be835deeb764aca44e) under "Step 1 — SystemConfig.transferOwnership".

## Validation

See [VALIDATION.md](./VALIDATION.md) for the calldata fingerprint to double-check before signing.
