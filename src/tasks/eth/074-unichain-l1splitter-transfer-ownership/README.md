# 074-unichain-l1splitter-transfer-ownership

Status: [DRAFT, NOT READY TO SIGN]

## Objective

Unichain Mainnet migration, fee step 1 of 2: the current owner of the Unichain `L1Splitter`, the
Unichain SystemConfig owner Safe (`0x9245d5D10AA8a842B31530De71EA86c0760Ca1b1`, 3-of-5) through its L2 alias
(`0xa356d5D10aA8A842B31530dE71EA86c0760CB2C2`), starts the `Ownable2Step` handover to the aliased
L1PAO with one `OptimismPortal2.depositTransaction` carrying `transferOwnership(0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b)`.
`0x4300c0d3c0d3c0D3c0d3C0D3c0d3C0D3C0D30003` is Uniswap's `L1Splitter` (unichain-contracts `src/FeeSplitter/L1Splitter.sol`, `Ownable2Step`), the L1-fee leg of Unichain's FeeSplitter `0x4300c0D3c0d3c0d3c0d3c0d3C0D3c0d3c0d30001`. The L1PAO completes the handover in
[077-unichain-l1splitter-accept-and-configure](../077-unichain-l1splitter-accept-and-configure/README.md).

| Chain | Chain ID | L1Splitter (L2) | `pendingOwner()` |
|---|---|---|---|
| Unichain | 130 | `0x4300c0d3c0d3c0D3c0d3C0D3c0d3C0D3C0D30003` | `0x0000000000000000000000000000000000000000` → `0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b` (alias of [L1PAO](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/mainnet/unichain.toml#L58)) |

`owner()` stays `0xa356d5D10aA8A842B31530dE71EA86c0760CB2C2` until 079 executes.

## Simulation & Signing

This is a **single-safe** task executed directly by the Unichain SystemConfig owner Safe.

```bash
cd src/tasks/eth/074-unichain-l1splitter-transfer-ownership

just simulate-stack eth 074-unichain-l1splitter-transfer-ownership

SKIP_DECODE_AND_PRINT=1 just sign-stack eth 074-unichain-l1splitter-transfer-ownership
```

## Execution

For facilitators, once the Safe has collected its signatures. Run the pre-execution checks in
[VALIDATION.md](./VALIDATION.md) first. `just execute` refuses to run without `SIGNATURES`.

```bash
cd src/tasks/eth/074-unichain-l1splitter-transfer-ownership

SIGNATURES=0x... just execute
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the signer
checklist, the calldata breakdown, the pre-execution checks, the expected state changes and
the post-execution checks.
