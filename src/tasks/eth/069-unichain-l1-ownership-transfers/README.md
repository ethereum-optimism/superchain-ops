# 069-unichain-l1-ownership-transfers

Status: [DRAFT, NOT READY TO SIGN]

## Objective

For **Unichain Mainnet** (chainId 130), transfer L1 ownership of the `ProxyAdmin` and the `DisputeGameFactory` from the Unichain 3-of-3 Safe to the standard OP-governed L1PAO — the same 2-of-2 nested Safe (Foundation Upgrade Safe + Security Council) that owns OP Mainnet. This is the L1 half of the [Unichain ProxyAdmin Owner Transition to Standard Optimism Governance](https://app.notion.com/p/oplabs/EXTERNAL-Maintenance-Upgrade-Proposal-Unichain-ProxyAdmin-Owner-Transition-to-Standard-Optimism-Go-381f153ee16281efad21c307cef7c928) proposal; the L2 half is [070-unichain-l2pao-transfer](../070-unichain-l2pao-transfer/README.md), which executes after this task.

| Contract | Current owner | New owner |
|---|---|---|
| [`ProxyAdmin`](https://github.com/ethereum-optimism/superchain-registry/blob/848b7c912f02fb97403ea78a1a152ae7e181e6cc/superchain/extra/addresses/addresses.json#L161) `0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4` | [`0x6d5B183F538ABB8572F5cD17109c617b994D5833`](https://github.com/ethereum-optimism/superchain-registry/blob/848b7c912f02fb97403ea78a1a152ae7e181e6cc/superchain/configs/mainnet/unichain.toml#L46) (Unichain 3-of-3) | [`0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`](https://github.com/ethereum-optimism/superchain-registry/blob/848b7c912f02fb97403ea78a1a152ae7e181e6cc/superchain/configs/mainnet/op.toml#L46) (OP-governed L1PAO) |
| [`DisputeGameFactoryProxy`](https://github.com/ethereum-optimism/superchain-registry/blob/848b7c912f02fb97403ea78a1a152ae7e181e6cc/superchain/configs/mainnet/unichain.toml#L52) `0x2F12d621a16e2d3285929C9996f478508951dFe4` | `0x6d5B183F538ABB8572F5cD17109c617b994D5833` (Unichain 3-of-3) | `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (OP-governed L1PAO) |

The 3-of-3's child safes ([`chain-governor`, `foundation`, `council`](../../../addresses.toml)) sign this task. No other Unichain role changes (verified on-chain 2026-08-25): the [`DelayedWETH`](https://github.com/ethereum-optimism/superchain-registry/blob/848b7c912f02fb97403ea78a1a152ae7e181e6cc/superchain/extra/addresses/addresses.json#L147) is post-U16 and not ownable; `SuperchainConfig`, `Guardian` and `Challenger` are already the standard OP Mainnet ones; the `SystemConfig` owner is an operator role, out of scope per the governance post.

> [!WARNING]
> Do not sign until the governance proposal has passed its special voting cycle and the standard veto period has elapsed.

## Simulation & Signing

This is a **nested** task: signers act through one of the 3-of-3's three owner safes, so the child-safe argument (`chain-governor`, `foundation` or `council`) is required.

```bash
cd src/tasks/eth/069-unichain-l1-ownership-transfers

# Simulate with your safe
just simulate-stack eth 069-unichain-l1-ownership-transfers chain-governor
just simulate-stack eth 069-unichain-l1-ownership-transfers foundation
just simulate-stack eth 069-unichain-l1-ownership-transfers council

# Sign with your safe
SKIP_DECODE_AND_PRINT=1 just sign-stack eth 069-unichain-l1-ownership-transfers chain-governor
SKIP_DECODE_AND_PRINT=1 just sign-stack eth 069-unichain-l1-ownership-transfers foundation
SKIP_DECODE_AND_PRINT=1 just sign-stack eth 069-unichain-l1-ownership-transfers council
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the calldata breakdown, and the expected state changes.
