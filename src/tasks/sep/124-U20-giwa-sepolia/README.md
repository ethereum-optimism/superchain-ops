# 124-U20-giwa-sepolia

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x59ef077b02a92abecf165fe6588f30f89937197632699271fd505284d3002dde)

## Objective

Executes Upgrade 20 (`op-contracts/v8.0.0`) on GIWA Sepolia Testnet (chain id 91342) in a
single transaction from the GIWA Sepolia ProxyAdminOwner
([`0x0B266965c88C78f17e1F9f59784249bf8Da1CB9E`](https://github.com/ethereum-optimism/superchain-registry/blob/8fde8b3c615ffac0cf9ba82cbdb1fd716a4a7f8a/superchain/configs/sepolia/giwa.toml#L44),
a nested 2-of-2 of the DunamuUpgradeSafe `0x3d58888b6903B87bD030b93F6FD37cb843b92DB7` and the
GIWASecurityCouncil `0x37FF75B6545F0747b21c43EEB95744b791d1bf1C`, each 1-of-1): one
`OPCM.upgradeSuperchain` on GIWA's own SuperchainConfig followed by one `OPCM.upgrade`, through
the v8.0.0
[OPCM `0x6AbfAbBC793883adD5fa308A97163E8225a9f4Ca`](https://github.com/ethereum-optimism/superchain-registry/blob/8fde8b3c615ffac0cf9ba82cbdb1fd716a4a7f8a/validation/standard/standard-versions-sepolia.toml#L26-L43)
(version 8.0.1).

| Chain | Chain ID | Respected game type | SystemConfigProxy |
|---|---|---|---|
| GIWA Sepolia Testnet | 91342 | PERMISSIONED_CANNON (1) → SUPER_PERMISSIONED (5) | [`0x8352825bA56C32d816Dd906Ad4A392B5BC9eC984`](https://github.com/ethereum-optimism/superchain-registry/blob/8fde8b3c615ffac0cf9ba82cbdb1fd716a4a7f8a/superchain/configs/sepolia/giwa.toml#L49) |

The upgrade moves GIWA's SuperchainConfig
(`0xEF3a8c9Ec7873C3ACEE4e6153fb66072cdE9032d`) to 2.4.3, `SystemConfig` to 4.0.0 and
`OptimismPortal2` to 5.8.0, clears the PERMISSIONED_CANNON (1) game implementation, installs
SUPER_PERMISSIONED (5, bondless, proposer-only) and re-anchors the `AnchorStateRegistry` to a
super root. GIWA Sepolia has no CANNON_KONA implementation to carry over, so SUPER_CANNON_KONA
(9) stays disabled and the chain stays permissioned on SUPER_PERMISSIONED (same shape as
sepolia-devnet-3 in [sep/107](../107-U20-sepolia-devnet-2-3/README.md)). Games created before the
upgrade keep resolving but no longer update the anchor.

The starting anchor is a single-chain super root at a finalized L2 block, derived on
2026-11-05 with the monorepo's `op-chain-ops/cmd/check-super-root` (block, timestamp and RPC in
[config.toml](./config.toml)). The anchor is part of the signed calldata and is fixed once it
is published.

## Simulation & Signing

This is a **nested** task: signers act through one of the ProxyAdminOwner's two owner safes, so
the child-safe argument (`DunamuUpgradeSafe` or `GIWASecurityCouncil`) is required.

```bash
cd src/tasks/sep/124-U20-giwa-sepolia

just simulate-stack sep 124-U20-giwa-sepolia DunamuUpgradeSafe   # or GIWASecurityCouncil

SKIP_DECODE_AND_PRINT=1 just sign-stack sep 124-U20-giwa-sepolia DunamuUpgradeSafe   # or GIWASecurityCouncil
```

## Execution

For facilitators, once both child safes have collected their signatures: approve once per
safe, then execute. Run the pre-execution checks in [VALIDATION.md](./VALIDATION.md) first.

```bash
cd src/tasks/sep/124-U20-giwa-sepolia

SIGNATURES=0x... just approve DunamuUpgradeSafe
SIGNATURES=0x... just approve GIWASecurityCouncil
just execute
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the signer
checklist, the calldata breakdown, the pre-execution checks, the expected state changes and
the post-execution checks.
