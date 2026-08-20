# 067-mmzd-l1-ownership-transfers

Status: [DRAFT, NOT READY TO SIGN]

## Objective

Transfers L1 ownership (`ProxyAdmin` and `DisputeGameFactory`) of **Metal
Mainnet** (chainId 1750), **Mode Mainnet** (34443), **Zora Mainnet** (7777777)
and **Dust Mainnet** (55378) from the L1 ProxyAdminOwner Safe to the chain
operator's Safe `0x4a4962275DF8C60a80d3a25faEc5AA7De116A746`.
This is the L1 half of the handover; the L2 half is
[068-mmzd-l2pao-transfer](../068-mmzd-l2pao-transfer/README.md), which executes
after this task.

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

The receiving Safe is a Gnosis Safe v1.3.0 designated by the chain
operator (Conduit), confirmed via email during task
preparation. It already owns Metal, Mode and Dust `SystemConfigProxy` 
contracts on mainnet. Ownership transfers can be reverse by the new owner only.

There is no SuperchainConfig or SystemConfig change, those are for the
operator to execute once it holds the ProxyAdmin.

## Simulation & Signing

Nested task: run each command with the child safe you sign through.

```bash
cd src/tasks/eth/067-mmzd-l1-ownership-transfers

just simulate-stack eth 067-mmzd-l1-ownership-transfers council   # or foundation

SKIP_DECODE_AND_PRINT=1 just sign-stack eth 067-mmzd-l1-ownership-transfers council   # or foundation
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the
calldata breakdown, the expected state changes and the post-execution checks.
