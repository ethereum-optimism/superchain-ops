# 125-U21-op-uni-opcm-migrate-v900

Status: DRAFT, NOT READY TO SIGN

> [!NOTE]
> The super root of the pair in [config.toml](./config.toml) is the one `check-super-root`
> computed on 2026-11-03 and must be refreshed shortly before signing; the hashes and calldata
> in [VALIDATION.md](./VALIDATION.md) are regenerated from the stacked simulation at that
> point. The stacked simulation on task 115 passed on 2026-11-03 with empty validator output.

## Objective

Migrates Unichain Sepolia and OP Sepolia onto shared dispute contracts with `OPCM.migrate`,
from the standard Sepolia L1 ProxyAdminOwner
([`0x1Eb2fFc903729a0F03966B917003800b145F56E2`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/sepolia/op.toml#L47),
2-of-2 of the [Foundation Upgrade Safe](../../../addresses.toml#L17) and the
[Security Council](../../../addresses.toml#L18)), through the v9.0.0-rc.1
[OPCM `0x160f0fe4dc1b3f4026687e8dd4b7f800879939cc`](https://github.com/ethereum-optimism/superchain-registry/blob/41553edca76a4d67d7be0b57f857ffc978295153/validation/standard/standard-versions-sepolia.toml)
(version 9.0.3). A single delegatecall:

- deploys a shared ETHLockbox, DisputeGameFactory and AnchorStateRegistry, administered by
  Unichain Sepolia's `ProxyAdmin` (the first chain in ascending chain-ID order);
- moves each portal's and lockbox's ETH into the shared lockbox;
- points both portals at the shared dispute contracts and enables INTEROP on both chains;
- registers SUPER_PERMISSIONED (5) and SUPER_CANNON_KONA (9, 0.08 ETH bond) on the shared
  DisputeGameFactory and makes 9 the respected game type.

Migration is one-way and invalidates all prior withdrawal proofs. This is the Sepolia
execution of the OP + Unichain interop set; Ink Sepolia and Soneium Minato are upgraded by
task 115 but stay single-chain.

Depends on
[115-U21-op-ink-soneium-uni](../115-U21-op-ink-soneium-uni/README.md):
`migrate` requires every chain to be on the v9 OPCM (`SystemConfig.lastUsedOPCMVersion`),
and the v9 OPCM reverts with `OPContractsManagerV2_InvalidUpgradeSequence` otherwise.

| Chain | Chain ID | SystemConfigProxy |
|---|---|---|
| Unichain Sepolia Testnet | 1301 | [`0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/sepolia/unichain.toml#L52) |
| OP Sepolia Testnet | 11155420 | [`0x034edD2A225f7f429A63E0f1D2084B9E0A93b538`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/sepolia/op.toml#L52) |

| Input | Value | Source |
|---|---|---|
| `proposer` | `0x9884c33c65111da7bbed0e63cd2392f503b135f5` | OP Sepolia's OP Enterprise proposer (sep/113), `DisputeGameFactory.gameArgs(5)` on OP Sepolia |
| `startingAnchorRoot` | `0x382d95f5…9a08` @ 1793742186 | `check-super-root` over both chains' L2 RPCs on 2026-11-03; refresh before signing |
| `startingRespectedGameType` | 9 (SUPER_CANNON_KONA) | both chains' `OptimismPortal2.respectedGameType()` today |
| `cannonKonaPrestate` | `0x03b985…faf59` | kona-client/v1.9.0 `cannon64-kona-interop`, same as task 115 |
| `superCannonKonaInitBond` | 0.08 ETH | both chains' `DisputeGameFactory.initBonds(9)` today |

> [!NOTE]
> The shared game takes one proposer. Unichain Sepolia's op-proposer
> (`0x97e74f93df7fb8eb2542d0cc42dfb21aabb40800`, its current `gameArgs(5)`) must be stopped or
> repointed in its inventory after migration, and OP Sepolia's proposer must be configured for
> the interop set (supernode) before it proposes against the shared factory.

> [!NOTE]
> Unichain Sepolia's `ProxyAdmin` and `DisputeGameFactory` are owned by the standard L1PAO
> on-chain; the registry pin still records the old owner, so [config.toml](./config.toml)
> pins the root safe explicitly, as sep/108 and sep/115 do.

## Simulation & Signing

This is a **nested** task: signers act through one of the L1PAO's two owner safes, so the
child-safe argument (`council` or `foundation`) is required. Always simulate stacked on task 115.

```bash
cd src/tasks/sep/125-U21-op-uni-opcm-migrate-v900

just simulate-stack sep 125-U21-op-uni-opcm-migrate-v900 council   # or foundation

USE_KEYSTORE=1 SKIP_DECODE_AND_PRINT=1 just sign-stack sep 125-U21-op-uni-opcm-migrate-v900 council
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the signer
checklist, the calldata breakdown, the pre-execution check, the expected state changes and the
post-execution checks.
