# Validation

This document can be used to validate the inputs and result of the execution of
the transaction which you are signing.

Task 070 transfers the L2 ProxyAdmin Owner for Unichain Mainnet (chainId 130)
to the L1-to-L2 alias of the OP-governed L1PAO
`0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`, via a deposit transaction through
the L1 OptimismPortal. The actual L2 state change (`L2 ProxyAdmin.owner` →
aliased new owner) happens after the deposit is included on L2 and cannot be
observed in the L1 simulation.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Transaction Inputs](#transaction-inputs)
3. [State Changes](#state-changes)
4. [Manual L2 verification](#manual-l2-verification-steps)

## Expected Domain and Message Hashes

> [!CAUTION]
>
> These hashes assume the pinned nonces below (see `config.toml`) — one ahead
> of the pins in task 069, accounting for the bump from that task, which
> executes first. The live baselines (verified 2026-08-25) are: Unichain
> 3-of-3 = 10, Chain Governor = 19, FUS = 66, SC = 64; the FUS/SC pins also
> carry +1 for task `066-soneium-fee-vault-recipient-update`:
> - Unichain 3-of-3 Safe:        **11** (live 10 + 1, task 069)
> - Unichain Chain Governor:     **20** (live 19 + 1, task 069)
> - FoundationUpgradeSafe:       **68** (live 66 + 1 task 066, + 1 task 069)
> - SecurityCouncil:             **66** (live 64 + 1 task 066, + 1 task 069)
>
> Before signing, re-verify each live nonce with
> `cast call <safe> "nonce()(uint256)" --rpc-url mainnet`. The pins apply
> whether or not task 069 has been signed yet, since the overrides mimic the
> post-069 state. If a nonce has advanced past the values above, bump the
> override in `config.toml` and re-simulate to regenerate these hashes.
>
> ### Unichain Chain Governor Safe (`0xb0c4C487C5cf6d67807Bc2008c66fa7e2cE744EC`)
>
> - Domain Hash:  `0x4f0b6efb6c01fa7e127a0ff87beefbeb53e056d30d3216c5ac70371b909ca66d`
> - Message Hash: `0xe2d1b1a28173296b9bbd2fe2058fa55bf3202bfa7a74de07573b677a32e6e6ed`
>
> ### FoundationUpgradeSafe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0x09c761ddf57ec5d4e262720b50f5de39e3d30dd8847be544b1d76e5f8a0400c7`
>
> ### SecurityCouncil (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash:  `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0x9c688f1002705854bfdec626e4d5fb1c8d7438218b84514104f95fe2d4e23960`

## Transaction Inputs

The transaction calls `OptimismPortalProxy.depositTransaction` with the
following arguments (decoded from the task calldata in `_data`):

- `_to`:         `0x4200000000000000000000000000000000000018` (L2 ProxyAdmin predeploy)
- `_value`:      `0`
- `_gasLimit`:   `200000`
- `_isCreation`: `false`
- `_data`:       `0xf2fde38b0000000000000000000000006b1bae59d09fccbddb6c6cceb07b7279367c4e3b`

The inner `transferOwnership(address)` payload targets
`0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b` — the L1-to-L2 alias of
`0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`. Verify by hand with:

```bash
cast calldata-decode "transferOwnership(address)" \
  0xf2fde38b0000000000000000000000006b1bae59d09fccbddb6c6cceb07b7279367c4e3b
# returns 0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b
```

## State Changes

The L1 simulation produces two state changes (the root Safe nonce and the
OptimismPortal deposit bookkeeping), plus the standard nested-execution
bookkeeping described below; the L2 state change happens after deposit
inclusion and must be checked manually (see below).

### Signer safes (nested-execution bookkeeping)

The approving child safe's nonce increments by 1 (Unichain Chain Governor
`20` → `21`, FoundationUpgradeSafe `68` → `69`, or SecurityCouncil `66` → `67`,
per the pinned overrides). During each child safe's approve step, the root
Unichain 3-of-3 also gains an
`approvedHashes[<child safe>][0x586752c373176aa3d4cc2b7aee615069cdbcdd5e2a29a572170c2e603a21f2af] = 1`
storage write — expect it in the Tenderly state diff of the approval
transactions.

---

### `0x6d5b183f538abb8572f5cd17109c617b994d5833` (Unichain 3-of-3 — parent multisig) — Chain ID: 1

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `11`
  - **After:**  `12`
  - **Summary:** nonce
  - **Detail:** Standard Gnosis Safe nonce bump. Starts at 11 because this
    task is stacked after task 069, which advances the live nonce 10 → 11.

---

### `0x0bd48f6b86a26d3a217d0fa6ffe2b491b956a7a2` (Unichain OptimismPortalProxy) — Chain ID: 130

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** OptimismPortal `params` slot — `prevBaseFee`, `prevBoughtGas`,
    and `prevBlockNum` are updated as part of bookkeeping for the new deposit;
    `_gasLimit = 200000 = 0x30d40` shows up in the middle word.
  - **Detail:** Slot 1 of OptimismPortalProxy packs the deposit-accounting
    parameters that `depositTransaction` updates on every call. The exact
    "Before"/"After" values depend on the simulation block; the constant
    `0x30d40` in the middle word matches the requested L2 gas limit (200,000).

The corresponding `TransactionDeposited(from, to, version, opaqueData)` log is
emitted by the OptimismPortal; verify in Tenderly that `from` is
`0x7E6c183F538abb8572F5cd17109C617b994d6944` (the aliased Unichain 3-of-3),
`to` is `0x4200000000000000000000000000000000000018`, and that the opaque data
encodes the `transferOwnership` payload above.

## Post-execution verification

The L2 change lands only once the deposit is relayed, so it cannot be confirmed
from L1. On Unichain Mainnet:

1. Find the deposit transaction from `0x7E6c183F538abb8572F5cd17109C617b994d6944`
   to the L2 ProxyAdmin predeploy `0x4200000000000000000000000000000000000018`.
2. Confirm it emitted `OwnershipTransferred` with `newOwner`
   `0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b`.
3. Confirm the final owner:
   ```bash
   cast call 0x4200000000000000000000000000000000000018 "owner()(address)" --rpc-url https://mainnet.unichain.org
   # Expected: 0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b
   ```
   This matches OP Mainnet's L2 ProxyAdmin owner.

## Task Calldata

```
0x174dea710000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000bd48f6b86a26d3a217d0fa6ffe2b491b956a7a20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c42000000000000000000000000420000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030d40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000006b1bae59d09fccbddb6c6cceb07b7279367c4e3b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
```

## Manual L2 Verification Steps

The L2 owner change lands only after the deposit is relayed. See
[Post-execution verification](#post-execution-verification) above for the
post-execution checks, and
[`docs/simulate-l2-ownership-transfer.md`](../../../../docs/simulate-l2-ownership-transfer.md)
for the full L2 deposit-simulation walkthrough (its worked example uses this
exact transfer: from alias `0x7E6c...6944`, new owner alias `0x6B1B...4E3b`).
