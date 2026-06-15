# 102-migration-src-0-proposer-rotation

Status: DRAFT, NOT READY TO SIGN

## Objective

For the `migration-src-0` (chainId 420120140) DisputeGameFactory on Sepolia, rotate the **PermissionedDisputeGame** (PDG, game type 1) proposer and challenger to the `migrated-sop-1` receiving infrastructure (the FROM side of this Type A migration exercise).

The PDG implementation address is unchanged (`0x58bf355C5d4EdFc723eF89d99582ECCfd143266A`); only the `gameArgs` blob changes, so the template emits a single `setImplementation` call for game type 1.

> [!NOTE]
> **Fault proofs are out of scope for this exercise.** The absolute prestate is **left unchanged** (`0x038512e0…d54c`, the netchef-default permissioned prestate). The FaultDisputeGame (FDG, game type 0) is **not** registered on `migration-src-0` (`gameImpls(0) == 0x0`) and is not added here — the FDG slot stays zeroed (`fdgImpl = 0x0`, empty `fdgGameArgs`), so no FDG call is emitted.

This is Migration Log step **3a/4** (`DisputeGameFactory.setImplementation`, proposer/challenger rotation).

- **DisputeGameFactoryProxy**: `0xD36035054813F3979f61fE17E870beC0fB8F964D`
- **Signer**: L1 ProxyAdminOwner Safe `0xe934Dc97E347C6aCef74364B50125bb8689c40ff`

## State Changes

Writes to `DisputeGameFactoryProxy` ([`0xD3603505…964D`](https://sepolia.etherscan.io/address/0xD36035054813F3979f61fE17E870beC0fB8F964D#readContract)) for chainId 420120140.

### Game type 1 (PDG — PERMISSIONED_CANNON)

| `gameArgs(1)` field | Bytes | Current (on-chain) | New |
|---------------------|-------|--------------------|-----|
| prestate | 0–32 | `0x038512e02c4c3f7bdaec27d00edf55b7155e0905301e1a88083e4e0a6764d54c` | `0x038512e02c4c3f7bdaec27d00edf55b7155e0905301e1a88083e4e0a6764d54c` (unchanged) |
| vm | 32–52 | `0x6463dee3828677f6270d83d45408044fc5edb908` | `0x6463dee3828677f6270d83d45408044fc5edb908` (unchanged) |
| anchorStateRegistry | 52–72 | `0x25189fec7e5794e6cbb53afcfe624c517537a216` | `0x25189fec7e5794e6cbb53afcfe624c517537a216` (unchanged) |
| delayedWETH | 72–92 | `0x3895dcd2f5ddd092c31aa8744ceb4c6006b7ea8e` | `0x3895dcd2f5ddd092c31aa8744ceb4c6006b7ea8e` (unchanged) |
| l2ChainId | 92–124 | `420120140` | `420120140` (unchanged) |
| proposer | 124–144 | `0x0fd61abe8d576f2c77ea05af2d37eef98164c9fc` | `0x5e9eE0Aa455425AaD2B55742077F95113FbaeB71` |
| challenger | 144–164 | `0x5d5f9c4bd7946bf3f1f2ecf2cc9896fcb6a1546e` | `0x9805e7976880e6e48Ce765118846078B877d80D0` |

`gameImpls(1)` is unchanged at `0x58bf355C5d4EdFc723eF89d99582ECCfd143266A`. Game type 0 (FDG) remains unset (`gameImpls(0) == 0x0`).

- **Current values**: full `gameArgs(1)` blob read on-chain on Sepolia via `cast call 0xD3603505… "gameArgs(uint32)(bytes)" 1`. Decomposed per the permissioned 164-byte layout (prestate|vm|ASR|weth|chainId|proposer|challenger).
- **New proposer / challenger**: `migrated-sop-1` receiving infrastructure, read on-chain from `migrated-sop-1`'s DisputeGameFactory (`cast call 0xD22e520F… "gameArgs(uint32)(bytes)" 1`).

## Simulation & Signing

Simulation commands:
```bash
cd src/tasks/sep/102-migration-src-0-proposer-rotation
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../justfile simulate
```

Signing commands:
```bash
cd src/tasks/sep/102-migration-src-0-proposer-rotation
just --dotenv-path $(pwd)/.env --justfile ../../../justfile sign
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes and the calldata fingerprint.
