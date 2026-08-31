# 108-unichain-l2pao-transfer

Status: [DRAFT, NOT READY TO SIGN]

## Objective

For **Unichain Sepolia** (chainId 1301), transfer the L2 `ProxyAdmin` predeploy owner to the L1-to-L2 alias of the standard OP-governed Sepolia L1PAO, completing the Sepolia dry run of the [Unichain ProxyAdmin Owner Transition to Standard Optimism Governance](https://app.notion.com/p/oplabs/EXTERNAL-Maintenance-Upgrade-Proposal-Unichain-ProxyAdmin-Owner-Transition-to-Standard-Optimism-Go-381f153ee16281efad21c307cef7c928) proposal (mainnet: [eth/070](https://github.com/ethereum-optimism/superchain-ops/pull/1527)) started by [107-unichain-l1-ownership-transfers](../107-unichain-l1-ownership-transfers/README.md).

| L2 `ProxyAdmin` `0x4200000000000000000000000000000000000018` | Address |
|---|---|
| Current owner | `0xe474339ee47775888df411A163c586a8bDEaaEd0` — alias of the [Unichain Sepolia Safe](https://github.com/ethereum-optimism/superchain-registry/blob/848b7c912f02fb97403ea78a1a152ae7e181e6cc/superchain/configs/sepolia/unichain.toml#L47) `0xd363339eE47775888Df411A163c586a8BdEA9dbf` |
| New owner | `0x2FC3ffc903729a0f03966b917003800B145F67F3` — alias of the [OP-governed Sepolia L1PAO](https://github.com/ethereum-optimism/superchain-registry/blob/848b7c912f02fb97403ea78a1a152ae7e181e6cc/superchain/configs/sepolia/op.toml#L47) `0x1Eb2fFc903729a0F03966B917003800b145F56E2`, matching OP Sepolia's L2 ProxyAdmin owner |

The change is one deposit transaction through Unichain Sepolia's L1 [`OptimismPortal`](https://github.com/ethereum-optimism/superchain-registry/blob/848b7c912f02fb97403ea78a1a152ae7e181e6cc/superchain/configs/sepolia/unichain.toml#L51) `0x0d83dab629f0e0F9d36c0Cbc89B69a489f0751bD`, still sent by the Unichain Sepolia Safe — its alias owns the L2 predeploy until this deposit lands.

> [!IMPORTANT]
> **Execute `107-unichain-l1-ownership-transfers` first.** The template requires the L1 `ProxyAdmin` owner to already be the OP-governed Sepolia L1PAO; the stacked simulation runs 107 first, and the on-chain execution must do the same.

> [!NOTE]
> Sepolia is not gated on governance and executes before the mainnet transition, which must wait for the special voting cycle and veto period.

## Simulation & Signing

This is a **single** task: the Unichain Sepolia Safe's owners are EOAs and sign directly, so no child-safe argument is needed.

```bash
cd src/tasks/sep/108-unichain-l2pao-transfer

# Simulate
just simulate-stack sep 108-unichain-l2pao-transfer

# Sign
SKIP_DECODE_AND_PRINT=1 just sign-stack sep 108-unichain-l2pao-transfer
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the calldata breakdown, the L2 replay, and the expected state changes on L1 and L2.
