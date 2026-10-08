# 113-op-sepolia-proposer-rotation

Status: [DRAFT, NOT READY TO SIGN]

## Objective

OP Sepolia OP Enterprise key rotation, part 1: rotates the proposer of the `SUPER_PERMISSIONED` (5)
dispute game on the **OP Sepolia** (chainId 11155420) `DisputeGameFactoryProxy` to the OP Enterprise
proposer, via `setImplementation(5, impl, gameArgs)` from the L1PAO. Since U20 the type-5 `gameArgs`
are `anchorStateRegistry | proposer` with no challenger. The respected game type stays `SUPER_CANNON_KONA` (9), which is permissionless, so type 5 is the Guardian fallback.

| Chain | Chain ID | DisputeGameFactoryProxy | `gameArgs(5)` proposer |
|---|---|---|---|
| OP Sepolia | 11155420 | [`0x05F9613aDB30026FFd634f38e5C4dFd30a197Fa1`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/sepolia/op.toml#L53) | `0x49277EE36A024120Ee218127354c4a3591dc90A9` → `0x9884C33C65111DA7Bbed0e63cD2392F503b135F5` |

The impl (`0x5C3eb47cB0174aea522a2a9Ae79487139A53D691`, SuperPermissionedDisputeGame v1.1.0), the anchorStateRegistry and the zero init
bond are read live and kept.

## Simulation & Signing

This is a **nested** task: signers act through one of the L1PAO's two owner safes, so the
child-safe argument (`council` or `foundation`) is required.

```bash
cd src/tasks/sep/113-op-sepolia-proposer-rotation

just simulate-stack sep 113-op-sepolia-proposer-rotation council   # or foundation

SKIP_DECODE_AND_PRINT=1 just sign-stack sep 113-op-sepolia-proposer-rotation council   # or foundation
```

## Execution

For facilitators, once both child safes have collected their signatures: approve once per safe,
then execute. Run the pre-execution checks in [VALIDATION.md](./VALIDATION.md) first.

```bash
cd src/tasks/sep/113-op-sepolia-proposer-rotation

SIGNATURES=0x... just approve council
SIGNATURES=0x... just approve foundation
just execute
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the signer
checklist, the calldata breakdown, the pre-execution checks, the expected state changes and
the post-execution checks.
