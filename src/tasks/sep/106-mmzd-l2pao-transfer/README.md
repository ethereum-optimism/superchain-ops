# 106-mmzd-l2pao-transfer

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x75f08552c25869942dab85ea45e9eb97db56407d993eefeac728fd1b0f9d5230)

## Objective

Transfers the L2 ProxyAdmin owner of **Metal Sepolia** (chainId 1740), **Mode
Sepolia** (919), **Zora Sepolia** (999999999) and **Dust Testnet** (55377) to
the L1-to-L2 alias of the chain operator's Safe, in a single task. This is the
Sepolia counterpart of
[eth/068-mmzd-l2pao-transfer](../../eth/068-mmzd-l2pao-transfer/README.md) and
the L2 half of the handover started by
[105-mmzd-l1-ownership-transfers](../105-mmzd-l1-ownership-transfers/README.md).

| L2 ProxyAdmin `0x4200000000000000000000000000000000000018` (all four L2s) | Address |
|---|---|
| Current owner | `0x2FC3ffc903729a0f03966b917003800B145F67F3` (aliased L1PAO) |
| New owner | `0x45588C2Eb9018d5a6487bF0440838cd4238E9E03` (aliased operator Safe `0x34478c2eB9018d5A6487BF0440838Cd4238e8cf2`) |

The change is delivered as one deposit transaction per chain through that
chain's L1 OptimismPortal:

| Chain | OptimismPortalProxy |
|---|---|
| Metal Sepolia | `0x01D4dfC994878682811b2980653D03E589f093cB` |
| Mode Sepolia | `0x320e1580effF37E008F1C92700d1eBa47c1B23fD` |
| Zora Sepolia | `0xeffE2C6cA9Ab797D418f0D91eA60807713f3536f` |
| Dust Testnet | `0xe6230Bd9e96AD839D4c546710D9A99835052d1C1` |

> [!IMPORTANT]
> **Execute `105-mmzd-l1-ownership-transfers` first.** The template requires the
> L1 ProxyAdmin owner of every chain to already be the operator's Safe; the
> stacked simulation runs 105 first, and the on-chain execution must do the
> same.

## Simulation & Signing

Nested task: run each command with the child safe you sign through.

```bash
cd src/tasks/sep/106-mmzd-l2pao-transfer

just simulate-stack sep 106-mmzd-l2pao-transfer council   # or foundation

SKIP_DECODE_AND_PRINT=1 just sign-stack sep 106-mmzd-l2pao-transfer council   # or foundation
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the
calldata breakdown, the L2 replay, the expected state changes on L1 and L2, and
the post-execution checks.
