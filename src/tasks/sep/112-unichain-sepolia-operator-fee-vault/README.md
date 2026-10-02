# 112-unichain-sepolia-operator-fee-vault

Status: [DRAFT, NOT READY TO SIGN]

## Objective

Unichain Sepolia migration, fee-vault step: points the **Unichain Sepolia** (chainId 1301)
`OperatorFeeVault` (`0x420000000000000000000000000000000000001b`, v1.1.1) at the OP Enterprise cost
recipient on L1, via three `OptimismPortal2.depositTransaction` calls from the L1PAO (the aliased
L1PAO owns the L2 ProxyAdmin, which the vault setters authorize against). Sequencer, Base and L1 fee vaults pay into Unichain's fee splitter
and are not touched; Unichain Sepolia's splitter has no owner or setters, so there is no L1Splitter
step on this network.

| Chain | Chain ID | OptimismPortalProxy | OperatorFeeVault field | Change |
|---|---|---|---|---|
| Unichain Sepolia | 1301 | [`0x0d83dab629f0e0F9d36c0Cbc89B69a489f0751bD`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/sepolia/unichain.toml#L51) | `recipient()` | `0x4200000000000000000000000000000000000019` (BaseFeeVault) → `0xc9EDDd1852e84164A2Be3a1743F492C93EB0aC52` |
| | | | `withdrawalNetwork()` | 1 (L2) → 0 (L1) |
| | | | `minWithdrawalAmount()` | 0 → 0.15 ETH (the eth/062 cost-vault value) |

## Simulation & Signing

This is a **nested** task: signers act through one of the L1PAO's two owner safes, so the
child-safe argument (`council` or `foundation`) is required.

```bash
cd src/tasks/sep/112-unichain-sepolia-operator-fee-vault

just simulate-stack sep 112-unichain-sepolia-operator-fee-vault council   # or foundation

SKIP_DECODE_AND_PRINT=1 just sign-stack sep 112-unichain-sepolia-operator-fee-vault council   # or foundation
```

## Execution

For facilitators, once both child safes have collected their signatures: approve once per safe,
then execute. Run the pre-execution checks in [VALIDATION.md](./VALIDATION.md) first.

```bash
cd src/tasks/sep/112-unichain-sepolia-operator-fee-vault

SIGNATURES=0x... just approve council
SIGNATURES=0x... just approve foundation
just execute
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the signer
checklist, the calldata breakdown, the pre-execution checks, the expected state changes and
the post-execution checks.
