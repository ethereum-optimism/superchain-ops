# 070-unichain-l2pao-transfer

Status: [DRAFT, NOT READY TO SIGN]

## Objective

For **Unichain Mainnet** (chainId 130), transfer the L2 `ProxyAdmin` predeploy owner to the L1-to-L2 alias of the standard OP-governed L1PAO, completing the [Unichain ProxyAdmin Owner Transition to Standard Optimism Governance](https://app.notion.com/p/oplabs/EXTERNAL-Maintenance-Upgrade-Proposal-Unichain-ProxyAdmin-Owner-Transition-to-Standard-Optimism-Go-381f153ee16281efad21c307cef7c928) proposal started by [069-unichain-l1-ownership-transfers](../069-unichain-l1-ownership-transfers/README.md).

| L2 `ProxyAdmin` `0x4200000000000000000000000000000000000018` | Address |
|---|---|
| Current owner | `0x7E6c183F538abb8572F5cd17109C617b994d6944` — alias of the [Unichain 3-of-3](https://github.com/ethereum-optimism/superchain-registry/blob/848b7c912f02fb97403ea78a1a152ae7e181e6cc/superchain/configs/mainnet/unichain.toml#L46) `0x6d5B183F538ABB8572F5cD17109c617b994D5833` |
| New owner | `0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b` — alias of the [OP-governed L1PAO](https://github.com/ethereum-optimism/superchain-registry/blob/848b7c912f02fb97403ea78a1a152ae7e181e6cc/superchain/configs/mainnet/op.toml#L46) `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`, matching OP Mainnet's L2 ProxyAdmin owner |

The change is one deposit transaction through Unichain's L1 [`OptimismPortal`](https://github.com/ethereum-optimism/superchain-registry/blob/848b7c912f02fb97403ea78a1a152ae7e181e6cc/superchain/configs/mainnet/unichain.toml#L50) `0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2`, still sent by the Unichain 3-of-3 — its alias owns the L2 predeploy until this deposit lands.

> [!IMPORTANT]
> **Execute `069-unichain-l1-ownership-transfers` first.** The template requires the L1 `ProxyAdmin` owner to already be the OP-governed L1PAO; the stacked simulation runs 069 first, and the on-chain execution must do the same.

> [!WARNING]
> Do not sign until the governance proposal has passed its special voting cycle and the standard veto period has elapsed.

## Simulation & Signing

This is a **nested** task: signers act through one of the 3-of-3's three owner safes, so the child-safe argument (`chain-governor`, `foundation` or `council`) is required.

```bash
cd src/tasks/eth/070-unichain-l2pao-transfer

# Simulate with your safe
just simulate-stack eth 070-unichain-l2pao-transfer chain-governor
just simulate-stack eth 070-unichain-l2pao-transfer foundation
just simulate-stack eth 070-unichain-l2pao-transfer council

# Sign with your safe
SKIP_DECODE_AND_PRINT=1 just sign-stack eth 070-unichain-l2pao-transfer chain-governor
SKIP_DECODE_AND_PRINT=1 just sign-stack eth 070-unichain-l2pao-transfer foundation
SKIP_DECODE_AND_PRINT=1 just sign-stack eth 070-unichain-l2pao-transfer council
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the calldata breakdown, the L2 replay, and the expected state changes on L1 and L2.
