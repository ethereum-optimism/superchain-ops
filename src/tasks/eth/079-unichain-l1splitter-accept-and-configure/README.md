# 079-unichain-l1splitter-accept-and-configure

Status: [DRAFT, NOT READY TO SIGN]

## Objective

Unichain Mainnet migration, fee step 2 of 2: the L1PAO accepts ownership of the Unichain
`L1Splitter` started by [076-unichain-l1splitter-transfer-ownership](../076-unichain-l1splitter-transfer-ownership/README.md),
points its L1 recipient at the OP Enterprise cost recipient and lowers its minimum withdrawal, with
three `OptimismPortal2.depositTransaction` calls executed on L2 by the aliased L1PAO
(`0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b`). `0x4300c0d3c0d3c0D3c0d3C0D3c0d3C0D3C0D30003` is Uniswap's `L1Splitter` (unichain-contracts `src/FeeSplitter/L1Splitter.sol`, `Ownable2Step`), the L1-fee leg of Unichain's FeeSplitter `0x4300c0D3c0d3c0d3c0d3c0d3C0D3c0d3c0d30001`. The disbursement interval (24h) is unchanged.

| Chain | Chain ID | L1Splitter (L2) | Field | Change |
|---|---|---|---|---|
| Unichain | 130 | `0x4300c0d3c0d3c0D3c0d3C0D3c0d3C0D3C0D30003` | `owner()` | `0xa356d5D10aA8A842B31530dE71EA86c0760CB2C2` → `0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b` |
| | | | `l1Recipient()` | `0x7078c4537C04c2b2E52ddBa06074dBdACF23cA15` → `0xdead000000000000000000000000000000000004` |
| | | | `minWithdrawalAmount()` | 10 ETH → 0.15 ETH (the eth/062 cost-vault value) |

> [!WARNING]
> This task contains **placeholder** values, so it stays DRAFT and its hashes and calldata are
> not signable. Replace them in [config.toml](./config.toml), re-run the simulation and
> regenerate [VALIDATION.md](./VALIDATION.md):
>   - `0xdead000000000000000000000000000000000004`: OPE cost recipient (L1)

> [!IMPORTANT]
> `pendingOwner()` is set by eth/076. Until that deposit is relayed, [config.toml](./config.toml) sets `simulatePendingOwnerTransfer = true` so the template simulates it on the L2 fork; remove the flag once `pendingOwner()` returns the aliased L1PAO. If eth/076 never landed, these deposits revert on L2.

> [!IMPORTANT]
> Mainnet L1PAO actions on Unichain go through a Maintenance Upgrade governance post (as eth/061 and eth/062 did for Ink); signing is gated on it.

## Simulation & Signing

This is a **nested** task: signers act through one of the L1PAO's two owner safes, so the
child-safe argument (`council` or `foundation`) is required.

```bash
cd src/tasks/eth/079-unichain-l1splitter-accept-and-configure

just simulate-stack eth 079-unichain-l1splitter-accept-and-configure council   # or foundation

SKIP_DECODE_AND_PRINT=1 just sign-stack eth 079-unichain-l1splitter-accept-and-configure council   # or foundation
```

## Execution

For facilitators, once both child safes have collected their signatures: approve once per safe,
then execute. Run the pre-execution checks in [VALIDATION.md](./VALIDATION.md) first.

```bash
cd src/tasks/eth/079-unichain-l1splitter-accept-and-configure

SIGNATURES=0x... just approve council
SIGNATURES=0x... just approve foundation
just execute
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the signer
checklist, the calldata breakdown, the pre-execution checks, the expected state changes and
the post-execution checks.
