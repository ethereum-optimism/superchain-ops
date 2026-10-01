# 113-unichain-sepolia-proposer-rotation

Status: [DRAFT, NOT READY TO SIGN]

## Objective

Unichain Sepolia migration, cutover step 4: rotates the proposer of the `SUPER_PERMISSIONED` (5)
dispute game on the **Unichain Sepolia** (chainId 1301) `DisputeGameFactoryProxy` to the OP Enterprise
proposer, via `setImplementation(5, impl, gameArgs)` from the L1PAO. Since U20 the type-5 `gameArgs`
are `anchorStateRegistry | proposer` with no challenger; the respected game type stays
`SUPER_CANNON_KONA` (9), which is permissionless, so type 5 is the Guardian fallback.

| Chain | Chain ID | DisputeGameFactoryProxy | `gameArgs(5)` proposer |
|---|---|---|---|
| Unichain Sepolia | 1301 | [`0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/sepolia/unichain.toml#L53) | `0xA25B0eF1CC3ee12a0a167B5BF44dB1a9c166474e` → `0xdead000000000000000000000000000000000003` |

The impl (`0x5C3eb47cB0174aea522a2a9Ae79487139A53D691`, SuperPermissionedDisputeGame v1.1.0), the anchorStateRegistry and the zero init
bond are read live and kept.

> [!WARNING]
> This task contains **placeholder** values, so it stays DRAFT and its hashes and calldata are
> not signable. Replace them in [config.toml](./config.toml), re-run the simulation and
> regenerate [VALIDATION.md](./VALIDATION.md):
>   - `0xdead000000000000000000000000000000000003`: OPE proposer

## Simulation & Signing

This is a **nested** task: signers act through one of the L1PAO's two owner safes, so the
child-safe argument (`council` or `foundation`) is required.

```bash
cd src/tasks/sep/113-unichain-sepolia-proposer-rotation

just simulate-stack sep 113-unichain-sepolia-proposer-rotation council   # or foundation

SKIP_DECODE_AND_PRINT=1 just sign-stack sep 113-unichain-sepolia-proposer-rotation council   # or foundation
```

## Execution

For facilitators, once both child safes have collected their signatures: approve once per safe,
then execute. Run the pre-execution checks in [VALIDATION.md](./VALIDATION.md) first.

```bash
cd src/tasks/sep/113-unichain-sepolia-proposer-rotation

SIGNATURES=0x... just approve council
SIGNATURES=0x... just approve foundation
just execute
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the signer
checklist, the calldata breakdown, the pre-execution checks, the expected state changes and
the post-execution checks.
