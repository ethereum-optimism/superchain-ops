# 069-unichain-l1-ownership-transfers

Status: [DRAFT, NOT READY TO SIGN]

## Objective

Transfers L1 ownership (`ProxyAdmin` and `DisputeGameFactory`) of **Unichain
Mainnet** (chainId 130) from the Unichain 3-of-3 Safe to the standard
OP-governed mainnet L1PAO — the same 2-of-2 nested Safe (FoundationUpgradeSafe
+ SecurityCouncil) that owns OP Mainnet. This is the L1 half of the
transition; the L2 half is
[070-unichain-l2pao-transfer](../070-unichain-l2pao-transfer/README.md), which
executes after this task.

This executes the mainnet portion of the
[Maintenance Upgrade Proposal: Unichain ProxyAdmin Owner Transition to Standard Optimism Governance](https://app.notion.com/p/oplabs/EXTERNAL-Maintenance-Upgrade-Proposal-Unichain-ProxyAdmin-Owner-Transition-to-Standard-Optimism-Go-381f153ee16281efad21c307cef7c928),
removing the Chain Governor from the owner set in preparation for the interop
upgrade.

| Contract | Current owner | New owner |
|---|---|---|
| ProxyAdmin `0x3B73Fa8d82f511A3caE17B5a26E4E1a2d5E2f2A4` | `0x6d5B183F538ABB8572F5cD17109c617b994D5833` (Unichain 3-of-3) | `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (OP-governed L1PAO) |
| DisputeGameFactoryProxy `0x2F12d621a16e2d3285929C9996f478508951dFe4` | `0x6d5B183F538ABB8572F5cD17109c617b994D5833` (Unichain 3-of-3) | `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (OP-governed L1PAO) |

No other Unichain Mainnet role changes in this transition (verified on-chain
2026-08-25):

- `DelayedWETHProxy` (`0x74ad145aC900F1DD5551F0C9E143314DC4022FCf`) is
  post-U16 and not ownable — no ownership to transfer.
- `SuperchainConfig`, `Guardian` and `Challenger` are already the standard
  OP Mainnet ones (`0x95703e...4a4C`, `0x09f715...dAf2`, `0x9BA6e0...6b3A`).
- The `SystemConfig` owner (`0x9245d5D10AA8a842B31530De71EA86c0760Ca1b1`) is
  an operational role that stays with the chain operator and is out of scope
  for the governance proposal.

> [!WARNING]
> **Signing gate:** do not sign until the governance proposal has passed its
> special voting cycle and the standard veto period has elapsed.

## Simulation & Signing

This task is signed by Unichain's current ProxyAdminOwner, a nested 3-of-3 of
the Unichain Chain Governor Safe, the Foundation Upgrade Safe, and the
Security Council. Run the commands once for the safe you sign for, replacing
`<chain-governor|foundation|council>` accordingly.

```bash
cd src/tasks/eth/069-unichain-l1-ownership-transfers

# Simulate
just simulate-stack eth 069-unichain-l1-ownership-transfers <chain-governor|foundation|council>

# Sign
SKIP_DECODE_AND_PRINT=1 just sign-stack eth 069-unichain-l1-ownership-transfers <chain-governor|foundation|council>
```

> [!CAUTION]
> The Safe nonces are pinned in `config.toml`. Re-verify them against live
> on-chain values before signing — see [VALIDATION.md](./VALIDATION.md).

### For Facilitators, after signatures have been collected

```bash
cd src/tasks/eth/069-unichain-l1-ownership-transfers

# Approve once per safe, passing that safe's collected signatures
SIGNATURES=0x... just approve <chain-governor|foundation|council>

# Execute once all three safes have approved
just execute
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes,
the calldata breakdown, the expected state changes and the post-execution
checks. Task inputs and the rationale for the state overrides are documented
in [config.toml](./config.toml).
