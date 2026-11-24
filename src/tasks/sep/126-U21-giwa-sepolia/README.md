# 126-U21-giwa-sepolia

Status: DRAFT, NOT READY TO SIGN

## Objective

Executes Upgrade 21 (`op-contracts/v9.0.0`) on GIWA Sepolia Testnet (chain id 91342) in a
single transaction from the GIWA Sepolia ProxyAdminOwner
([`0x0B266965c88C78f17e1F9f59784249bf8Da1CB9E`](https://github.com/ethereum-optimism/superchain-registry/blob/308e08f7a0508e46c28686c9538fec39985b73c6/superchain/configs/sepolia/giwa.toml#L44),
a nested 2-of-2 of the DunamuUpgradeSafe `0x3d58888b6903B87bD030b93F6FD37cb843b92DB7` and the
GIWASecurityCouncil `0x37FF75B6545F0747b21c43EEB95744b791d1bf1C`, each 1-of-1): one
`OPCM.upgradeSuperchain` on GIWA's own SuperchainConfig followed by one `OPCM.upgrade`, through
the v9.0.0
[OPCM `0x160f0fe4dc1b3f4026687e8dd4b7f800879939cc`](https://github.com/ethereum-optimism/superchain-registry/blob/308e08f7a0508e46c28686c9538fec39985b73c6/validation/standard/standard-versions-sepolia.toml#L8-L24)
(version 9.0.3).

| Chain | Chain ID | Respected game type | SystemConfigProxy |
|---|---|---|---|
| GIWA Sepolia Testnet | 91342 | SUPER_PERMISSIONED (5), unchanged | [`0x8352825bA56C32d816Dd906Ad4A392B5BC9eC984`](https://github.com/ethereum-optimism/superchain-registry/blob/308e08f7a0508e46c28686c9538fec39985b73c6/superchain/configs/sepolia/giwa.toml#L49) |

The upgrade moves GIWA's SuperchainConfig (`0xEF3a8c9Ec7873C3ACEE4e6153fb66072cdE9032d`) to
2.5.0, `SystemConfig` to 4.3.0, `OptimismPortal2` to 6.1.0, the `AnchorStateRegistry` to 4.0.0,
the `L1CrossDomainMessenger` to 2.13.0 and the DelayedWETH to 2.0.0. The portal has no
`ETHLockbox` at v8 (`ethLockbox()` is zero, `ETH_LOCKBOX` off), so the upgrade deploys one,
authorizes the portal on it, enables `ETH_LOCKBOX` and moves the portal's ETH into it. GIWA
Sepolia has no SUPER_CANNON_KONA implementation, so it stays permissioned on SUPER_PERMISSIONED
with the same game implementation and arguments, and the super-root anchor is carried forward
(same shape as sepolia-devnet-3 in [sep/122](../122-U21-sepolia-devnet-4-5-opcm-upgrade-v900/README.md)).

## Simulation & Signing

This is a **nested** task: signers act through one of the ProxyAdminOwner's two owner safes, so
the child-safe argument (`DunamuUpgradeSafe` or `GIWASecurityCouncil`) is required.

```bash
cd src/tasks/sep/126-U21-giwa-sepolia

just simulate-stack sep 126-U21-giwa-sepolia DunamuUpgradeSafe   # or GIWASecurityCouncil

SKIP_DECODE_AND_PRINT=1 just sign-stack sep 126-U21-giwa-sepolia DunamuUpgradeSafe   # or GIWASecurityCouncil
```

## Execution

For facilitators, once both child safes have collected their signatures: approve once per
safe, then execute. Run the pre-execution checks in [VALIDATION.md](./VALIDATION.md) first.
Pass `TENDERLY_GAS` explicitly: forge's own gas estimate is too low for the child approvals
(the inner Safe call runs out of gas with `GS013`).

```bash
cd src/tasks/sep/126-U21-giwa-sepolia

TENDERLY_GAS=10000000 SIGNATURES=0x... just approve DunamuUpgradeSafe
TENDERLY_GAS=10000000 SIGNATURES=0x... just approve GIWASecurityCouncil
TENDERLY_GAS=10000000 just execute
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the signer
checklist, the calldata breakdown, the pre-execution checks, the expected state changes and
the post-execution checks.
