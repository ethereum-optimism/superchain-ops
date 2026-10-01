# 080-unichain-operator-fee-vault

Status: [DRAFT, NOT READY TO SIGN]

## Objective

Unichain Mainnet migration, fee-vault step: points the **Unichain** (chainId 130) `OperatorFeeVault`
(`0x420000000000000000000000000000000000001b`, v1.1.1) at the OP Enterprise cost recipient on L1, via
three `OptimismPortal2.depositTransaction` calls from the L1PAO (the aliased L1PAO owns the L2
ProxyAdmin, which the vault setters authorize against). The OperatorFeeVault sits outside
Unichain's fee splitter; the Sequencer, Base and L1 fee vaults pay into the splitter and are not
touched.

| Chain | Chain ID | OptimismPortalProxy | OperatorFeeVault field | Change |
|---|---|---|---|---|
| Unichain | 130 | [`0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/mainnet/unichain.toml#L50) | `recipient()` | `0x4200000000000000000000000000000000000019` (BaseFeeVault) → `0xdead000000000000000000000000000000000004` |
| | | | `withdrawalNetwork()` | 1 (L2) → 0 (L1) |
| | | | `minWithdrawalAmount()` | 0 → 0.15 ETH (the eth/062 cost-vault value) |

> [!WARNING]
> This task contains **placeholder** values, so it stays DRAFT and its hashes and calldata are
> not signable. Replace them in [config.toml](./config.toml), re-run the simulation and
> regenerate [VALIDATION.md](./VALIDATION.md):
>   - `0xdead000000000000000000000000000000000004`: OPE cost recipient (L1)

> [!IMPORTANT]
> Mainnet L1PAO actions on Unichain go through a Maintenance Upgrade governance post (as eth/061 and eth/062 did for Ink); signing is gated on it.

## Simulation & Signing

This is a **nested** task: signers act through one of the L1PAO's two owner safes, so the
child-safe argument (`council` or `foundation`) is required.

```bash
cd src/tasks/eth/080-unichain-operator-fee-vault

just simulate-stack eth 080-unichain-operator-fee-vault council   # or foundation

SKIP_DECODE_AND_PRINT=1 just sign-stack eth 080-unichain-operator-fee-vault council   # or foundation
```

## Execution

For facilitators, once both child safes have collected their signatures: approve once per safe,
then execute. Run the pre-execution checks in [VALIDATION.md](./VALIDATION.md) first.

```bash
cd src/tasks/eth/080-unichain-operator-fee-vault

SIGNATURES=0x... just approve council
SIGNATURES=0x... just approve foundation
just execute
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the signer
checklist, the calldata breakdown, the pre-execution checks, the expected state changes and
the post-execution checks.
