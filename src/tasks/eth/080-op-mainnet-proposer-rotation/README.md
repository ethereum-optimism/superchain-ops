# 080-op-mainnet-proposer-rotation

Status: [DRAFT, NOT READY TO SIGN]

## Objective

OP Mainnet OP Enterprise key rotation, part 1: rotates the proposer of the `SUPER_PERMISSIONED` (5)
dispute game on the **OP Mainnet** (chainId 10) `DisputeGameFactoryProxy` to the OP Enterprise
proposer, via `setImplementation(5, impl, gameArgs)` from the L1PAO. Since U20 the type-5 `gameArgs`
are `anchorStateRegistry | proposer` with no challenger. The respected game type stays `SUPER_CANNON_KONA` (9), which is permissionless, so type 5 is the Guardian fallback.

| Chain | Chain ID | DisputeGameFactoryProxy | `gameArgs(5)` proposer |
|---|---|---|---|
| OP Mainnet | 10 | [`0xe5965Ab5962eDc7477C8520243A95517CD252fA9`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/mainnet/op.toml#L52) | `0x473300df21D047806A082244b417f96b32f13A33` → `0xdead00000000000000000000000000002003dead` |

The impl (`0x5C3eb47cB0174aea522a2a9Ae79487139A53D691`, SuperPermissionedDisputeGame v1.1.0), the anchorStateRegistry and the zero init
bond are read live and kept.

## Simulation & Signing

This is a **nested** task: signers act through one of the L1PAO's two owner safes, so the
child-safe argument (`council` or `foundation`) is required.

```bash
cd src/tasks/eth/080-op-mainnet-proposer-rotation

just simulate-stack eth 080-op-mainnet-proposer-rotation council   # or foundation

SKIP_DECODE_AND_PRINT=1 just sign-stack eth 080-op-mainnet-proposer-rotation council   # or foundation
```

## Execution

For facilitators, once both child safes have collected their signatures: approve once per safe,
then execute. Run the pre-execution checks in [VALIDATION.md](./VALIDATION.md) first.

```bash
cd src/tasks/eth/080-op-mainnet-proposer-rotation

SIGNATURES=0x... just approve council
SIGNATURES=0x... just approve foundation
just execute
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the signer
checklist, the calldata breakdown, the pre-execution checks, the expected state changes and
the post-execution checks.
