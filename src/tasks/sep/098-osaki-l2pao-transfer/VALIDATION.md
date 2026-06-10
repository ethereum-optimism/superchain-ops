# Validation

This document can be used to validate the inputs and result of the execution of
the transaction which you are signing.

Task 098 transfers the L2 ProxyAdmin Owner for Osaki Sepolia (chainId 9111973)
to the L1-to-L2 alias of `0xFB0F8937A0d6999C67E8a01310eBf7fe1859205F`, via a
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
> one ahead of the on-chain value to account for the bump from task 097:
> - Standard Sepolia L1PAO Safe: **51**
> - FoundationUpgradeSafe:       **71**
> - SecurityCouncil:              **65**
>
> All three Safes are shared across many Sepolia chains. Before signing,
> re-verify the live nonces with
> `cast call <safe> "nonce()" --rpc-url sepolia` and your ledger. If task 097
> has not yet been signed when you simulate this one, the pinned values still
> apply (the override mimics the post-097 state); if anything else has
> advanced the live nonces in the meantime, bump the corresponding override
> and re-simulate so the hashes below are regenerated.
>
> ### FoundationUpgradeSafe (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`)
>
> - Domain Hash:  `0x37e1f5dd3b92a004a23589b741196c8a214629d4ea3a690ec8e41ae45c689cbb`
> - Message Hash: `0xf1e54a545e79bd039a8cca480a0d88b56cf531a9f93c8eb8cce30f46db438e4d`
>
> ### SecurityCouncil (`0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`)
>
> - Domain Hash:  `0xbe081970e9fc104bd1ea27e375cd21ec7bb1eec56bfe43347c3e36c5d27b8533`
> - Message Hash: `0x02fe93654620ea5af31e523b5a71413ceabcfa6d5cd8366d4b5a2a0d5d5711fd`

## Transaction Inputs

The transaction calls `OptimismPortalProxy.depositTransaction` with the
following arguments (decoded from the task calldata in `_data`):

- `_to`:         `0x4200000000000000000000000000000000000018` (L2 ProxyAdmin predeploy)
- `_value`:      `0`
- `_gasLimit`:   `200000`
- `_isCreation`: `false`
- `_data`:       `0xf2fde38b0000000000000000000000000c208937a0d6999c67e8a01310ebf7fe18593170`

The inner `transferOwnership(address)` payload targets
`0x0C208937a0D6999c67E8A01310ebF7fE18593170` — the L1-to-L2 alias of
`0xFB0F8937A0d6999C67E8a01310eBf7fe1859205F`. Verify by hand with:

```bash
cast calldata-decode "transferOwnership(address)" \
  0xf2fde38b0000000000000000000000000c208937a0d6999c67e8a01310ebf7fe18593170
# returns 0x0C208937a0D6999c67E8A01310ebF7fE18593170
```

## State Changes

The L1 simulation produces two state changes; the L2 state change happens
after deposit inclusion and must be checked manually (see below).

> Note: the simulation also applies the
> `0x2f3369b81c2b6e1e80a98f7de44be8cfff314db0` slot `0x00` override declared
> in `config.toml`. That override pre-applies task 097's L1 ownership transfer
> so the template's `proxyAdmin.owner() == newOwnerToAlias` check passes; it
> does not produce a state change at signing time (the actual transition is
> performed by task 097).

---

### `0x1eb2ffc903729a0f03966b917003800b145f56e2` (Standard Sepolia L1PAO Safe — parent multisig) — Chain ID: 11155111

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Decoded Kind:** `uint256`
  - **Before:** `51`
  - **After:**  `52`
  - **Summary:** nonce
  - **Detail:** Standard Gnosis Safe nonce bump. Starts at 51 because this
    task is stacked after task 097, which advances the nonce from 50 → 51.

---

### `0x7218b76ad6c329e731aa3213c65fb05634691238` (Osaki OptimismPortalProxy) — Chain ID: 9111973

- **Key:**          `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Before:** `0x0000000000a8418f0000000000334c930000000000000000000000003b9aca00`
  - **After:**  `0x0000000000a849c80000000000030d400000000000000000000000003b9aca00`
  - **Summary:** OptimismPortal `params` slot — `prevBaseFee`, `prevBoughtGas`,
    and `prevBlockNum` are updated as part of bookkeeping for the new deposit;
    `_data.gasLimit = 200000 = 0x30d40` shows up in the middle word.
  - **Detail:** Slot 1 of OptimismPortalProxy packs the deposit-accounting
    parameters that `depositTransaction` updates on every call. The exact
    "After" value depends on the simulation block; the constant `0x30d40` in
    the middle word matches the requested L2 gas limit (200,000).

The corresponding `TransactionDeposited(from, to, version, opaqueData)` log is
emitted by the OptimismPortal; verify in Tenderly that `from` is the L1
caller, `to` is `0x4200000000000000000000000000000000000018`, and that the
opaque data encodes the `transferOwnership` payload above.

## Task Calldata

```
0x174dea710000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000007218b76ad6c329e731aa3213c65fb056346912380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c42000000000000000000000000420000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030d40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000024f2fde38b0000000000000000000000000c208937a0d6999c67e8a01310ebf7fe185931700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
```

## Manual L2 Verification Steps

For a complete walkthrough follow
[`docs/simulate-l2-ownership-transfer.md`](../../../../docs/simulate-l2-ownership-transfer.md).

After the L1 transaction is executed:

1. **Find the L2 deposit transaction** on Osaki Sepolia from the aliased
   sender `0x2FC3ffc903729a0f03966b917003800B145F67F3` (alias of the standard
   Sepolia L1PAO Safe) to the L2 ProxyAdmin predeploy
   `0x4200000000000000000000000000000000000018`.
2. **Verify the `OwnershipTransferred` event**:
   - `previousOwner`: `0x2FC3ffc903729a0f03966b917003800B145F67F3`
   - `newOwner`:      `0x0C208937a0D6999c67E8A01310ebF7fE18593170`
3. **Verify final L2 state**:
   ```bash
   cast call 0x4200000000000000000000000000000000000018 "owner()(address)" --rpc-url <osaki-sepolia-rpc>
   # Expected: 0x0C208937a0D6999c67E8A01310ebF7fE18593170
   ```
