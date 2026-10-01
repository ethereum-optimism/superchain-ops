# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the pinned nonces in [config.toml](./config.toml) (L1PAO 45,
FoundationUpgradeSafe 75, SecurityCouncil 72) and move
only if those inputs move.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### FoundationUpgradeSafe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0x53564615350c1f0fdda177388ac3e363356c2b0f9796f25e0d68a9e137c902a5`
>
> ### SecurityCouncil (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash:  `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0x58d564c5d585fc4e5ec376ecabe4ffb6b2eb055cca6164564b362e8272dea400`

Root L1PAO (`0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`) safe transaction hash (identical on both signing paths):
`0x81a3f47eee3dd3528a9234f6b5726a998e388ab93b351730d90b74593259d3be`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/eth/079-unichain-l1splitter-accept-and-configure
just simulate-stack eth 079-unichain-l1splitter-accept-and-configure council   # or foundation
```

Check:

1. The domain and message hashes printed to the terminal match the ones at the top of this
   file.
2. In the Tenderly link printed by the simulation: paste the **execution calldata printed
   beneath the link** (it starts with `0x6a761202`, the outer
   `execTransaction` that the child safe sends to the L1PAO, and wraps the
   [task calldata](#task-calldata) below) into the **Raw input data** field and simulate; the
   contracts touched must be the ones listed in [Task State Changes](#task-state-changes), and
   nothing else.
3. The call trace shows three `depositTransaction` calls on `0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2` targeting `0x4300c0d3c0d3c0D3c0d3C0D3c0d3C0D3C0D30003` with the payloads in the [Understanding Task Calldata](#understanding-task-calldata) table, and three `TransactionDeposited` events.

## For Facilitators and Reviewers

Everything from here on is for facilitators executing the task and for reviewers. Signers only
need the two sections above.

### Task Calldata

The inner `aggregate3Value` payload, for decoding and verification. It is what the L1PAO
delegatecalls into `Multicall3DelegateCall`; the Tenderly simulation takes the outer
`execTransaction` wrapper printed by `just simulate-stack` (see step 2 above).

```
0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000003c00000000000000000000000000bd48f6b86a26d3a217d0fa6ffe2b491b956a7a200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000e4e9e05c420000000000000000000000004300c0d3c0d3c0d3c0d3c0d3c0d3c0d3c0d30003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000249f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000479ba509700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bd48f6b86a26d3a217d0fa6ffe2b491b956a7a20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c420000000000000000000000004300c0d3c0d3c0d3c0d3c0d3c0d3c0d3c0d30003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000249f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000024f62b6105000000000000000000000000dead00000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bd48f6b86a26d3a217d0fa6ffe2b491b956a7a20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c420000000000000000000000004300c0d3c0d3c0d3c0d3c0d3c0d3c0d3c0d30003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000249f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000024c1c4ed2c0000000000000000000000000000000000000000000000000214e8348c4f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
```

### Understanding Task Calldata

The task is a single `Multicall3DelegateCall.aggregate3Value` from the L1PAO (selector
`0x174dea71`) containing **3** call(s), each with `allowFailure = false` and
`value = 0`:

| # | Target | Function | Arguments |
|---|---|---|---|
| 1 | `0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2` (OptimismPortalProxy) | `depositTransaction(address,uint256,uint64,bool,bytes)` | `_to = 0x4300c0d3c0d3c0D3c0d3C0D3c0d3C0D3C0D30003`, `_gasLimit = 150000`, `_data = acceptOwnership()` |
| 2 | `0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2` (OptimismPortalProxy) | `depositTransaction(address,uint256,uint64,bool,bytes)` | `_to = 0x4300c0d3c0d3c0D3c0d3C0D3c0d3C0D3C0D30003`, `_gasLimit = 150000`, `_data = updateL1Recipient(0xdead000000000000000000000000000000000004)` |
| 3 | `0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2` (OptimismPortalProxy) | `depositTransaction(address,uint256,uint64,bool,bytes)` | `_to = 0x4300c0d3c0d3c0D3c0d3C0D3c0d3C0D3C0D30003`, `_gasLimit = 150000`, `_data = updateMinWithdrawalAmount(150000000000000000)` |

To verify the payload fingerprints:

```bash
cast calldata "acceptOwnership()" 
# Expected: 0x79ba5097

cast calldata "updateL1Recipient(address)" 0xdead000000000000000000000000000000000004
# Expected: 0xf62b6105000000000000000000000000dead000000000000000000000000000000000004

cast calldata "updateMinWithdrawalAmount(uint256)" 150000000000000000
# Expected: 0xc1c4ed2c0000000000000000000000000000000000000000000000000214e8348c4f0000
```

Each payload appears once; the portal, the `depositTransaction` selector `e9e05c42`, the L1Splitter address and the gas limit `0249f0` repeat three times. To decode the full calldata:

```bash
cast calldata-decode "aggregate3Value((address,bool,uint256,bytes)[])" <task calldata>
```

### Pre-execution checks and execution

```bash
RPC=https://ethereum-rpc.publicnode.com

cast call 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A "nonce()(uint256)" -r $RPC   # 45
cast call 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 "nonce()(uint256)" -r $RPC   # 75
cast call 0xc2819DC788505Aac350142A7A707BF9D03E3Bd03 "nonce()(uint256)" -r $RPC   # 72
cast call 0x4300c0d3c0d3c0D3c0d3C0D3c0d3C0D3C0D30003 "pendingOwner()(address)" -r https://mainnet.unichain.org   # 0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b (eth/076 relayed)
```

Then execute with the collected signatures:

```bash
cd src/tasks/eth/079-unichain-l1splitter-accept-and-configure

SIGNATURES=0x... just approve council
SIGNATURES=0x... just approve foundation
just execute
```

### Task State Changes

#### `0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2` (Unichain OptimismPortalProxy)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** `ResourceMetering.ResourceParams`: `prevBoughtGas` becomes 450,000 (3 × 150,000) and `prevBlockNum` the simulation block; both are block-dependent. Only this slot of the portal may change.

On L2, once relayed, the L1Splitter changes `owner` (slot `0`), clears `pendingOwner` (slot `1`), and updates `l1Recipient` (low 20 bytes of slot `2`) and `minWithdrawalAmount` (slot `3`).

#### `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (L1PAO, root safe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `45` → **After:** `46`
  - **Summary:** nonce increment of the root safe. The before-value reflects the nonce state
    override in [config.toml](./config.toml).
- **Key (foundation path):** `0x00b38288a4fff14a0b699efb1ec356439273256b7921d8d500c2a55766552bf1`
- **Key (council path):** `0xf759a36e82bf93062516ef6e421e76a7a9019f6e285da6615095df565d69c749`
  - **Before:** `0` → **After:** `1`
  - **Summary:** `approvedHashes[<child safe>][0x81a3f47e…]`, the child safe's approval. Only the
    key of the path being simulated is written. Derive with
    `cast index bytes32 0x81a3f47eee3dd3528a9234f6b5726a998e388ab93b351730d90b74593259d3be $(cast index address <child> 8)`.

#### `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (FoundationUpgradeSafe), foundation path

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `75` → **After:** `76`
  - **Summary:** nonce increment of the approving child safe.

#### `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03` (SecurityCouncil), council path

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `72` → **After:** `73`
  - **Summary:** nonce increment of the approving child safe.

#### `0x24424336F04440b1c28685a38303aC33C9D14a25` (SecurityCouncil LivenessGuard), council path

- **Key:** `0xee4378be6a15d4c71cb07a5a47d8ddc4aba235142e05cb828bb7141206657e27`
  - **Summary:** `lastLive[0xca11bde05977b3631167028862bE2a173976CA11]` set to the simulation timestamp, a simulation
    artifact (the simulation makes Multicall3 the sole signer of the child safe).

Tenderly also shows `Nonce N → N+1` (no storage key) on the Safe owner used as the simulation's
sender. Its protocol account nonce, unrelated to the Safe's signing nonce.

### Post-execution verification calls

```bash
L2RPC=https://mainnet.unichain.org

cast call 0x4300c0d3c0d3c0D3c0d3C0D3c0d3C0D3C0D30003 "owner()(address)" -r $L2RPC                 # 0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b
cast call 0x4300c0d3c0d3c0D3c0d3C0D3c0d3C0D3C0D30003 "pendingOwner()(address)" -r $L2RPC          # 0x0000000000000000000000000000000000000000
cast call 0x4300c0d3c0d3c0D3c0d3C0D3c0d3C0D3C0D30003 "l1Recipient()(address)" -r $L2RPC           # 0xdead000000000000000000000000000000000004
cast call 0x4300c0d3c0d3c0D3c0d3C0D3c0d3C0D3C0D30003 "minWithdrawalAmount()(uint256)" -r $L2RPC   # 150000000000000000
cast call 0x4300c0d3c0d3c0D3c0d3C0D3c0d3C0D3C0D30003 "feeDisbursementInterval()(uint48)" -r $L2RPC # 86400 (unchanged)
```
