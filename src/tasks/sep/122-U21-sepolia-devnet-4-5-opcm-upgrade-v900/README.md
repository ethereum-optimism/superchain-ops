# 122-U21-sepolia-devnet-4-5-opcm-upgrade-v900

Status: DRAFT, NOT READY TO SIGN

> [!NOTE]
> Placeholder values (`0xdead…dead`) are in place for sepolia-devnet-5, the U21 kona interop
> prestate and the expected validation errors until sepolia-devnet-5 is deployed
> (devnets-private #2365). The task cannot be simulated until they are filled in.

## Objective

Executes Upgrade 21 (`op-contracts/v9.0.0`) on the four OP Labs staging networks that share the
devnet SuperchainConfig (sepolia-devnet-2, -3, -4 and -5) in a single transaction from the
staging ProxyAdminOwner Safe
([`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`](https://sepolia.etherscan.io/address/0xe934Dc97E347C6aCef74364B50125bb8689c40ff),
1-of-1): one `OPCM.upgradeSuperchain` on the shared devnet SuperchainConfig
[`0x289d2A1b1AE6E0470D8B72E53B6E3f485f251DBb`](https://sepolia.etherscan.io/address/0x289d2A1b1AE6E0470D8B72E53B6E3f485f251DBb)
followed by one `OPCM.upgrade` per chain, through the v9.0.0-rc.1
[OPCM `0x160f0fe4dc1b3f4026687e8dd4b7f800879939cc`](https://github.com/ethereum-optimism/superchain-registry/blob/41553edca76a4d67d7be0b57f857ffc978295153/validation/standard/standard-versions-sepolia.toml)
(version 9.0.3).

| Chain | Chain ID | Respected game type | SystemConfigProxy |
|---|---|---|---|
| sepolia-devnet-2 | 420130015 | SUPER_CANNON_KONA (9), unchanged | [`0x5F91Ea5EEA70E505b457A442Dc7A8e5D9641b937`](https://sepolia.etherscan.io/address/0x5F91Ea5EEA70E505b457A442Dc7A8e5D9641b937) |
| sepolia-devnet-3 | 420130018 | SUPER_PERMISSIONED (5), unchanged | [`0x66dac055c7cD3B3a043760521dCa840cB3E8F3FF`](https://sepolia.etherscan.io/address/0x66dac055c7cD3B3a043760521dCa840cB3E8F3FF) |
| sepolia-devnet-4 | 420130019 | SUPER_CANNON_KONA (9), unchanged | [`0xa15b902f86a60cafe43034eee86a5c19db931e59`](https://sepolia.etherscan.io/address/0xa15b902f86a60cafe43034eee86a5c19db931e59) |
| sepolia-devnet-5 | 420130020 | SUPER_CANNON_KONA (9), unchanged | `0xdead…dead` (not deployed yet) |

On every chain the upgrade moves `SystemConfig` to 4.3.0 and `OptimismPortal2` to 6.1.0, keeps
SUPER_PERMISSIONED (5) registered and carries the current super-root anchor forward. On
sepolia-devnet-2, -4 and -5 it re-registers SUPER_CANNON_KONA (9, 0.08 ETH bond): devnet-2 with
the kona-client/v1.9.0 `cannon64-kona-interop` prestate (it stays a standalone chain), devnet-4
and -5 with the U21 prestate of their interop cluster. sepolia-devnet-3 has no SUPER_CANNON_KONA
implementation, so it stays permissioned. No portal has an `ETHLockbox` at v8 (`ethLockbox()` is
zero, `ETH_LOCKBOX` off), so the upgrade deploys one per chain, authorizes the portal on it and
moves the portal's ETH into it.

sepolia-devnet-4 and -5 are the interop staging pair. U21 is upgrade only (decided 3 Nov 2026):
their `OPCM.migrate` follows the U22 / op-contracts v10.0.0 upgrade as a separate task, and
sepolia-devnet-2 and -3 are never migrated.

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
