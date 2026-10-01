# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the
pinned nonce in [config.toml](./config.toml) (0xB278818732E5BEbb742dc4Aa0617ccd1Dec76b65 nonce 32) and move only if that
nonce moves.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Soneium SystemConfigOwner (`0xB278818732E5BEbb742dc4Aa0617ccd1Dec76b65`)
>
> - Domain Hash:  `0xd5ef838177141b76f2edb19b4bb90f1d5526d11264faa809879995be7cb8a3d5`
> - Message Hash: `0x0248d40a147382ea83ed6fd1607609b84c36cef3822ad40ec8bba31a48309e01`

Safe transaction hash: `0x55024758ec315b4e2ffd7f8f1aba7b674f556f1fe7ae6dcd5eb8416470114e5b`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/sep/111-soneium-minato-system-config-owner-to-fus
just simulate-stack sep 111-soneium-minato-system-config-owner-to-fus
```

Check:

1. The domain and message hashes printed to the terminal match the ones at the top of this
   file.
2. In the Tenderly link printed by the simulation: paste the **execution calldata printed
   beneath the link** (it starts with `0x6a761202`, `Safe.execTransaction`, and wraps the
   [task calldata](#task-calldata) below) into the **Raw input data** field and simulate; the
   contracts touched must be the ones listed in [Task State Changes](#task-state-changes), and
   nothing else. The inner task calldata (`0x174dea71`) on its own reverts against the Safe.
3. The call trace shows a single `transferOwnership` call on `0x4Ca9608Fef202216bc21D543798ec854539bAAd3` with
   `newOwner = 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`, and one `OwnershipTransferred(0xB278818732E5BEbb742dc4Aa0617ccd1Dec76b65, 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B)` event.

## For Facilitators and Reviewers

Everything from here on is for facilitators executing the task and for reviewers. Signers only
need the two sections above.

### Task Calldata

The inner `aggregate3Value` payload, for decoding and verification. It is what the Safe
delegatecalls into `Multicall3DelegateCall`; the Tenderly simulation takes the outer
`execTransaction` wrapper printed by `just simulate-stack` (see step 2 above).

```
0x174dea710000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000004ca9608fef202216bc21d543798ec854539baad30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b000000000000000000000000dee57160aafcf04c34c887b5962d0a69676d3c8b00000000000000000000000000000000000000000000000000000000
```

### Understanding Task Calldata

The task is a single `Multicall3DelegateCall.aggregate3Value` from the Safe (selector
`0x174dea71`) containing **1** call, with `allowFailure = false` and `value = 0`:

| # | Target | Function | Argument |
|---|---|---|---|
| 1 | `0x4Ca9608Fef202216bc21D543798ec854539bAAd3` (Soneium Minato SystemConfigProxy) | `transferOwnership(address)` | `newOwner = 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B` |

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

cast call 0xB278818732E5BEbb742dc4Aa0617ccd1Dec76b65 "nonce()(uint256)" -r $RPC          # 32
cast call 0x4Ca9608Fef202216bc21D543798ec854539bAAd3 "owner()(address)" -r $RPC           # 0xB278818732E5BEbb742dc4Aa0617ccd1Dec76b65
cast call 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B "getThreshold()(uint256)" -r $RPC   # must succeed (newOwner is a Safe)
```

Then execute with the collected signatures:

```bash
cd src/tasks/sep/111-soneium-minato-system-config-owner-to-fus

SIGNATURES=0x... just execute
```

### Task State Changes

Two contracts change.

#### `0x4Ca9608Fef202216bc21D543798ec854539bAAd3` (Soneium Minato SystemConfigProxy)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Before:** `0x000000000000000000000000b278818732e5bebb742dc4aa0617ccd1dec76b65`
  - **After:**  `0x000000000000000000000000dee57160aafcf04c34c887b5962d0a69676d3c8b`
  - **Summary:** `owner` (OZ `OwnableUpgradeable` slot) moves to the Foundation Upgrade Safe.

#### `0xB278818732E5BEbb742dc4Aa0617ccd1Dec76b65` (Soneium SystemConfigOwner)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `32` → **After:** `33`
  - **Summary:** nonce increment of the Safe executing the task. The before-value reflects the
    nonce state override in [config.toml](./config.toml).

Tenderly also shows `Nonce N → N+1` (no storage key) on the Safe owner used as the simulation's
sender. Its protocol account nonce, unrelated to the Safe's signing nonce.

### Post-execution verification calls

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com

cast call 0x4Ca9608Fef202216bc21D543798ec854539bAAd3 "owner()(address)" -r $RPC   # 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B
cast call 0xB278818732E5BEbb742dc4Aa0617ccd1Dec76b65 "nonce()(uint256)" -r $RPC  # 33
```
