# 123-U21-sepolia-devnet-6-opcm-upgrade-v900

Status: DRAFT, NOT READY TO SIGN

> [!NOTE]
> Every chain address is a placeholder (`0xdead…dead`) until sepolia-devnet-6 is deployed
> (devnets-private #2366) and brought from `op-contracts/v6.0.0` to `v8.0.0` by its own
> `OPCMUpgradeV700` and `OPCMUpgradeV800` tasks. The task cannot be simulated until then.

## Objective

Executes Upgrade 21 (`op-contracts/v9.0.0`) on sepolia-devnet-6 from the staging
ProxyAdminOwner Safe
([`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`](https://sepolia.etherscan.io/address/0xe934Dc97E347C6aCef74364B50125bb8689c40ff),
1-of-1): one `OPCM.upgradeSuperchain` on the chain's own SuperchainConfig followed by one
`OPCM.upgrade`, through the `op-contracts/v9.0.0`
[OPCM `0x160f0fe4dc1b3f4026687e8dd4b7f800879939cc`](https://github.com/ethereum-optimism/superchain-registry/blob/41553edca76a4d67d7be0b57f857ffc978295153/validation/standard/standard-versions-sepolia.toml)
(version 9.0.3).

| Chain | Chain ID | Respected game type | SystemConfigProxy |
|---|---|---|---|
| sepolia-devnet-6 | 420130021 | SUPER_PERMISSIONED (5), unchanged | `0xdead…dead` (not deployed yet) |

sepolia-devnet-6 mirrors a self-managed custom-gas-token chain on permissioned proofs, so it
has its own SuperchainConfig and never joins an interop set. The upgrade moves `SystemConfig`
to 4.3.0 and `OptimismPortal2` to 6.1.0, keeps SUPER_PERMISSIONED (5) as the only registered
game, carries the current anchor forward and wires an `ETHLockbox` to the portal; because the
chain uses a custom gas token, the portal keeps custody and no ETH moves. There is no migrate
task for this chain.

## Simulation & Signing

This is a **single-safe** task: the staging ProxyAdminOwner is a 1-of-1 Safe, so no child-safe
argument is needed.

```bash
cd src/tasks/sep/123-U21-sepolia-devnet-6-opcm-upgrade-v900

just simulate-stack sep 123-U21-sepolia-devnet-6-opcm-upgrade-v900

USE_KEYSTORE=1 SKIP_DECODE_AND_PRINT=1 just sign-stack sep 123-U21-sepolia-devnet-6-opcm-upgrade-v900
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hash, the signer checklist,
the calldata breakdown, the pre-execution check, the expected state changes and the
post-execution checks.
