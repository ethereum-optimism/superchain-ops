# 106-mmzd-l2pao-transfer: Transfer L2 ProxyAdmin Owner for Metal, Mode, Zora and Dust Sepolia

Status: READY TO SIGN

## Objective

Transfer the L2 ProxyAdmin Owner of Metal Sepolia (chainId 1740), Mode
Sepolia (chainId 919), Zora Sepolia (chainId 999999999) and Dust Testnet
(chainId 55377) to the L1-to-L2 alias of the chain operator's Safe, executing
the L2 half of the ownership handover for all four chains in a single task.
This is the Sepolia counterpart of `eth/068-mmzd-l2pao-transfer`.

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
> **Execute `105-mmzd-l1-ownership-transfers` first.** This task requires the
> L1 ProxyAdmin owner of every chain to already be the operator's Safe.

## Signing gates — do not sign until ALL are cleared

1. **Task 105 executed:** the per-chain `proxyAdmin.owner()` build-time checks
   only pass on-chain once task 105 has executed (local simulation pre-applies
   it via state overrides).
2. **Ordering / nonces:** the nonce pins in [config.toml](./config.toml) sit
   one ahead of the live values (L1PAO 55 / FUS 75 / SC 69), accounting for
   task 105. sep/104 (PR #1515) is FOS-signed and has no effect. Re-verify
   the live nonces immediately before signing and regenerate the
   [VALIDATION.md](./VALIDATION.md) hashes on any drift.

## Simulation & Signing

The root safe is the 2-of-2 nested L1PAO, so run each command once per child
safe (`foundation`, then `council`).

```bash
cd src/tasks/sep/106-mmzd-l2pao-transfer
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
checks (public RPCs: `https://testnet.rpc.metall2.com`,
`https://sepolia.mode.network`, `https://sepolia.rpc.zora.energy`,
`https://rpc-dust-testnet-0.t.conduit.xyz`).

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes
and state changes. Task inputs and the rationale for the address fallback,
alias derivation and state overrides are documented in
[config.toml](./config.toml).
