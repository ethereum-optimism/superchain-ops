# Validation

This document can be used to validate the inputs and result of the execution of
the transaction which you are signing.

Task 068 transfers the L2 ProxyAdmin Owner of Metal (chainId 1750), Mode
(chainId 34443), Zora (chainId 7777777) and Dust (chainId 55378) to the
L1-to-L2 alias of `0x4a4962275DF8C60a80d3a25faEc5AA7De116A746`, via one
deposit transaction per chain through that chain's L1 OptimismPortal. The
actual L2 state changes (`L2 ProxyAdmin.owner` → aliased new owner) happen
after each deposit is included on its L2 and cannot be observed in the L1
simulation.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Transaction Inputs](#transaction-inputs)
3. [State Changes](#state-changes)
4. [Manual L2 verification](#manual-l2-verification-steps)

## Expected Domain and Message Hashes

> [!CAUTION]
>
> These hashes assume the pinned nonces below — two ahead of the live on-chain
> values (read 2026-08-13: L1PAO=40 / FUS=66 / SC=64), accounting for the
> bumps from eth/066 and task 067:
> - Standard mainnet L1PAO Safe: **42**
> - FoundationUpgradeSafe:       **68**
> - SecurityCouncil:             **66**
>
> Before signing, re-verify each live nonce with
> `cast call <safe> "nonce()(uint256)" --rpc-url mainnet`. The pins apply
> whether or not eth/066 and task 067 have been signed yet, since the
> overrides mimic the post-067 state. If a nonce has advanced past the values
> above, bump the override in `config.toml` and re-simulate to regenerate
> these hashes.
>
> ### FoundationUpgradeSafe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0x71c885f2d8fe51616ba61e0235437924854f2e862d4cc0177e8e2f2a775920bb`
>
> ### SecurityCouncil (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash:  `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0x424a30762d12550ae37fee33fdccf6a8afe4944b5baba5bb7b6e7411cde24f5e`

## Transaction Inputs

The transaction calls each chain's `OptimismPortalProxy.depositTransaction`
(four calls total, one per chain) with identical arguments:

- `_to`:         `0x4200000000000000000000000000000000000018` (L2 ProxyAdmin predeploy)
- `_value`:      `0`
- `_gasLimit`:   `200000`
- `_isCreation`: `false`
- `_data`:       `0xf2fde38b0000000000000000000000005b5a62275df8c60a80d3a25faec5aa7de116b857`

The portals called (in calldata order):

| Chain | OptimismPortalProxy |
|---|---|
| Metal (1750) | `0x3F37aBdE2C6b5B2ed6F8045787Df1ED1E3753956` |
| Mode (34443) | `0x8B34b14c7c7123459Cf3076b8Cb929BE097d0C07` |
| Zora (7777777) | `0x1a0ad011913A150f69f6A19DF447A0CfD9551054` |
| Dust (55378) | `0xF573A6DA7a5b5dE9fbADfC26cFFC595ad04Dc7D4` |

The inner `transferOwnership(address)` payload targets
`0x5b5A62275DF8c60A80D3a25FAeC5aA7De116b857` — the L1-to-L2 alias of
`0x4a4962275DF8C60a80d3a25faEc5AA7De116A746`. Verify by hand with:

```bash
cast calldata-decode "transferOwnership(address)" \
  0xf2fde38b0000000000000000000000005b5a62275df8c60a80d3a25faec5aa7de116b857
# returns 0x5b5A62275DF8c60A80D3a25FAeC5aA7De116b857
```

## State Changes

The L1 simulation produces five state changes (the root Safe nonce and one
OptimismPortal deposit-bookkeeping write per chain), plus the standard
nested-execution bookkeeping described below; the L2 state changes happen
after deposit inclusion and must be checked manually (see below).

### Signer safes (nested-execution bookkeeping)

The approving child safe's nonce increments by 1 (FoundationUpgradeSafe
`68` → `69`, or SecurityCouncil `66` → `67`, per the pinned overrides).
During each child safe's approve step, the root L1PAO also gains an
`approvedHashes[<child safe>][0x12b35b0929f871f853e244771307512a9e1f24e811a22bef66a88866a81ad5d1] = 1`
storage write — expect it in the Tenderly state diff of the approval
transactions.

> Note: the simulation also applies the four ProxyAdmin slot `0x00` overrides
> declared in `config.toml`. Those overrides pre-apply task 067's L1 ownership
> transfers so the template's per-chain `proxyAdmin.owner() == newOwnerToAlias`
> check passes; they do not produce state changes at signing time (the actual
> transitions are performed by task 067).

---

### `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a` (Standard mainnet L1PAO Safe — parent multisig) — Chain ID: 1

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `42`
  - **After:**  `43`
  - **Summary:** nonce
  - **Detail:** Standard Gnosis Safe nonce bump. Starts at 42 because this
    task is stacked after eth/066 and task 067, which advance the live nonce
    40 → 42.

---

### OptimismPortalProxy `params` slot (one write per chain)

Each of the four portals updates its slot `0x01` — the packed
`ResourceMetering.ResourceParams` (`prevBaseFee`, `prevBoughtGas`,
`prevBlockNum`) bookkeeping that `depositTransaction` updates on every call:

- `0x3f37abde2c6b5b2ed6f8045787df1ed1e3753956` (Metal OptimismPortalProxy) — Chain ID: 1750
- `0x8b34b14c7c7123459cf3076b8cb929be097d0c07` (Mode OptimismPortalProxy) — Chain ID: 34443
- `0x1a0ad011913a150f69f6a19df447a0cfd9551054` (Zora OptimismPortalProxy) — Chain ID: 7777777
- `0xf573a6da7a5b5de9fbadfc26cffc595ad04dc7d4` (Dust OptimismPortalProxy) — Chain ID: 55378

The exact "Before"/"After" values depend on the simulation block; the
constant `0x30d40` in the middle word matches the requested L2 gas limit
(200,000).

Each portal also emits a `TransactionDeposited(from, to, version, opaqueData)`
log; verify in Tenderly that there are exactly four, that `from` is
`0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b` (the aliased current L1PAO),
that `to` is `0x4200000000000000000000000000000000000018`, and that the
opaque data encodes the `transferOwnership` payload above.

## Post-execution verification

The L2 changes land only once each deposit is relayed, so they cannot be
confirmed from L1. On each L2:

1. Find the deposit transaction from `0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b`
   to the L2 ProxyAdmin predeploy `0x4200000000000000000000000000000000000018`.
2. Confirm it emitted `OwnershipTransferred` with `newOwner`
   `0x5b5A62275DF8c60A80D3a25FAeC5aA7De116b857`.
3. Confirm the final owner:
   ```bash
   cast call 0x4200000000000000000000000000000000000018 "owner()(address)" --rpc-url https://rpc.metall2.com
   cast call 0x4200000000000000000000000000000000000018 "owner()(address)" --rpc-url https://mainnet.mode.network
   cast call 0x4200000000000000000000000000000000000018 "owner()(address)" --rpc-url https://rpc.zora.energy
   cast call 0x4200000000000000000000000000000000000018 "owner()(address)" --rpc-url https://rpc-dust-mainnet-0.t.conduit.xyz
   # All expected: 0x5b5A62275DF8c60A80D3a25FAeC5aA7De116b857
   ```
4. Ask the chain operator to confirm receipt of ownership through the shared
   channel.

## Task Calldata

```
0x174dea710000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000240000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000005c00000000000000000000000003f37abde2c6b5b2ed6f8045787df1ed1e37539560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c42000000000000000000000000420000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030d40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000005b5a62275df8c60a80d3a25faec5aa7de116b85700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008b34b14c7c7123459cf3076b8cb929be097d0c070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c42000000000000000000000000420000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030d40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000005b5a62275df8c60a80d3a25faec5aa7de116b85700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a0ad011913a150f69f6a19df447a0cfd95510540000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c42000000000000000000000000420000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030d40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000005b5a62275df8c60a80d3a25faec5aa7de116b8570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f573a6da7a5b5de9fbadfc26cffc595ad04dc7d40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c42000000000000000000000000420000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030d40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000005b5a62275df8c60a80d3a25faec5aa7de116b8570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
```

## Manual L2 Verification Steps

The L2 owner changes land only after each deposit is relayed. See
[README.md](./README.md) for the post-execution checks, and
[`docs/simulate-l2-ownership-transfer.md`](../../../../docs/simulate-l2-ownership-transfer.md)
for the full L2 deposit-simulation walkthrough — repeat it for each of the
four `TransactionDeposited` events, selecting the corresponding L2 network in
Tenderly each time.
