# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the
pinned nonce in [config.toml](./config.toml) (0x325B777f8F0bC71fb6b617Bc41A8703CA7077891 nonce 7) and move only if that
nonce moves.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Unichain SystemConfigOwner (`0x325B777f8F0bC71fb6b617Bc41A8703CA7077891`)
>
> - Domain Hash:  `0x188054e16f4c64a2629fcef891da5d49e9d67d03d6fbedc906cc4f1de70ad8f8`
> - Message Hash: `0x24b5cba25b470e662526f52ed0880784d80c75ba4a9c4219c0c05c5d5e038d95`

Safe transaction hash: `0x4343325d1509b659b802e4a082f86d959e7687d97a0c824d56228d197678f942`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/sep/110-unichain-sepolia-system-config-owner-to-fus
just simulate-stack sep 110-unichain-sepolia-system-config-owner-to-fus
```

Check:

1. The domain and message hashes printed to the terminal match the ones at the top of this
   file.
2. In the Tenderly link printed by the simulation: paste the **execution calldata printed
   beneath the link** (it starts with `0x6a761202`, `Safe.execTransaction`, and wraps the
   [task calldata](#task-calldata) below) into the **Raw input data** field and simulate; the
   contracts touched must be the ones listed in [Task State Changes](#task-state-changes), and
   nothing else. The inner task calldata (`0x174dea71`) on its own reverts against the Safe.
3. The call trace shows a single `transferOwnership` call on `0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D` with
   `newOwner = 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`, and one `OwnershipTransferred(0x325B777f8F0bC71fb6b617Bc41A8703CA7077891, 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B)` event.
4. `newOwner` (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`) is the Sepolia Foundation Upgrade Safe, see
   [Verifying the new owner](#verifying-the-new-owner).

### Verifying the new owner

The transfer is irreversible for the current owner, so check that `newOwner` is the Sepolia
Foundation Upgrade Safe against independent sources:

- [`src/addresses.toml#L18`](../../../addresses.toml#L18) `FoundationUpgradeSafe`.
- superchain-registry [`standard-config-roles-sepolia.toml#L3`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/validation/standard/standard-config-roles-sepolia.toml#L3) lists the Sepolia L1 ProxyAdmin owner `0x1Eb2fFc903729a0F03966B917003800b145F56E2`, whose two owners are the Foundation Upgrade Safe and the Security Council (first check below).
- On-chain:

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com

cast call 0x1Eb2fFc903729a0F03966B917003800b145F56E2 "getOwners()(address[])" -r $RPC   # [0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B, 0xf64bc17485f0B4Ea5F06A96514182FC4cB561977] (L1PAO = FUS + Security Council)
cast call 0x05C993e60179f28bF649a2Bb5b00b5F4283bD525 "owner()(address)" -r $RPC        # 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B (Ink Sepolia SystemConfig owner since sep/104)
```

## For Facilitators and Reviewers

Everything from here on is for facilitators executing the task and for reviewers. Signers only
need the two sections above.

### Task Calldata

The inner `aggregate3Value` payload, for decoding and verification. It is what the Safe
delegatecalls into `Multicall3DelegateCall`; the Tenderly simulation takes the outer
`execTransaction` wrapper printed by `just simulate-stack` (see step 2 above).

```
0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000aee94b9ab7752d3f7704bde212c0c6a0b701571d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b000000000000000000000000dee57160aafcf04c34c887b5962d0a69676d3c8b00000000000000000000000000000000000000000000000000000000
```

### Understanding Task Calldata

The task is a single `Multicall3DelegateCall.aggregate3Value` from the Safe (selector
`0x174dea71`) containing **1** call, with `allowFailure = false` and `value = 0`:

| # | Target | Function | Argument |
|---|---|---|---|
| 1 | `0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D` (Unichain Sepolia SystemConfigProxy) | `transferOwnership(address)` | `newOwner = 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B` |

To verify the payload fingerprint:

```bash
cast calldata "transferOwnership(address)" 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B
# Expected: 0xf2fde38b000000000000000000000000dee57160aafcf04c34c887b5962d0a69676d3c8b
```

The payload and the target each appear exactly once. To decode the full calldata:

```bash
cast calldata-decode "aggregate3Value((address,bool,uint256,bytes)[])" <task calldata>
```

### Pre-execution checks and execution

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com

cast call 0x325B777f8F0bC71fb6b617Bc41A8703CA7077891 "nonce()(uint256)" -r $RPC          # 7
cast call 0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D "owner()(address)" -r $RPC           # 0x325B777f8F0bC71fb6b617Bc41A8703CA7077891
cast call 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B "getThreshold()(uint256)" -r $RPC   # must succeed (newOwner is a Safe)
```

Then execute with the collected signatures:

```bash
cd src/tasks/sep/110-unichain-sepolia-system-config-owner-to-fus

SIGNATURES=0x... just execute
```

### Task State Changes

Two contracts change.

#### `0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D` (Unichain Sepolia SystemConfigProxy)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Before:** `0x000000000000000000000000325b777f8f0bc71fb6b617bc41a8703ca7077891`
  - **After:**  `0x000000000000000000000000dee57160aafcf04c34c887b5962d0a69676d3c8b`
  - **Summary:** `owner` (OZ `OwnableUpgradeable` slot) moves to the Foundation Upgrade Safe.

#### `0x325B777f8F0bC71fb6b617Bc41A8703CA7077891` (Unichain SystemConfigOwner)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `7` → **After:** `8`
  - **Summary:** nonce increment of the Safe executing the task. The before-value reflects the
    nonce state override in [config.toml](./config.toml).

Tenderly also shows `Nonce N → N+1` (no storage key) on the Safe owner used as the simulation's
sender. Its protocol account nonce, unrelated to the Safe's signing nonce.

### Post-execution verification calls

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com

cast call 0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D "owner()(address)" -r $RPC   # 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B
cast call 0x325B777f8F0bC71fb6b617Bc41A8703CA7077891 "nonce()(uint256)" -r $RPC  # 8
```
