# 124-U21-sepolia-devnet-4-5-opcm-migrate-v900

Status: DRAFT, NOT READY TO SIGN

> [!NOTE]
> Placeholder values (`0xdead…dead`) are in place for the super proposer, the super root, the
> U21 kona interop prestate and the expected validation errors until sepolia-devnet-5 is
> deployed (devnets-private #2365) and task 122 has been simulated. The task cannot be
> simulated until they are filled in.

## Objective

Migrates sepolia-devnet-4 and sepolia-devnet-5 onto shared dispute contracts with
`OPCM.migrate`, from the staging ProxyAdminOwner Safe
([`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`](https://sepolia.etherscan.io/address/0xe934Dc97E347C6aCef74364B50125bb8689c40ff),
1-of-1), through the v9.0.0-rc.1
[OPCM `0x160f0fe4dc1b3f4026687e8dd4b7f800879939cc`](https://github.com/ethereum-optimism/superchain-registry/blob/41553edca76a4d67d7be0b57f857ffc978295153/validation/standard/standard-versions-sepolia.toml)
(version 9.0.3). A single delegatecall:

- deploys a shared ETHLockbox, DisputeGameFactory and AnchorStateRegistry;
- moves each portal's and lockbox's ETH into the shared lockbox;
- points both portals at the shared dispute contracts and enables INTEROP on both chains;
- registers SUPER_PERMISSIONED (5) and SUPER_CANNON_KONA (9, 0.08 ETH bond) on the shared
  DisputeGameFactory and makes 9 the respected game type.

Migration is one-way and invalidates all prior withdrawal proofs. This is the staging rehearsal
of the OP Mainnet + Unichain interop set.

Depends on
[122-U21-sepolia-devnet-4-5-opcm-upgrade-v900](../122-U21-sepolia-devnet-4-5-opcm-upgrade-v900/README.md):
`migrate` requires every chain to be on the v9 OPCM.

| Chain | Chain ID | SystemConfigProxy |
|---|---|---|
| sepolia-devnet-4 | 420130019 | [`0xa15b902f86a60cafe43034eee86a5c19db931e59`](https://sepolia.etherscan.io/address/0xa15b902f86a60cafe43034eee86a5c19db931e59) |
| sepolia-devnet-5 | 420130020 | `0xdead…dead` (not deployed yet) |

## Simulation & Signing

This is a **single-safe** task: the staging ProxyAdminOwner is a 1-of-1 Safe, so no child-safe
argument is needed. Always simulate stacked on task 122.

```bash
cd src/tasks/sep/124-U21-sepolia-devnet-4-5-opcm-migrate-v900

just simulate-stack sep 124-U21-sepolia-devnet-4-5-opcm-migrate-v900

USE_KEYSTORE=1 SKIP_DECODE_AND_PRINT=1 just sign-stack sep 124-U21-sepolia-devnet-4-5-opcm-migrate-v900
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hash, the signer checklist,
the calldata breakdown, the pre-execution check, the expected state changes and the
post-execution checks.
