# 122-U21-sepolia-devnet-4-5-opcm-upgrade-v900

Status: DRAFT, NOT READY TO SIGN

> [!NOTE]
> Placeholder values (`0xdead…dead`) are in place for sepolia-devnet-5, the U21 kona interop
> prestate and the expected validation errors until sepolia-devnet-5 is deployed
> (devnets-private #2365). The task cannot be simulated until they are filled in.

## Objective

Executes Upgrade 21 (`op-contracts/v9.0.0`) on sepolia-devnet-4 and sepolia-devnet-5 in a single
transaction from the staging ProxyAdminOwner Safe
([`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`](https://sepolia.etherscan.io/address/0xe934Dc97E347C6aCef74364B50125bb8689c40ff),
1-of-1): one `OPCM.upgradeSuperchain` on the shared devnet SuperchainConfig
[`0x289d2A1b1AE6E0470D8B72E53B6E3f485f251DBb`](https://sepolia.etherscan.io/address/0x289d2A1b1AE6E0470D8B72E53B6E3f485f251DBb)
followed by one `OPCM.upgrade` per chain, through the v9.0.0-rc.1
[OPCM `0x160f0fe4dc1b3f4026687e8dd4b7f800879939cc`](https://github.com/ethereum-optimism/superchain-registry/blob/41553edca76a4d67d7be0b57f857ffc978295153/validation/standard/standard-versions-sepolia.toml)
(version 9.0.3).

| Chain | Chain ID | Respected game type | SystemConfigProxy |
|---|---|---|---|
| sepolia-devnet-4 | 420130019 | SUPER_CANNON_KONA (9), unchanged | [`0xa15b902f86a60cafe43034eee86a5c19db931e59`](https://sepolia.etherscan.io/address/0xa15b902f86a60cafe43034eee86a5c19db931e59) |
| sepolia-devnet-5 | 420130020 | SUPER_CANNON_KONA (9), unchanged | `0xdead…dead` (not deployed yet) |

On both chains the upgrade moves `SystemConfig` to 4.3.0 and `OptimismPortal2` to 6.1.0, keeps
SUPER_PERMISSIONED (5) and SUPER_CANNON_KONA (9, 0.08 ETH bond) registered with the U21 kona
interop prestate, and carries the current super-root anchor forward. Neither portal has an
`ETHLockbox` at v8 (`ethLockbox()` is zero, `ETH_LOCKBOX` off), so the upgrade deploys one per
chain, authorizes the portal on it and moves the portal's ETH into it.

This is the first half of the U21 rollout on the interop staging pair. It must execute before
[124-U21-sepolia-devnet-4-5-opcm-migrate-v900](../124-U21-sepolia-devnet-4-5-opcm-migrate-v900/README.md),
which requires every chain to be on the v9 OPCM.

The shared SuperchainConfig also serves sepolia-devnet-2 and -3, which stay on v8 until their own
U21 task; the v9 OPCM only requires the SuperchainConfig to be at or above its own implementation
version, so upgrading it first does not block them.

## Simulation & Signing

This is a **single-safe** task: the staging ProxyAdminOwner is a 1-of-1 Safe, so no child-safe
argument is needed.

```bash
cd src/tasks/sep/122-U21-sepolia-devnet-4-5-opcm-upgrade-v900

just simulate-stack sep 122-U21-sepolia-devnet-4-5-opcm-upgrade-v900

USE_KEYSTORE=1 SKIP_DECODE_AND_PRINT=1 just sign-stack sep 122-U21-sepolia-devnet-4-5-opcm-upgrade-v900
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hash, the signer checklist,
the calldata breakdown, the pre-execution check, the expected state changes and the
post-execution checks.
