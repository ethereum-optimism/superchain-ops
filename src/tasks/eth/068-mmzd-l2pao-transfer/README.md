# 068-mmzd-l2pao-transfer

Status: [DRAFT, NOT READY TO SIGN]

Governance: link the approved proposal covering the Metal/Mode/Zora/Dust handover
here, then set the status to READY TO SIGN.

## Objective

Transfers the L2 ProxyAdmin owner of **Metal Mainnet** (chainId 1750), **Mode
Mainnet** (34443), **Zora Mainnet** (7777777) and **Dust Mainnet** (55378) to
the L1-to-L2 alias of the chain operator's Safe, in a single task. This is the
L2 half of the handover started by
[067-mmzd-l1-ownership-transfers](../067-mmzd-l1-ownership-transfers/README.md).

| L2 ProxyAdmin `0x4200000000000000000000000000000000000018` (all four L2s) | Address |
|---|---|
| Current owner | `0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b` (aliased L1PAO) |
| New owner | `0x5b5A62275DF8c60A80D3a25FAeC5aA7De116b857` (aliased operator Safe `0x4a4962275DF8C60a80d3a25faEc5AA7De116A746`) |

The change is delivered as one deposit transaction per chain through that
chain's L1 OptimismPortal:

| Chain | OptimismPortalProxy |
|---|---|
| Metal | `0x3F37aBdE2C6b5B2ed6F8045787Df1ED1E3753956` |
| Mode | `0x8B34b14c7c7123459Cf3076b8Cb929BE097d0C07` |
| Zora | `0x1a0ad011913A150f69f6A19DF447A0CfD9551054` |
| Dust | `0xF573A6DA7a5b5dE9fbADfC26cFFC595ad04Dc7D4` |

> [!IMPORTANT]
> **Execute `067-mmzd-l1-ownership-transfers` first.** The template requires the
> L1 ProxyAdmin owner of every chain to already be the operator's Safe; the
> stacked simulation runs 067 first, and the on-chain execution must do the
> same.

## Simulation & Signing

Nested task: run each command with the child safe you sign through.

```bash
cd src/tasks/eth/068-mmzd-l2pao-transfer

just simulate-stack eth 068-mmzd-l2pao-transfer council   # or foundation

SKIP_DECODE_AND_PRINT=1 just sign-stack eth 068-mmzd-l2pao-transfer council   # or foundation
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the
calldata breakdown, the L2 replay, the expected state changes on L1 and L2, and
the post-execution checks.
