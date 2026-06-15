# 106-ink-sepolia-fee-vault-update

Status: DRAFT, NOT READY TO SIGN — **blocked** (see [Blockers](#blockers)). The L1 simulation passes (7 portal deposits assembled, 3 deploys + 4 upgrades), **but** the L2 effect reverts while the L2 ProxyAdmin owner is `address(0)`, and the recipients are placeholders. Resolve both blockers, then re-simulate and regenerate the message/safe hashes in [VALIDATION.md](./VALIDATION.md) before signing.

## Objective

Upgrades the four fee-vault predeploys on **Ink Sepolia** (chainId 763373) to new v1.6.0 implementations and re-initializes each with the new (Kraken) recipient. This is cutover step **15** (post-cutover) of the _Ink Sepolia Testnet Migration — Engineering Plan_ ("Update FeeVaults — to Kraken FeeRecipient address").

Each upgrade is an `OptimismPortal2.depositTransaction` (batched through `Multicall3.aggregate3Value`) sending an L1→L2 message to:

1. **CREATE2-deploy** the v1.6.0 impl bytecode on L2 (one for `SequencerFeeVault`, one shared between `BaseFeeVault` & `L1FeeVault`, one for `OperatorFeeVault`).
2. **`ProxyAdmin.upgradeAndCall`** each proxy to the deployed impl, calling `initialize(recipient, minWithdrawal, withdrawalNetwork)`.

Total: **7 portal deposits** in one Safe transaction (3 deploys + 4 upgrades), signed by the L1 ProxyAdminOwner Safe (`0x1Eb2fFc903729a0F03966B917003800b145F56E2`, nested 2-of-2).

## Blockers

> [!CAUTION]
> **This task cannot be signed/executed as-is. Two items must be resolved first.**
>
> **1. Recipients are placeholders.** The Kraken fee recipient(s) for Ink Sepolia are an **open item** in the migration plan (§1 open items; §3.3 "FeeRecipient Owner" is an empty placeholder). The `0xdead…00XX` values in [config.toml](./config.toml) exist only to make the simulated state diff obvious. The current on-chain recipient for all four vaults is the Gelato Safe `0xBeA2Bc852a160B8547273660E22F4F08C2fa9Bbb` on **L2**. Replace the placeholders (and confirm L1-vs-L2 withdrawal network — see below) before signing.
>
> **2. L2 ProxyAdmin has no owner.** Verified on-chain: Ink Sepolia's L2 ProxyAdmin (`0x4200000000000000000000000000000000000018`) `owner()` is `address(0)` (vs. OP Sepolia, which returns the aliased L1PAO). The fee-vault recipient is **immutable** in the live v1.5.0 vaults, so changing it requires a proxy upgrade through the L2 ProxyAdmin. With owner = `0x0`, the `upgradeAndCall` deposits will **relay but revert on L2** — the L1 transaction succeeds while L2 state is unchanged (a silent failure). **Prerequisite:** transfer the L2 ProxyAdmin ownership to the aliased L1PAO (`0x2fc3ffc903729a0f03966b917003800b145f67f3`). This step is **not** in the current migration plan and must be added. Once done, set `l2RpcUrls` in config.toml to re-enable the template's L2 owner pre-flight check.

## State Changes (intended, once blockers are cleared)

State changes land on the **Ink Sepolia L2** (chainId 763373) once the portal deposits are relayed.

| L2 Vault | L2 Predeploy | Current recipient | New recipient (placeholder) |
|----------|--------------|-------------------|------------------------------|
| SequencerFeeVault | `0x4200…0011` | `0xBeA2Bc…9Bbb` (L2) | `0xdead000000000000000000000000000000000011` |
| BaseFeeVault | `0x4200…0019` | `0xBeA2Bc…9Bbb` (L2) | `0xdead000000000000000000000000000000000019` |
| L1FeeVault | `0x4200…001a` | `0xBeA2Bc…9Bbb` (L2) | `0xdead00000000000000000000000000000000001a` |
| OperatorFeeVault | `0x4200…001b` | `0x4200…0019` | `0xdead00000000000000000000000000000000001b` |

Each vault is re-initialized with `minWithdrawalAmount = 0` and `withdrawalNetwork = 0 (L1)`, and its proxy impl slot set to the newly CREATE2-deployed v1.6.0 implementation (deterministic addresses).

> [!IMPORTANT]
> Current Ink Sepolia vaults use `withdrawalNetwork = 1 (L2)` with a **2 ETH** minimum. This task assumes the OPE/migration standard (`L1`, no minimum). Confirm Kraken's preference before signing and update [config.toml](./config.toml) (`networks` / `minWithdrawalAmounts`) if needed.

## Execution order

Migration plan step **15** — run **after** the cutover sequence:
1. (out-of-ops, Gelato) `SystemConfig.transferOwnership` Gelato → OPE (step W26)
2. `104-ink-sepolia-set-batcher-unsafe-signer`
3. `105-ink-sepolia-proposer-rotation`
4. (prerequisite) transfer L2 ProxyAdmin ownership to the aliased L1PAO — see Blocker #2
5. **`106-ink-sepolia-fee-vault-update`** ← this task

## Simulation & Signing

```bash
cd src/tasks/sep/106-ink-sepolia-fee-vault-update
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../justfile simulate
```

> The L1 simulation can pass (depositTransaction only emits events on L1) **even though the L2 effect would revert** while Blocker #2 stands. Do not interpret a green L1 simulation as proof the recipients changed on L2.

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes and the deposit pattern.
