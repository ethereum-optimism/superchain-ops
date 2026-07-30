# Validation

This document can be used to validate the inputs and result of the execution of
the transaction which you are signing.

Task 064 transfers the L2 ProxyAdmin Owner for Swell Mainnet (chainId 1923)
to the L1-to-L2 alias of `0xa83F1334c6a8Daca576Dc14020d9d2b1b16a8Dfa`, via a
deposit transaction through the L1 OptimismPortal. The actual L2 state change
(`L2 ProxyAdmin.owner` → aliased new owner) happens after the deposit is
included on L2 and cannot be observed in the L1 simulation.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Transaction Inputs](#transaction-inputs)
3. [State Changes](#state-changes)
4. [Manual L2 verification](#manual-l2-verification-steps)

## Expected Domain and Message Hashes

> [!CAUTION]
>
> Pinned at the following nonces (see `config.toml` `stateOverrides`), each
> three ahead of the on-chain values (read 2026-07-30: L1PAO=36 / FUS=62 /
> SC=60) to account for the two READY-TO-SIGN Ink tasks queued ahead
> (`eth/061`, `eth/062`) plus task 063 of this pair:
> - Standard mainnet L1PAO Safe: **39**
> - FoundationUpgradeSafe:       **65**
> - SecurityCouncil:             **63**
>
> All three Safes are shared across many mainnet chains. Before signing,
> re-verify the live nonces with
> `cast call <safe> "nonce()" --rpc-url mainnet` and your ledger. If task 063
> has not yet been signed when you simulate this one, the pinned values still
> apply (the override mimics the post-063 state); if anything else has
> advanced the live nonces in the meantime, bump the corresponding override
> and re-simulate so the hashes below are regenerated.
>
> ### FoundationUpgradeSafe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0x334e4c2b39031202af9c3402f920fcaef14aaa65e0c39142808f09f4d9a97a92`
>
> ### SecurityCouncil (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash:  `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0xcffb5105d1df196321c6aa8da8a266db997bf4698e5f421b795379812de54224`

## Transaction Inputs

The transaction calls `OptimismPortalProxy.depositTransaction` with the
following arguments (decoded from the task calldata in `_data`):

- `_to`:         `0x4200000000000000000000000000000000000018` (L2 ProxyAdmin predeploy)
- `_value`:      `0`
- `_gasLimit`:   `200000`
- `_isCreation`: `false`
- `_data`:       `0xf2fde38b000000000000000000000000b9501334c6a8daca576dc14020d9d2b1b16a9f0b`

The inner `transferOwnership(address)` payload targets
`0xb9501334c6a8Daca576Dc14020d9d2b1b16a9F0b` — the L1-to-L2 alias of
`0xa83F1334c6a8Daca576Dc14020d9d2b1b16a8Dfa`. Verify by hand with:

```bash
cast calldata-decode "transferOwnership(address)" \
  0xf2fde38b000000000000000000000000b9501334c6a8daca576dc14020d9d2b1b16a9f0b
# returns 0xb9501334c6a8Daca576Dc14020d9d2b1b16a9F0b
```

## State Changes

The L1 simulation produces two state changes; the L2 state change happens
after deposit inclusion and must be checked manually (see below).

> Note: the simulation also applies the
> `0x4C4710a4Ec3F514A492CC6460818C4A6A6269dd6` slot `0x00` override declared
> in `config.toml`. That override pre-applies task 063's L1 ownership transfer
> so the template's `proxyAdmin.owner() == newOwnerToAlias` check passes; it
> does not produce a state change at signing time (the actual transition is
> performed by task 063).

---

### `0x5a0aae59d09fccbddb6c6cceb07b7279367c3d2a` (Standard mainnet L1PAO Safe — parent multisig) — Chain ID: 1

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `39`
  - **After:**  `40`
  - **Summary:** nonce
  - **Detail:** Standard Gnosis Safe nonce bump. Starts at 39 because this
    task is stacked after the two Ink tasks (`eth/061`, `eth/062`) and task
    063, which advance the nonce from 36 → 39.

---

### `0x758e0ee66102816f5c3ec9ecc1188860fbb87812` (Swell OptimismPortalProxy) — Chain ID: 1923

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Before:** `0x000000000187135700000000000c35000000000000000000000000003b9aca00`
  - **After:**  `0x000000000187595d0000000000030d400000000000000000000000003b9aca00`
  - **Summary:** OptimismPortal `params` slot — `prevBaseFee`, `prevBoughtGas`,
    and `prevBlockNum` are updated as part of bookkeeping for the new deposit;
    `_data.gasLimit = 200000 = 0x30d40` shows up in the middle word.
  - **Detail:** Slot 1 of OptimismPortalProxy packs the deposit-accounting
    parameters that `depositTransaction` updates on every call. The exact
    "Before"/"After" values depend on the simulation block; the constant
    `0x30d40` in the middle word matches the requested L2 gas limit (200,000).

The corresponding `TransactionDeposited(from, to, version, opaqueData)` log is
emitted by the OptimismPortal; verify in Tenderly that `from` is the L1
caller, `to` is `0x4200000000000000000000000000000000000018`, and that the
opaque data encodes the `transferOwnership` payload above.

## Task Calldata

```
0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000758e0ee66102816f5c3ec9ecc1188860fbb878120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c42000000000000000000000000420000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030d40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000024f2fde38b000000000000000000000000b9501334c6a8daca576dc14020d9d2b1b16a9f0b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
```

## Manual L2 Verification Steps

For a complete walkthrough follow
[`docs/simulate-l2-ownership-transfer.md`](../../../../docs/simulate-l2-ownership-transfer.md).
Note that Swell's public RPC (`https://swell-mainnet.alt.technology`) now
requires authentication — request an endpoint from AltLayer in
`#oplabs-altlayer` if needed, or verify via https://explorer.swellnetwork.io.

After the L1 transaction is executed:

1. **Find the L2 deposit transaction** on Swell Mainnet from the aliased
   sender `0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b` (alias of the standard
   mainnet L1PAO Safe) to the L2 ProxyAdmin predeploy
   `0x4200000000000000000000000000000000000018`.
2. **Verify the `OwnershipTransferred` event**:
   - `previousOwner`: `0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b`
   - `newOwner`:      `0xb9501334c6a8Daca576Dc14020d9d2b1b16a9F0b`
3. **Verify final L2 state**:
   ```bash
   cast call 0x4200000000000000000000000000000000000018 "owner()(address)" --rpc-url <swell-mainnet-rpc>
   # Expected: 0xb9501334c6a8Daca576Dc14020d9d2b1b16a9F0b
   ```
4. **AltLayer confirms receipt of ownership** in `#oplabs-altlayer`.
