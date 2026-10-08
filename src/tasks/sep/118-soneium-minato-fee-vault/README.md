# 118-soneium-minato-fee-vault

Status: [DRAFT, NOT READY TO SIGN]

## Objective

Soneium Minato migration, fee-vault step: points the **Soneium Minato** (chainId 1946) `L1FeeVault` and
`OperatorFeeVault` at the OP Enterprise cost recipient on L1 (withdrawal network L1, 0.15 ETH minimum,
the eth/062 cost-vault values), via 5 `OptimismPortal2.depositTransaction` calls from the L1PAO
through [`0x65ea1489741A5D72fFdD8e6485B216bBdcC15Af3`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/sepolia/soneium-minato.toml#L51) (the aliased L1PAO owns the L2 ProxyAdmin, which the vault setters
authorize against). The Sequencer and Base fee vaults are not touched.

| Vault | Field | Change |
|---|---|---|
| L1FeeVault `0x420000000000000000000000000000000000001a` | `recipient()` | `0x7CE93e2bEa4D52e7d7C6870F294874ef034C31Cd` → `0xdead00000000000000000000000000001004dead` |
| L1FeeVault `0x420000000000000000000000000000000000001a` | `minWithdrawalAmount()` | 1 ETH → 0.15 ETH |
| OperatorFeeVault `0x420000000000000000000000000000000000001b` | `recipient()` | `0x4200000000000000000000000000000000000019` (BaseFeeVault) → `0xdead00000000000000000000000000001004dead` |
| OperatorFeeVault `0x420000000000000000000000000000000000001b` | `withdrawalNetwork()` | 1 (L2) → 0 (L1) |
| OperatorFeeVault `0x420000000000000000000000000000000000001b` | `minWithdrawalAmount()` | 0 → 0.15 ETH |

> [!IMPORTANT]
> The L1FeeVault already withdraws to L1, so its network is unchanged and no deposit is sent for it.

## Simulation & Signing

This is a **nested** task: signers act through one of the L1PAO's two owner safes, so the
child-safe argument (`council` or `foundation`) is required.

```bash
cd src/tasks/sep/118-soneium-minato-fee-vault

just simulate-stack sep 118-soneium-minato-fee-vault council   # or foundation

SKIP_DECODE_AND_PRINT=1 just sign-stack sep 118-soneium-minato-fee-vault council   # or foundation
```

## Execution

For facilitators, once both child safes have collected their signatures: approve once per safe,
then execute. Run the pre-execution checks in [VALIDATION.md](./VALIDATION.md) first.

```bash
cd src/tasks/sep/118-soneium-minato-fee-vault

SIGNATURES=0x... just approve council
SIGNATURES=0x... just approve foundation
just execute
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the signer
checklist, the calldata breakdown, the pre-execution checks, the expected state changes and
the post-execution checks.
