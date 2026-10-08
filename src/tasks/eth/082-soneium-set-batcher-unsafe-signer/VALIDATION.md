# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the pinned nonce in [config.toml](./config.toml) (FoundationUpgradeSafe
79), with the SystemConfig owner set to the FoundationUpgradeSafe and move only if those inputs move.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### FoundationUpgradeSafe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0x4760e5ecd4c5853522d4eb4b0716cd8bb915fc92470a72d92c2788f4f8e471a6`

Safe transaction hash: `0xa9b27d6226003090171673c8de551d24b3125a6de059dd3f28d0e0cf74264861`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/eth/082-soneium-set-batcher-unsafe-signer
just simulate-stack eth 082-soneium-set-batcher-unsafe-signer
```

Check:

1. The domain and message hashes printed to the terminal match the ones at the top of this
   file.
2. In the Tenderly link printed by the simulation: paste the **execution calldata printed
   beneath the link** (it starts with `0x6a761202`, the outer
   `execTransaction`, and wraps the
   [task calldata](#task-calldata) below) into the **Raw input data** field and simulate; the
   contracts touched must be the ones listed in [Task State Changes](#task-state-changes), and
   nothing else.
3. The call trace shows `setBatcherHash` and `setUnsafeBlockSigner` on `0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3` with the values in the [Understanding Task Calldata](#understanding-task-calldata) table, and two `ConfigUpdate` events (`updateType` 0 `BATCHER` and 3 `UNSAFE_BLOCK_SIGNER`).

## For Facilitators and Reviewers

Everything from here on is for facilitators executing the task and for reviewers. Signers only
need the two sections above.

### Task Calldata

The inner `aggregate3Value` payload, for decoding and verification. It is what the FoundationUpgradeSafe
delegatecalls into `Multicall3DelegateCall`; the Tenderly simulation takes the outer
`execTransaction` wrapper printed by `just simulate-stack` (see step 2 above).

```
0x174dea7100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000001200000000000000000000000007a8ed66b319911a0f3e7288bddab30d9c0c875c30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000024c9b26f61000000000000000000000000dead00000000000000000000000000001001dead000000000000000000000000000000000000000000000000000000000000000000000000000000007a8ed66b319911a0f3e7288bddab30d9c0c875c3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000002418d13918000000000000000000000000dead00000000000000000000000000001002dead00000000000000000000000000000000000000000000000000000000
```

### Understanding Task Calldata

The task is a single `Multicall3DelegateCall.aggregate3Value` from the FoundationUpgradeSafe (selector
`0x174dea71`) containing **2** call(s), each with `allowFailure = false` and
`value = 0`:

| # | Target | Function | Arguments |
|---|---|---|---|
| 1 | `0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3` (SystemConfigProxy) | `setBatcherHash(bytes32)` | `_batcherHash = 0xdead00000000000000000000000000001001dead` (left-padded) |
| 2 | `0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3` (SystemConfigProxy) | `setUnsafeBlockSigner(address)` | `_unsafeBlockSigner = 0xdead00000000000000000000000000001002dead` |

To verify the payload fingerprints:

```bash
cast calldata "setBatcherHash(bytes32)" 0x000000000000000000000000dead00000000000000000000000000001001dead
# Expected: 0xc9b26f61000000000000000000000000dead00000000000000000000000000001001dead

cast calldata "setUnsafeBlockSigner(address)" 0xdead00000000000000000000000000001002dead
# Expected: 0x18d13918000000000000000000000000dead00000000000000000000000000001002dead
```

Each payload appears exactly once and the target twice. To decode the full calldata:

```bash
cast calldata-decode "aggregate3Value((address,bool,uint256,bytes)[])" <task calldata>
```

### Pre-execution checks and execution

```bash
RPC=https://ethereum-rpc.publicnode.com

cast call 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 "nonce()(uint256)" -r $RPC   # 79
cast call 0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3 "owner()(address)" -r $RPC   # 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 (after 075)
```

Then execute with the collected signatures:

```bash
cd src/tasks/eth/082-soneium-set-batcher-unsafe-signer

SIGNATURES=0x... just execute
```

### Task State Changes

#### `0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3` (Soneium SystemConfigProxy)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000067`
  - **Before:** `0x0000000000000000000000006776be80dbada6a02b5f2095cf13734ac303b8d1`
  - **After:**  `0x000000000000000000000000dead00000000000000000000000000001001dead`
  - **Summary:** `batcherHash`.
- **Key:** `0x65a7ed542fb37fe237fdfbdd70b31598523fe5b32879e307bae27a0bd9581c08`
  - **Before:** `0x0000000000000000000000007c2bd59ee2a2c7391c9a240132f26071e9546262`
  - **After:**  `0x000000000000000000000000dead00000000000000000000000000001002dead`
  - **Summary:** `unsafeBlockSigner` (`keccak256("systemconfig.unsafeblocksigner") - 1`).

The slot `0x33` owner value is a state override standing in for 075, not a change made by this task.

#### `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (FoundationUpgradeSafe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `79` → **After:** `80`
  - **Summary:** nonce increment of the Safe executing the task. The before-value reflects the
    nonce state override in [config.toml](./config.toml).

Tenderly also shows `Nonce N → N+1` (no storage key) on the Safe owner used as the simulation's
sender. Its protocol account nonce, unrelated to the Safe's signing nonce.

### Post-execution verification calls

```bash
RPC=https://ethereum-rpc.publicnode.com

cast call 0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3 "batcherHash()(bytes32)" -r $RPC        # 0x000000000000000000000000dead00000000000000000000000000001001dead
cast call 0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3 "unsafeBlockSigner()(address)" -r $RPC   # 0xdead00000000000000000000000000001002dead
cast call 0x7A8Ed66B319911A0F3E7288BDdAB30d9c0C875c3 "owner()(address)" -r $RPC               # 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 (unchanged)
```
