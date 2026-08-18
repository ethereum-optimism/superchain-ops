# 066-soneium-fee-vault-recipient-update

Status: [READY TO SIGN]

## Objective

For **Soneium Mainnet** (chainId 1868), rotate the recipient of **all four L2 fee-vault predeploys** to the new Soneium fee recipient Safe `0x34ffF1A1CB3C054E9eD1BbD36883B14A66E6C260`, and lower the minimum withdrawal amount **10 ETH > 5 ETH** on the three vaults that carry it. Withdrawal networks are untouched (all L2), as is the OperatorFeeVault's zero minimum.

| Vault | Version (live) | Change |
|---|---|---|
| `SequencerFeeVault` `0x4200000000000000000000000000000000000011` | v1.6.1 | recipient `0xF07b3169ffF67A8AECdBb18d9761AEeE34591112` → `0x34ffF1A1CB3C054E9eD1BbD36883B14A66E6C260`; minWithdrawalAmount **10 ETH → 5 ETH** |
| `BaseFeeVault` `0x4200000000000000000000000000000000000019` | v1.6.1 | recipient `0xF07b3169ffF67A8AECdBb18d9761AEeE34591112` → `0x34ffF1A1CB3C054E9eD1BbD36883B14A66E6C260`; minWithdrawalAmount **10 ETH → 5 ETH** |
| `L1FeeVault` `0x420000000000000000000000000000000000001A` | v1.6.1 | recipient `0xF07b3169ffF67A8AECdBb18d9761AEeE34591112` → `0x34ffF1A1CB3C054E9eD1BbD36883B14A66E6C260`; minWithdrawalAmount **10 ETH → 5 ETH** |
| `OperatorFeeVault` `0x420000000000000000000000000000000000001b` | v1.1.1 | recipient `0x4200000000000000000000000000000000000019` (BaseFeeVault) → `0x34ffF1A1CB3C054E9eD1BbD36883B14A66E6C260` (min stays 0, network stays L2) |

## Simulation & Signing

This is a **nested** task: signers act through one of the L1PAO's two owner safes, so the child-safe argument (`council` or `foundation`) is required.

```bash
cd src/tasks/eth/066-soneium-fee-vault-recipient-update

# Simulate — one command per signer safe (hashes recorded in VALIDATION.md):
just simulate-stack eth 066-soneium-fee-vault-recipient-update council
just simulate-stack eth 066-soneium-fee-vault-recipient-update foundation

# Sign — with whichever safe you are an owner of (nested signing flow — see docs/NESTED.md):
SKIP_DECODE_AND_PRINT=1 just sign-stack eth 066-soneium-fee-vault-recipient-update council
SKIP_DECODE_AND_PRINT=1 just sign-stack eth 066-soneium-fee-vault-recipient-update foundation
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the calldata breakdown, and the expected state changes.
