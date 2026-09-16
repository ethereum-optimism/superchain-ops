# 107-unichain-l1-ownership-transfers

Status: [DRAFT, NOT READY TO SIGN]

## Objective

For **Unichain Sepolia** (chainId 1301), transfer L1 ownership of the `ProxyAdmin` and the `DisputeGameFactory` from the Unichain Sepolia Safe to the standard OP-governed Sepolia L1PAO — the same 2-of-2 nested Safe (Foundation Upgrade Safe + Security Council) that owns OP Sepolia. This is the L1 half of the Sepolia dry run of the [Unichain ProxyAdmin Owner Transition to Standard Optimism Governance](https://app.notion.com/p/oplabs/EXTERNAL-Maintenance-Upgrade-Proposal-Unichain-ProxyAdmin-Owner-Transition-to-Standard-Optimism-Go-381f153ee16281efad21c307cef7c928) proposal (mainnet: [eth/069](https://github.com/ethereum-optimism/superchain-ops/pull/1527)); the L2 half is [108-unichain-l2pao-transfer](../108-unichain-l2pao-transfer/README.md), which executes after this task.

| Contract | Current owner | New owner |
|---|---|---|
| [`ProxyAdmin`](https://github.com/ethereum-optimism/superchain-registry/blob/848b7c912f02fb97403ea78a1a152ae7e181e6cc/superchain/extra/addresses/addresses.json#L187) `0x2BF403E5353A7a082ef6bb3Ae2Be3B866D8D3ea4` | [`0xd363339eE47775888Df411A163c586a8BdEA9dbf`](https://github.com/ethereum-optimism/superchain-registry/blob/848b7c912f02fb97403ea78a1a152ae7e181e6cc/superchain/configs/sepolia/unichain.toml#L47) (Unichain Sepolia Safe) | [`0x1Eb2fFc903729a0F03966B917003800b145F56E2`](https://github.com/ethereum-optimism/superchain-registry/blob/848b7c912f02fb97403ea78a1a152ae7e181e6cc/superchain/configs/sepolia/op.toml#L47) (OP-governed Sepolia L1PAO) |
| [`DisputeGameFactoryProxy`](https://github.com/ethereum-optimism/superchain-registry/blob/848b7c912f02fb97403ea78a1a152ae7e181e6cc/superchain/configs/sepolia/unichain.toml#L53) `0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b` | `0xd363339eE47775888Df411A163c586a8BdEA9dbf` (Unichain Sepolia Safe) | `0x1Eb2fFc903729a0F03966B917003800b145F56E2` (OP-governed Sepolia L1PAO) |

Unlike the mainnet 3-of-3, the Unichain Sepolia Safe is a flat 2-of-5 whose owners are EOAs, so its owners sign this task directly. No other Unichain Sepolia role changes (verified on-chain 2026-08-31): the [`DelayedWETH`](https://github.com/ethereum-optimism/superchain-registry/blob/848b7c912f02fb97403ea78a1a152ae7e181e6cc/superchain/extra/addresses/addresses.json#L173) is post-U16 and not ownable; `SuperchainConfig` and `Guardian` are already the standard OP Sepolia ones; the `Challenger` and the `SystemConfig` owner are Unichain-operated Safes, out of scope as operator roles.

> [!NOTE]
> Sepolia is not gated on governance and executes before the mainnet transition, which must wait for the special voting cycle and veto period.

## Simulation & Signing

This is a **single** task: the Unichain Sepolia Safe's owners are EOAs and sign directly, so no child-safe argument is needed.

```bash
cd src/tasks/sep/107-unichain-l1-ownership-transfers

# Simulate
just simulate-stack sep 107-unichain-l1-ownership-transfers

# Sign
SKIP_DECODE_AND_PRINT=1 just sign-stack sep 107-unichain-l1-ownership-transfers
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the calldata breakdown, and the expected state changes.
