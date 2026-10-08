# 083-soneium-proposer-rotation

Status: [DRAFT, NOT READY TO SIGN]

## Objective

Soneium Mainnet migration, cutover step 4: rotates the proposer of the `SUPER_PERMISSIONED` (5)
dispute game on the **Soneium** (chainId 1868) `DisputeGameFactoryProxy` to the OP Enterprise
proposer, via `setImplementation(5, impl, gameArgs)` from the L1PAO. Since U20 the type-5 `gameArgs`
are `anchorStateRegistry | proposer` with no challenger. Type 5 is Soneium's respected and only game type (there is no type 9), so after the old proposer stops, only this rotation lets the OPE proposer post outputs.

| Chain | Chain ID | DisputeGameFactoryProxy | `gameArgs(5)` proposer |
|---|---|---|---|
| Soneium | 1868 | [`0x512A3d2c7a43BD9261d2B8E8C9c70D4bd4D503C0`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/mainnet/soneium.toml#L52) | `0x400c164C4a8cA84385B70EEd6eB03ea847c8E1b8` → `0xdead00000000000000000000000000001003dead` |

The impl (`0x5C3eb47cB0174aea522a2a9Ae79487139A53D691`, SuperPermissionedDisputeGame v1.1.0), the anchorStateRegistry and the zero init
bond are read live and kept.

## Simulation & Signing

This is a **nested** task: signers act through one of the L1PAO's two owner safes, so the
child-safe argument (`council` or `foundation`) is required.

```bash
cd src/tasks/eth/083-soneium-proposer-rotation

just simulate-stack eth 083-soneium-proposer-rotation council   # or foundation

SKIP_DECODE_AND_PRINT=1 just sign-stack eth 083-soneium-proposer-rotation council   # or foundation
```

## Execution

For facilitators, once both child safes have collected their signatures: approve once per safe,
then execute. Run the pre-execution checks in [VALIDATION.md](./VALIDATION.md) first.

```bash
cd src/tasks/eth/083-soneium-proposer-rotation

SIGNATURES=0x... just approve council
SIGNATURES=0x... just approve foundation
just execute
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the signer
checklist, the calldata breakdown, the pre-execution checks, the expected state changes and
the post-execution checks.
