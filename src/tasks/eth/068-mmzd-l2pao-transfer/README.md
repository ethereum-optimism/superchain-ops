# 068-mmzd-l2pao-transfer: Transfer L2 ProxyAdmin Owner for Metal, Mode, Zora and Dust Mainnet

Status: READY TO SIGN

## Objective

Transfer the L2 ProxyAdmin Owner of Metal Mainnet (chainId 1750), Mode
Mainnet (chainId 34443), Zora Mainnet (chainId 7777777) and Dust Mainnet
(chainId 55378) to the L1-to-L2 alias of the chain operator's Safe, executing
the L2 half of the ownership handover for all four chains in a single task.

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
> **Execute `067-mmzd-l1-ownership-transfers` first.** This task requires the
> L1 ProxyAdmin owner of every chain to already be the operator's Safe.

## Signing gates — do not sign until ALL are cleared

1. **Governance:** the single governance post covering the Dust, Mode, Metal
   and Zora handover on both networks must be approved. Record the proposal
   link and its outcome here before signing.
2. **Task 067 executed:** the per-chain `proxyAdmin.owner()` build-time checks
   only pass on-chain once task 067 has executed (local simulation pre-applies
   it via state overrides).
3. **Ordering / nonces:** the nonce pins in [config.toml](./config.toml) sit
   two ahead of the live values (L1PAO 42 / FUS 68 / SC 66), accounting for
   eth/066 and task 067, both L1PAO-signed. Re-verify the live nonces
   immediately before signing and regenerate the
   [VALIDATION.md](./VALIDATION.md) hashes on any drift.

## Simulation & Signing

The root safe is the 2-of-2 nested L1PAO, so run each command once per child
safe (`foundation`, then `council`).

```bash
cd src/tasks/eth/068-mmzd-l2pao-transfer
SIMULATE_WITHOUT_LEDGER=1 just simulate <foundation|council>
# then, to sign:
just sign <foundation|council>
```

> [!CAUTION]
> The Safe nonces are pinned in `config.toml`. Re-verify them against live
> on-chain values before signing — see [VALIDATION.md](./VALIDATION.md).

For extra assurance on the L2 deposits before signing, follow
[`docs/simulate-l2-ownership-transfer.md`](../../../../docs/simulate-l2-ownership-transfer.md)
for each of the four `TransactionDeposited` events and record the results in
`VALIDATION.md`.

## Post-execution verification

The L2 changes land only once each deposit is relayed — see
[VALIDATION.md](./VALIDATION.md#post-execution-verification) for the per-chain
checks (public RPCs: `https://rpc.metall2.com`,
`https://mainnet.mode.network`, `https://rpc.zora.energy`,
`https://rpc-dust-mainnet-0.t.conduit.xyz`).

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes
and state changes. Task inputs and the rationale for the address fallback,
alias derivation and state overrides are documented in
[config.toml](./config.toml).
