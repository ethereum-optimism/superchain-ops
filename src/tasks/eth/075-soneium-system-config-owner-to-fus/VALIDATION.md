# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the
pinned nonce in [config.toml](./config.toml) (0x509182eC226b3B71D36A3255A80EF0b1A9D43033 nonce 22) and move only if that
nonce moves.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Soneium SystemConfigOwner (`0x509182eC226b3B71D36A3255A80EF0b1A9D43033`)
>
> - Domain Hash:  `0xfec9c20e9a1f1dc2de8e49ee266be73bafbca115021f1de122ef95419b35297d`
> - Message Hash: `0xe66991d48287daf6d7d332843b2039e8794314bfa6933e9f13c0141dd139d137`

Safe transaction hash: `0xd55db7661bc8f71f2f1c34b298b3f990f26811931a154fc21639cd656f3f51b6`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/eth/075-soneium-system-config-owner-to-fus
just simulate-stack eth 075-soneium-system-config-owner-to-fus
```

Check:

1. The domain and message hashes printed to the terminal match the ones at the top of this
   file.
2. In the Tenderly link printed by the simulation: paste the **execution calldata printed
   beneath the link** (it starts with `0x6a761202`, `Safe.execTransaction`, and wraps the
   [task calldata](#task-calldata) below) into the **Raw input data** field and simulate; the
   contracts touched must be the ones listed in [Task State Changes](#task-state-changes), and
   nothing else. The inner task calldata (`0x174dea71`) on its own reverts against the Safe.
3. The call trace shows a single `transferOwnership` call on `0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3` with
   `newOwner = 0x847B5c174615B1B7fDF770882256e2D3E95b9D92`, and one `OwnershipTransferred(0x509182eC226b3B71D36A3255A80EF0b1A9D43033, 0x847B5c174615B1B7fDF770882256e2D3E95b9D92)` event.

## For Facilitators and Reviewers

Everything from here on is for facilitators executing the task and for reviewers. Signers only
need the two sections above.

### Task Calldata

The inner `aggregate3Value` payload, for decoding and verification. It is what the Safe
delegatecalls into `Multicall3DelegateCall`; the Tenderly simulation takes the outer
`execTransaction` wrapper printed by `just simulate-stack` (see step 2 above).

```
0x174dea710000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000007a8ed66b319911a0f3e7288bddab30d9c0c875c30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024f2fde38b000000000000000000000000847b5c174615b1b7fdf770882256e2d3e95b9d9200000000000000000000000000000000000000000000000000000000
```

### Understanding Task Calldata

The task is a single `Multicall3DelegateCall.aggregate3Value` from the Safe (selector
`0x174dea71`) containing **1** call, with `allowFailure = false` and `value = 0`:

| # | Target | Function | Argument |
|---|---|---|---|
| 1 | `0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3` (Soneium SystemConfigProxy) | `transferOwnership(address)` | `newOwner = 0x847B5c174615B1B7fDF770882256e2D3E95b9D92` |

To verify the payload fingerprint:

```bash
cast calldata "transferOwnership(address)" 0x847B5c174615B1B7fDF770882256e2D3E95b9D92
# Expected: 0xf2fde38b000000000000000000000000847b5c174615b1b7fdf770882256e2d3e95b9d92
```

The payload and the target each appear exactly once. To decode the full calldata:

```bash
cast calldata-decode "aggregate3Value((address,bool,uint256,bytes)[])" <task calldata>
```

### Pre-execution checks and execution

```bash
RPC=https://ethereum-rpc.publicnode.com

cast call 0x509182eC226b3B71D36A3255A80EF0b1A9D43033 "nonce()(uint256)" -r $RPC          # 22
cast call 0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3 "owner()(address)" -r $RPC           # 0x509182eC226b3B71D36A3255A80EF0b1A9D43033
cast call 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 "getThreshold()(uint256)" -r $RPC   # must succeed (newOwner is a Safe)
```

Then execute with the collected signatures:

```bash
cd src/tasks/eth/075-soneium-system-config-owner-to-fus

SIGNATURES=0x... just execute
```

### Task State Changes

Two contracts change.

#### `0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3` (Soneium SystemConfigProxy)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000033`
  - **Before:** `0x000000000000000000000000509182ec226b3b71d36a3255a80ef0b1a9d43033`
  - **After:**  `0x000000000000000000000000847b5c174615b1b7fdf770882256e2d3e95b9d92`
  - **Summary:** `owner` (OZ `OwnableUpgradeable` slot) moves to the Foundation Upgrade Safe.

#### `0x509182eC226b3B71D36A3255A80EF0b1A9D43033` (Soneium SystemConfigOwner)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `22` → **After:** `23`
  - **Summary:** nonce increment of the Safe executing the task. The before-value reflects the
    nonce state override in [config.toml](./config.toml).

Tenderly also shows `Nonce N → N+1` (no storage key) on the Safe owner used as the simulation's
sender. Its protocol account nonce, unrelated to the Safe's signing nonce.

### Post-execution verification calls

```bash
RPC=https://ethereum-rpc.publicnode.com

cast call 0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3 "owner()(address)" -r $RPC   # 0x847B5c174615B1B7fDF770882256e2D3E95b9D92
cast call 0x509182eC226b3B71D36A3255A80EF0b1A9D43033 "nonce()(uint256)" -r $RPC  # 23
```
