# 081-soneium-fee-vault

Status: [DRAFT, NOT READY TO SIGN]

## Objective

Soneium Mainnet migration, fee-vault step: points the **Soneium** (chainId 1868) `L1FeeVault` and
`OperatorFeeVault` at the OP Enterprise cost recipient on L1 (withdrawal network L1, 0.15 ETH minimum,
the eth/062 cost-vault values), via 6 `OptimismPortal2.depositTransaction` calls from the L1PAO
through [`0x88e529A6ccd302c948689Cd5156C83D4614FAE92`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/mainnet/soneium.toml#L50) (the aliased L1PAO owns the L2 ProxyAdmin, which the vault setters
authorize against). The Sequencer and Base fee vaults are not touched.

| Vault | Field | Change |
|---|---|---|
| L1FeeVault `0x420000000000000000000000000000000000001a` | `recipient()` | `0x34ffF1A1CB3C054E9eD1BbD36883B14A66E6C260` (Soneium fee recipient, eth/072) → `0xdead00000000000000000000000000001004dead` |
| L1FeeVault `0x420000000000000000000000000000000000001a` | `withdrawalNetwork()` | 1 (L2) → 0 (L1) |
| L1FeeVault `0x420000000000000000000000000000000000001a` | `minWithdrawalAmount()` | 5 ETH → 0.15 ETH |
| OperatorFeeVault `0x420000000000000000000000000000000000001b` | `recipient()` | `0x34ffF1A1CB3C054E9eD1BbD36883B14A66E6C260` (Soneium fee recipient, eth/072) → `0xdead00000000000000000000000000001004dead` |
| OperatorFeeVault `0x420000000000000000000000000000000000001b` | `withdrawalNetwork()` | 1 (L2) → 0 (L1) |
| OperatorFeeVault `0x420000000000000000000000000000000000001b` | `minWithdrawalAmount()` | 0 → 0.15 ETH |

## Simulation & Signing

This is a **nested** task: signers act through one of the L1PAO's two owner safes, so the
child-safe argument (`council` or `foundation`) is required.

```bash
cd src/tasks/eth/081-soneium-fee-vault

just simulate-stack eth 081-soneium-fee-vault council   # or foundation

SKIP_DECODE_AND_PRINT=1 just sign-stack eth 081-soneium-fee-vault council   # or foundation
```

## Execution

For facilitators, once both child safes have collected their signatures: approve once per safe,
then execute. Run the pre-execution checks in [VALIDATION.md](./VALIDATION.md) first.

```bash
cd src/tasks/eth/081-soneium-fee-vault

SIGNATURES=0x... just approve council
SIGNATURES=0x... just approve foundation
just execute
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the signer
checklist, the calldata breakdown, the pre-execution checks, the expected state changes and
the post-execution checks.
