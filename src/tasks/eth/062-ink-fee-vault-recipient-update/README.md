# 062-ink-fee-vault-recipient-update

Status: READY TO SIGN

## Objective

For **Ink Mainnet** (chainId 57073), transfer the two cost-covering fee vaults to the OP Enterprise (OPE) **cost recipient**, as a fast follow of the Gelato → OPE rollup-operator migration (_Ink Mainnet Migration — Engineering Plan_ step 15 / W33; target cutover 2026-07-28; **not** on the cutover critical path — the vaults keep accruing to the current recipient until this executes).

| Vault | Version (live) | Change |
|---|---|---|
| `L1FeeVault` `0x420000000000000000000000000000000000001a` | v1.6.1 | recipient `0xa6f0F94C13C4255231958079E7331694205F6c93` → `0x1eB630b2e7409597D462dd5f3D21E305FC56B8C9`; minWithdrawalAmount **2 ETH → 0** (network already L1) |
| `OperatorFeeVault` `0x420000000000000000000000000000000000001b` | v1.1.1 | recipient `0x4200000000000000000000000000000000000019` (BaseFeeVault) → `0x1eB630b2e7409597D462dd5f3D21E305FC56B8C9`; withdrawalNetwork **L2 → L1** (min already 0) |

`SequencerFeeVault` (`0x…0011`) and `BaseFeeVault` (`0x…0019`) are **not** touched — chain-governor revenue stays with the current recipient.

**Cost recipient provenance:** `0x1eB630b2e7409597D462dd5f3D21E305FC56B8C9` is an L1 EOA whose key is managed in Google KMS (key ring `ink-mainnet-0`, key `cost-recipient`). Source of truth: `k8s-netchef-prod` — `manifests/ink-mainnet-0/mn-ink-mainnet-0-op-signer/mn-ink-mainnet-0-op-signer.yaml`, auth entry `mn-ink-mainnet-0-cost-recipient` (chainID 1). It will fund Ink's L1 operating costs (batcher / proposer / challenger top-ups). Note: the address is freshly created and **unused as of 2026-07-21** (nonce 0, balance 0 on L1) — a never-seen address is expected here, and key control must be proven before signing (see below).

## Signing gates — do not sign until ALL are cleared

1. **Template dependency:** `SetFeeVaultConfig` merges via [#1504](https://github.com/ethereum-optimism/superchain-ops/pull/1504) — this task's PR is stacked on it and can only merge after it.
2. **Governance:** the signer is the L1 ProxyAdminOwner (nested 2-of-2: Foundation Upgrade Safe + Security Council), so execution requires the Ink chain-servicer-migration Maintenance Upgrade proposal to clear its optimistic-approval veto window.
3. **Ordering:** the nonce pins in [config.toml](./config.toml) assume `eth/061-ink-proposer-rotation` ([#1490](https://github.com/ethereum-optimism/superchain-ops/pull/1490), signed by the same nested L1PAO) executes first. Re-simulate and regenerate the [VALIDATION.md](./VALIDATION.md) hashes if the ordering changes or any live nonce drifts.
4. **Key-control proof:** before signing, the cost-recipient key holder must demonstrate control of `0x1eB630b2e7409597D462dd5f3D21E305FC56B8C9` (a dust transaction from the address, or a signed message verified against it) — the address has never transacted, and a wrong recipient is only recoverable via another full nested-L1PAO task.

## Mechanism

The Karst hardfork (U19, active on Ink Mainnet since 2026-07-08) upgraded all four fee vaults to the mutable / setter design (Seq/Base/L1 v1.6.1, Operator v1.1.1 — verified live 2026-07-20). Config now lives in proxy storage behind owner-gated setters, so this task is an **in-place config update** — no implementation deployments, no proxy upgrades, and specifically **not** `FeeVaultUpgradeTemplate` (its `upgradeAndCall → initialize` reverts `InvalidInitialization` on Karst-initialized vaults) and **not** `UpdateFeeVaultRecipient` (would downgrade the vaults to immutable implementations).

`SetFeeVaultConfig` sends each changed field as an `OptimismPortal2.depositTransaction` from the L1PAO; the deposit's aliased sender (`0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b`, the alias of the L1PAO — verified live as the Ink L2 ProxyAdmin owner) is exactly the owner the setters authorize against. The template's mandatory pre-flight forks Ink via `l2RpcUrls` to assert L2 ProxyAdmin ownership, enforce the per-vault version gate (≥ 1.6.0 / ≥ 1.1.0; live Ink vaults are 1.6.1 / 1.1.1), and dry-run every setter before any signature is collected.

Per-field skip-unchanged yields exactly **4 deposits** (each with a 150,000 L2 gas limit):

1. `L1FeeVault.setRecipient(0x1eB630b2e7409597D462dd5f3D21E305FC56B8C9)`
2. `L1FeeVault.setMinWithdrawalAmount(0)`
3. `OperatorFeeVault.setRecipient(0x1eB630b2e7409597D462dd5f3D21E305FC56B8C9)`
4. `OperatorFeeVault.setWithdrawalNetwork(WithdrawalNetwork.L1)`

## Simulation & Signing

This is a **nested** task: signers act through one of the L1PAO's two owner safes, so the child-safe argument (`council` or `foundation`) is required.

```bash
cd src/tasks/eth/062-ink-fee-vault-recipient-update

# Simulate — one command per signer safe (hashes recorded in VALIDATION.md):
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../justfile simulate council
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../justfile simulate foundation

# Sign — with whichever safe you are an owner of (nested signing flow — see docs/NESTED.md):
just --dotenv-path $(pwd)/.env --justfile ../../../justfile sign council
just --dotenv-path $(pwd)/.env --justfile ../../../justfile sign foundation
```

## Post-execution verification

After the four deposits are relayed on Ink Mainnet:

```bash
RPC=https://rpc-gel.inkonchain.com
cast call 0x420000000000000000000000000000000000001a "recipient()(address)" -r $RPC
# → 0x1eB630b2e7409597D462dd5f3D21E305FC56B8C9
cast call 0x420000000000000000000000000000000000001b "recipient()(address)" -r $RPC
# → 0x1eB630b2e7409597D462dd5f3D21E305FC56B8C9
cast call 0x420000000000000000000000000000000000001b "withdrawalNetwork()(uint8)" -r $RPC
# → 0 (L1)
cast call 0x420000000000000000000000000000000000001a "minWithdrawalAmount()(uint256)" -r $RPC
# → 0 (was 2000000000000000000)

# Unchanged:
cast call 0x420000000000000000000000000000000000001a "withdrawalNetwork()(uint8)" -r $RPC        # 0
cast call 0x420000000000000000000000000000000000001b "minWithdrawalAmount()(uint256)" -r $RPC   # 0
cast call 0x4200000000000000000000000000000000000011 "recipient()(address)" -r $RPC             # 0xa6f0F94C13C4255231958079E7331694205F6c93
cast call 0x4200000000000000000000000000000000000019 "recipient()(address)" -r $RPC             # 0xa6f0F94C13C4255231958079E7331694205F6c93
```

Record the executed tx hash in the migration plan execution log (step 15 / fee-vault recipient update).

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the calldata breakdown, and the expected state changes.
