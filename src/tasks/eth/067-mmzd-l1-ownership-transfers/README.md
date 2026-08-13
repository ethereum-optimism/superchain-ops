# 067-mmzd-l1-ownership-transfers: Transfer L1 owners for Metal, Mode, Zora and Dust Mainnet (ProxyAdmin + DisputeGameFactory)

Status: READY TO SIGN

## Objective

Transfer L1 ownership of Metal Mainnet (chainId 1750), Mode Mainnet
(chainId 34443), Zora Mainnet (chainId 7777777) and Dust Mainnet
(chainId 55378) to the chain operator's designated Safe
`0x4a4962275DF8C60a80d3a25faEc5AA7De116A746`, executing the L1 half of the
ownership handover for all four chains in a single task.

| Chain | Contract | Current owner | New owner |
|---|---|---|---|
| Metal | ProxyAdmin `0x37Ff0ae34dadA1A95A4251d10ef7Caa868c7AC99` | `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (L1PAO) | `0x4a4962275DF8C60a80d3a25faEc5AA7De116A746` |
| Metal | DisputeGameFactoryProxy `0x7BFfF391A2dbbDc68A259792AC9748F50FcDE93E` | `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (L1PAO) | `0x4a4962275DF8C60a80d3a25faEc5AA7De116A746` |
| Mode | ProxyAdmin `0x470d87b1dae09a454A43D1fD772A561a03276aB7` | `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (L1PAO) | `0x4a4962275DF8C60a80d3a25faEc5AA7De116A746` |
| Mode | DisputeGameFactoryProxy `0x6f13EFadABD9269D6cEAd22b448d434A1f1B433E` | `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (L1PAO) | `0x4a4962275DF8C60a80d3a25faEc5AA7De116A746` |
| Zora | ProxyAdmin `0xD4ef175B9e72cAEe9f1fe7660a6Ec19009903b49` | `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (L1PAO) | `0x4a4962275DF8C60a80d3a25faEc5AA7De116A746` |
| Zora | DisputeGameFactoryProxy `0xB0F15106fa1e473Ddb39790f197275BC979Aa37e` | `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (L1PAO) | `0x4a4962275DF8C60a80d3a25faEc5AA7De116A746` |
| Dust | ProxyAdmin `0x32C61Bd2B7bf8E50F448331705eDDA99244e7339` | `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (L1PAO) | `0x4a4962275DF8C60a80d3a25faEc5AA7De116A746` |
| Dust | DisputeGameFactoryProxy `0xFcD88154a329557499535E7c803f3B3BD7FA1115` | `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (L1PAO) | `0x4a4962275DF8C60a80d3a25faEc5AA7De116A746` |

All current owners verified on-chain 2026-08-13. There is no DelayedWETH
transfer on any chain — see [config.toml](./config.toml).

**Receiving Safe provenance:** `0x4a4962275DF8C60a80d3a25faEc5AA7De116A746`
is a 4-of-10 Gnosis Safe v1.3.0 on Ethereum Mainnet, designated by the chain
operator (Conduit) as the receiving Safe for all four chains on mainnet, and
confirmed against Conduit's address document plus the address set exchanged
over email (`support@conduit.xyz`) for a persistent record. The same Safe
already owns the Metal, Mode and Dust `SystemConfigProxy` contracts on
mainnet.

The follow-up L2 ProxyAdmin transfers are `068-mmzd-l2pao-transfer`, which
must be executed after this task. The `SuperchainConfig` repoint and any
`SystemConfig` changes are out of scope — they will be executed by the
operator once it holds the ProxyAdmin.

## Signing gates — do not sign until ALL are cleared

1. **Governance:** the single governance post covering the Dust, Mode, Metal
   and Zora handover on both networks must be approved. Record the proposal
   link and its outcome here before signing.
2. **Receiving Safe verification:** re-confirm
   `0x4a4962275DF8C60a80d3a25faEc5AA7De116A746` (including its owner set) with
   the chain operator through an authenticated channel, and verify it against
   this README with ≥2 OP Labs engineers. Ownership transfers are
   irreversible.
3. **Ordering / nonces:** this task is numbered after
   [eth/065](https://github.com/ethereum-optimism/superchain-ops/pull/1515)
   and [eth/066](https://github.com/ethereum-optimism/superchain-ops/pull/1520)
   and is planned to execute after them. eth/066 is **L1PAO-signed**, so the
   nonce pins in [config.toml](./config.toml) sit one ahead of the live values
   (L1PAO 41 / FUS 67 / SC 65); eth/065 is FOS-signed and has no effect.
   Re-verify the live nonces immediately before signing and regenerate the
   [VALIDATION.md](./VALIDATION.md) hashes on any drift.

## Simulation & Signing

The root safe is the 2-of-2 nested L1PAO, so run each command once per child
safe (`foundation`, then `council`).

```bash
cd src/tasks/eth/067-mmzd-l1-ownership-transfers
SIMULATE_WITHOUT_LEDGER=1 just simulate <foundation|council>
# then, to sign:
just sign <foundation|council>
```

> [!CAUTION]
> The Safe nonces are pinned in `config.toml`. Re-verify them against live
> on-chain values before signing — see [VALIDATION.md](./VALIDATION.md).

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes
and state changes. Task inputs and the rationale for the address fallback and
nonce overrides are documented in [config.toml](./config.toml).
