# 070-unichain-l2pao-transfer

Status: [DRAFT, NOT READY TO SIGN]

## Objective

Transfers the L2 ProxyAdmin owner of **Unichain Mainnet** (chainId 130) to the
L1-to-L2 alias of the standard OP-governed mainnet L1PAO. This is the L2 half
of the transition started by
[069-unichain-l1-ownership-transfers](../069-unichain-l1-ownership-transfers/README.md),
completing the mainnet portion of the
[Maintenance Upgrade Proposal: Unichain ProxyAdmin Owner Transition to Standard Optimism Governance](https://app.notion.com/p/oplabs/EXTERNAL-Maintenance-Upgrade-Proposal-Unichain-ProxyAdmin-Owner-Transition-to-Standard-Optimism-Go-381f153ee16281efad21c307cef7c928).

| L2 ProxyAdmin `0x4200000000000000000000000000000000000018` | Address |
|---|---|
| Current owner | `0x7E6c183F538abb8572F5cd17109C617b994d6944` (aliased Unichain 3-of-3) |
| New owner | `0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b` (aliased OP-governed L1PAO `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`) |

The change is delivered as a deposit transaction through Unichain's L1
OptimismPortal `0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2`. The L2 ProxyAdmin
owner after this task matches OP Mainnet's L2 ProxyAdmin owner.

> [!IMPORTANT]
> **Execute `069-unichain-l1-ownership-transfers` first.** The template
> requires the L1 ProxyAdmin owner to already be the OP-governed L1PAO; the
> stacked simulation runs 069 first, and the on-chain execution must do the
> same. This task is still signed by the Unichain 3-of-3 — its alias owns the
> L2 ProxyAdmin predeploy until this deposit lands.

> [!WARNING]
> **Signing gate:** do not sign until the governance proposal has passed its
> special voting cycle and the standard veto period has elapsed.

## Simulation & Signing

This task is signed by the Unichain 3-of-3, a nested Safe of the Unichain
Chain Governor Safe, the Foundation Upgrade Safe, and the Security Council.
Run the commands once for the safe you sign for, replacing
`<chain-governor|foundation|council>` accordingly.

```bash
cd src/tasks/eth/070-unichain-l2pao-transfer

# Simulate
just simulate-stack eth 070-unichain-l2pao-transfer <chain-governor|foundation|council>

# Sign
SKIP_DECODE_AND_PRINT=1 just sign-stack eth 070-unichain-l2pao-transfer <chain-governor|foundation|council>
```

> [!CAUTION]
> The Safe nonces are pinned in `config.toml`. Re-verify them against live
> on-chain values before signing — see [VALIDATION.md](./VALIDATION.md).

For extra assurance on the L2 deposit before signing, follow
[`docs/simulate-l2-ownership-transfer.md`](../../../../docs/simulate-l2-ownership-transfer.md)
and record the result in `VALIDATION.md`.

### For Facilitators, after signatures have been collected

```bash
cd src/tasks/eth/070-unichain-l2pao-transfer

# Approve once per safe, passing that safe's collected signatures
SIGNATURES=0x... just approve <chain-governor|foundation|council>

# Execute once all three safes have approved
just execute
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes,
the calldata breakdown, the expected state changes on L1 and L2, and the
post-execution checks. Task inputs and the rationale for the root-safe pin and
state overrides are documented in [config.toml](./config.toml).
