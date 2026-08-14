# 066-soneium-fee-vault-recipient-update

Status: READY TO SIGN

## Objective

For **Soneium Mainnet** (chainId 1868), rotate the recipient of **all four L2 fee-vault predeploys** to the new Soneium fee recipient Safe `0x34ffF1A1CB3C054E9eD1BbD36883B14A66E6C260`, and lower the minimum withdrawal amount **10 ETH → 5 ETH** on the three vaults that carry it. Withdrawal networks are untouched (all L2), as is the OperatorFeeVault's zero minimum.

| Vault | Version (live) | Change |
|---|---|---|
| `SequencerFeeVault` `0x4200000000000000000000000000000000000011` | v1.6.1 | recipient `0xF07b3169ffF67A8AECdBb18d9761AEeE34591112` → `0x34ffF1A1CB3C054E9eD1BbD36883B14A66E6C260`; minWithdrawalAmount **10 ETH → 5 ETH** |
| `BaseFeeVault` `0x4200000000000000000000000000000000000019` | v1.6.1 | recipient `0xF07b3169ffF67A8AECdBb18d9761AEeE34591112` → `0x34ffF1A1CB3C054E9eD1BbD36883B14A66E6C260`; minWithdrawalAmount **10 ETH → 5 ETH** |
| `L1FeeVault` `0x420000000000000000000000000000000000001A` | v1.6.1 | recipient `0xF07b3169ffF67A8AECdBb18d9761AEeE34591112` → `0x34ffF1A1CB3C054E9eD1BbD36883B14A66E6C260`; minWithdrawalAmount **10 ETH → 5 ETH** |
| `OperatorFeeVault` `0x420000000000000000000000000000000000001b` | v1.1.1 | recipient `0x4200000000000000000000000000000000000019` (BaseFeeVault) → `0x34ffF1A1CB3C054E9eD1BbD36883B14A66E6C260` (min stays 0, network stays L2) |

**Why 5 ETH:** the value is agreed with the chain operator. It keeps `withdraw()` (permissionless, no automated trigger planned) spam-resistant while making sweeps to the new recipient roughly twice as frequent — and it fits TOML's int64 integer range (max ~9.22e18 wei ≈ 9.22 ETH), which the previous 10 ETH value did not, keeping this a task-only change against the unmodified `SetFeeVaultConfig` template.

Note on `OperatorFeeVault`: today it cascades into the `BaseFeeVault` predeploy (its recipient), so operator fees already reach the chain fee recipient indirectly via a second hop. After this task it pays the new recipient **directly** — the net destination of all four fee streams is identically `0x34ffF1A1CB3C054E9eD1BbD36883B14A66E6C260`.

**Recipient provenance:** `0x34ffF1A1CB3C054E9eD1BbD36883B14A66E6C260` is a **3-of-5 Safe deployed at the same address on both Ethereum L1 and Soneium L2** (verified live 2026-08-13: canonical Safe v1.4.1 singletons — `SafeL2` `0x29fcB43b46531BcA003ddC8FCB67FFE91900C762` on Soneium, `Safe` `0x41675C099F32341bf84BFc5382aF534df5C7461a` on L1 — with identical owner sets and threshold 3). Withdrawals stay on L2, so the Soneium deployment is the one that receives funds; the matching L1 deployment means the same parties control the address even if the withdrawal network is ever flipped to L1 later.

## Mechanism

All four Soneium fee vaults are on the post-Karst (U19, [eth/053](../053-U19-op-ink-mmz-soneium/README.md)) mutable / setter design (Seq/Base/L1 v1.6.1, Operator v1.1.1 — verified live 2026-08-13). Config lives in proxy storage behind owner-gated setters, so this task is an **in-place config update** — no implementation deployments, no proxy upgrades. It is the same `SetFeeVaultConfig` mechanism proven on Ink Mainnet by [eth/062](../062-ink-fee-vault-recipient-update/README.md).

`SetFeeVaultConfig` sends each changed field as an `OptimismPortal2.depositTransaction` from the L1PAO; the deposit's aliased sender (`0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b`, the alias of the L1PAO — verified live as the Soneium L2 ProxyAdmin owner) is exactly the owner the setters authorize against. The template's mandatory pre-flight forks Soneium via `l2RpcUrls` to assert L2 ProxyAdmin ownership, enforce the per-vault version gate (≥ 1.6.0 / ≥ 1.1.0), and dry-run every setter before any signature is collected.

Per-field skip-unchanged yields exactly **7 deposits** (each with a 150,000 L2 gas limit), in `vaultProxies` order with recipient before minimum per vault:

1. `SequencerFeeVault.setRecipient(0x34ffF1A1CB3C054E9eD1BbD36883B14A66E6C260)`
2. `SequencerFeeVault.setMinWithdrawalAmount(5000000000000000000)` (5 ETH)
3. `BaseFeeVault.setRecipient(0x34ffF1A1CB3C054E9eD1BbD36883B14A66E6C260)`
4. `BaseFeeVault.setMinWithdrawalAmount(5000000000000000000)` (5 ETH)
5. `L1FeeVault.setRecipient(0x34ffF1A1CB3C054E9eD1BbD36883B14A66E6C260)`
6. `L1FeeVault.setMinWithdrawalAmount(5000000000000000000)` (5 ETH)
7. `OperatorFeeVault.setRecipient(0x34ffF1A1CB3C054E9eD1BbD36883B14A66E6C260)`

No `setWithdrawalNetwork` deposits are emitted (all four vaults already withdraw on L2), and no `setMinWithdrawalAmount` for the OperatorFeeVault (stays 0). Because the skip set is re-derived from live L2 state on every run, any drift between signing and execution changes the calldata and invalidates all collected signatures (loud revert, full re-sign).

## Simulation & Signing

This is a **nested** task: signers act through one of the L1PAO's two owner safes, so the child-safe argument (`council` or `foundation`) is required.

```bash
cd src/tasks/eth/066-soneium-fee-vault-recipient-update

# Simulate — one command per signer safe (hashes recorded in VALIDATION.md):
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../justfile simulate council
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../justfile simulate foundation

# Sign — with whichever safe you are an owner of (nested signing flow — see docs/NESTED.md):
just --dotenv-path $(pwd)/.env --justfile ../../../justfile sign council
just --dotenv-path $(pwd)/.env --justfile ../../../justfile sign foundation
```

## Post-execution verification

After the seven deposits are relayed on Soneium Mainnet:

```bash
RPC=https://rpc.soneium.org

# Changed by this task — all four recipients:
cast call 0x4200000000000000000000000000000000000011 "recipient()(address)" -r $RPC
cast call 0x4200000000000000000000000000000000000019 "recipient()(address)" -r $RPC
cast call 0x420000000000000000000000000000000000001a "recipient()(address)" -r $RPC
cast call 0x420000000000000000000000000000000000001b "recipient()(address)" -r $RPC
# → each: 0x34ffF1A1CB3C054E9eD1BbD36883B14A66E6C260

# Changed by this task — three minimums (10 ETH → 5 ETH):
cast call 0x4200000000000000000000000000000000000011 "minWithdrawalAmount()(uint256)" -r $RPC # 5000000000000000000
cast call 0x4200000000000000000000000000000000000019 "minWithdrawalAmount()(uint256)" -r $RPC # 5000000000000000000
cast call 0x420000000000000000000000000000000000001a "minWithdrawalAmount()(uint256)" -r $RPC # 5000000000000000000

# Must be UNCHANGED — networks all 1 (L2), OperatorFeeVault min 0:
cast call 0x4200000000000000000000000000000000000011 "withdrawalNetwork()(uint8)" -r $RPC     # 1
cast call 0x4200000000000000000000000000000000000019 "withdrawalNetwork()(uint8)" -r $RPC     # 1
cast call 0x420000000000000000000000000000000000001a "withdrawalNetwork()(uint8)" -r $RPC     # 1
cast call 0x420000000000000000000000000000000000001b "withdrawalNetwork()(uint8)" -r $RPC     # 1
cast call 0x420000000000000000000000000000000000001b "minWithdrawalAmount()(uint256)" -r $RPC # 0
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the calldata breakdown, and the expected state changes.
