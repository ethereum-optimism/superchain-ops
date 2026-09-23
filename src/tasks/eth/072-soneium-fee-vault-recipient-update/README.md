# 072-soneium-fee-vault-recipient-update

Status: [READY TO SIGN]

## Objective

For **Soneium Mainnet** (chainId 1868), rotate the recipient of **all four L2 fee-vault predeploys** to the new Soneium fee recipient Safe `0x34ffF1A1CB3C054E9eD1BbD36883B14A66E6C260`, and lower the minimum withdrawal amount **10 ETH → 5 ETH** on the three vaults that carry it. Withdrawal networks are untouched (all L2), as is the OperatorFeeVault's zero minimum. This executes the approved [Maintenance Upgrade Proposal: Update Soneium Fee Vaults Recipient](https://gov.optimism.io/t/maintenance-upgrade-proposal-update-soneium-fee-vaults-recipient/10822).

| Vault | Version (live) | Change |
|---|---|---|
| `SequencerFeeVault` `0x4200000000000000000000000000000000000011` | v1.6.1 | recipient `0xF07b3169ffF67A8AECdBb18d9761AEeE34591112` → `0x34ffF1A1CB3C054E9eD1BbD36883B14A66E6C260`; minWithdrawalAmount **10 ETH → 5 ETH** |
| `BaseFeeVault` `0x4200000000000000000000000000000000000019` | v1.6.1 | recipient `0xF07b3169ffF67A8AECdBb18d9761AEeE34591112` → `0x34ffF1A1CB3C054E9eD1BbD36883B14A66E6C260`; minWithdrawalAmount **10 ETH → 5 ETH** |
| `L1FeeVault` `0x420000000000000000000000000000000000001A` | v1.6.1 | recipient `0xF07b3169ffF67A8AECdBb18d9761AEeE34591112` → `0x34ffF1A1CB3C054E9eD1BbD36883B14A66E6C260`; minWithdrawalAmount **10 ETH → 5 ETH** |
| `OperatorFeeVault` `0x420000000000000000000000000000000000001b` | v1.1.1 | recipient `0x4200000000000000000000000000000000000019` (BaseFeeVault) → `0x34ffF1A1CB3C054E9eD1BbD36883B14A66E6C260` (min stays 0, network stays L2) |

> [!IMPORTANT]
> This task re-creates the cancelled
> [066-soneium-fee-vault-recipient-update](../066-soneium-fee-vault-recipient-update/README.md)
> (same calls, same recipient) and is sequenced directly after `071-U20-op-ink-soneium-uni`
> (one L1PAO, Foundation Upgrade Safe and Security Council nonce). The nonce pins in
> [config.toml](./config.toml) assume it has executed. `073-gas-limit-ink` follows this task.

> [!NOTE]
> **Governance cleared 2026-08-27:** the proposal's optimistic-approval vote
> [SUCCEEDED](https://vote.optimism.io/proposals/62196726306527567841489953851523914523377547965497415025005404732621648509772).
> The veto window ended 2026-08-27 with 0.17% of votable supply against (20% veto quorum not
> reached), so signing may proceed.

## Simulation & Signing

This is a **nested** task: signers act through one of the L1PAO's two owner safes, so the child-safe argument (`council` or `foundation`) is required.

```bash
cd src/tasks/eth/072-soneium-fee-vault-recipient-update

# Simulate with council or foundation safe
just simulate-stack eth 072-soneium-fee-vault-recipient-update council
just simulate-stack eth 072-soneium-fee-vault-recipient-update foundation

# Sign with council or foundation safe
SKIP_DECODE_AND_PRINT=1 just sign-stack eth 072-soneium-fee-vault-recipient-update council
SKIP_DECODE_AND_PRINT=1 just sign-stack eth 072-soneium-fee-vault-recipient-update foundation
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the calldata breakdown, and the expected state changes.
