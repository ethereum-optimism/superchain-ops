# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the pinned nonces in [config.toml](./config.toml) (L1PAO 58,
FoundationUpgradeSafe 79, SecurityCouncil 72) and move
only if those inputs move.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### FoundationUpgradeSafe (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`)
>
> - Domain Hash:  `0x37e1f5dd3b92a004a23589b741196c8a214629d4ea3a690ec8e41ae45c689cbb`
> - Message Hash: `0x9494206efe58f5029ddf0e7f312281875f63c5201947e0fa6447bee859ccc0ff`
>
> ### SecurityCouncil (`0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`)
>
> - Domain Hash:  `0xbe081970e9fc104bd1ea27e375cd21ec7bb1eec56bfe43347c3e36c5d27b8533`
> - Message Hash: `0x124678c6ca505607171ade15b6ea1596d956e906127fbeaccaffd5f5029a4eef`

Root L1PAO (`0x1Eb2fFc903729a0F03966B917003800b145F56E2`) safe transaction hash (identical on both signing paths):
`0x25bcb3b986313ec2f89441ee76e059b7f1a72c5304929cb256bee5b206cf006c`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/sep/112-unichain-sepolia-operator-fee-vault
just simulate-stack sep 112-unichain-sepolia-operator-fee-vault council   # or foundation
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
3. The call trace shows three `depositTransaction` calls on `0x0d83dab629f0e0F9d36c0Cbc89B69a489f0751bD` targeting `0x420000000000000000000000000000000000001b` with the payloads in the [Understanding Task Calldata](#understanding-task-calldata) table, and three `TransactionDeposited` events.

## For Facilitators and Reviewers

Everything from here on is for facilitators executing the task and for reviewers. Signers only
need the two sections above.

### Task Calldata

The inner `aggregate3Value` payload, for decoding and verification. It is what the L1PAO
delegatecalls into `Multicall3DelegateCall`; the Tenderly simulation takes the outer
`execTransaction` wrapper printed by `just simulate-stack` (see step 2 above).

```
0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000022000000000000000000000000000000000000000000000000000000000000003e00000000000000000000000000d83dab629f0e0f9d36c0cbc89b69a489f0751bd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c42000000000000000000000000420000000000000000000000000000000000001b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000249f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000243bbed4a0000000000000000000000000c9eddd1852e84164a2be3a1743f492c93eb0ac5200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d83dab629f0e0f9d36c0cbc89b69a489f0751bd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c42000000000000000000000000420000000000000000000000000000000000001b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000249f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000024307f2962000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d83dab629f0e0f9d36c0cbc89b69a489f0751bd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c42000000000000000000000000420000000000000000000000000000000000001b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000249f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000002485b5b14d0000000000000000000000000000000000000000000000000214e8348c4f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
```

### Understanding Task Calldata

The task is a single `Multicall3DelegateCall.aggregate3Value` from the L1PAO (selector
`0x174dea71`) containing **3** call(s), each with `allowFailure = false` and
`value = 0`:

| # | Target | Function | Arguments |
|---|---|---|---|
| 1 | `0x0d83dab629f0e0F9d36c0Cbc89B69a489f0751bD` (OptimismPortalProxy) | `depositTransaction(address,uint256,uint64,bool,bytes)` | `_to = 0x4200…001b`, `_gasLimit = 150000`, `_data = setRecipient(0xc9EDDd1852e84164A2Be3a1743F492C93EB0aC52)` |
| 2 | `0x0d83dab629f0e0F9d36c0Cbc89B69a489f0751bD` (OptimismPortalProxy) | `depositTransaction(address,uint256,uint64,bool,bytes)` | `_to = 0x4200…001b`, `_gasLimit = 150000`, `_data = setWithdrawalNetwork(0)` |
| 3 | `0x0d83dab629f0e0F9d36c0Cbc89B69a489f0751bD` (OptimismPortalProxy) | `depositTransaction(address,uint256,uint64,bool,bytes)` | `_to = 0x4200…001b`, `_gasLimit = 150000`, `_data = setMinWithdrawalAmount(150000000000000000)` |

To verify the payload fingerprints:

```bash
cast calldata "setRecipient(address)" 0xc9EDDd1852e84164A2Be3a1743F492C93EB0aC52
# Expected: 0x3bbed4a0000000000000000000000000c9eddd1852e84164a2be3a1743f492c93eb0ac52

cast calldata "setWithdrawalNetwork(uint8)" 0
# Expected: 0x307f29620000000000000000000000000000000000000000000000000000000000000000

cast calldata "setMinWithdrawalAmount(uint256)" 150000000000000000
# Expected: 0x85b5b14d0000000000000000000000000000000000000000000000000214e8348c4f0000
```

Each payload appears once; the portal, the `depositTransaction` selector `e9e05c42`, the vault address and the gas limit `0249f0` repeat three times. To decode the full calldata:

```bash
cast calldata-decode "aggregate3Value((address,bool,uint256,bytes)[])" <task calldata>
```

### Pre-execution checks and execution

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com

cast call 0x1Eb2fFc903729a0F03966B917003800b145F56E2 "nonce()(uint256)" -r $RPC   # 58
cast call 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B "nonce()(uint256)" -r $RPC   # 79
cast call 0xf64bc17485f0B4Ea5F06A96514182FC4cB561977 "nonce()(uint256)" -r $RPC   # 72
cast call 0x4200000000000000000000000000000000000018 "owner()(address)" -r https://sepolia.unichain.org   # 0x2FC3ffc903729a0f03966b917003800B145F67F3 (aliased L1PAO)
```

Then execute with the collected signatures:

```bash
cd src/tasks/sep/112-unichain-sepolia-operator-fee-vault

SIGNATURES=0x... just approve council
SIGNATURES=0x... just approve foundation
just execute
```

### Task State Changes

#### `0x0d83dab629f0e0F9d36c0Cbc89B69a489f0751bD` (Unichain Sepolia OptimismPortalProxy)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** `ResourceMetering.ResourceParams`: `prevBoughtGas` becomes 450,000 (3 × 150,000) and `prevBlockNum` the simulation block; both are block-dependent. Only this slot of the portal may change.

On L2, once relayed, the OperatorFeeVault changes `recipient` / `withdrawalNetwork` (slot `2`) and
`minWithdrawalAmount` (slot `1`); see the post-execution checks.

#### `0x1Eb2fFc903729a0F03966B917003800b145F56E2` (L1PAO, root safe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `58` → **After:** `59`
  - **Summary:** nonce increment of the root safe. The before-value reflects the nonce state
    override in [config.toml](./config.toml).
- **Key (foundation path):** `0xfb967069d068d9d6a87a78e6171798f9c755470befac9f52a6d75bfeef1e7bea`
- **Key (council path):** `0x07fbd228556435cba68d37d1b235dd6a864e04c38cd0f179dbdeb1d07de4a599`
  - **Before:** `0` → **After:** `1`
  - **Summary:** `approvedHashes[<child safe>][0x25bcb3b9…]`, the child safe's approval. Only the
    key of the path being simulated is written. Derive with
    `cast index bytes32 0x25bcb3b986313ec2f89441ee76e059b7f1a72c5304929cb256bee5b206cf006c $(cast index address <child> 8)`.

#### `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B` (FoundationUpgradeSafe), foundation path

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `79` → **After:** `80`
  - **Summary:** nonce increment of the approving child safe.

#### `0xf64bc17485f0B4Ea5F06A96514182FC4cB561977` (SecurityCouncil), council path

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `72` → **After:** `73`
  - **Summary:** nonce increment of the approving child safe.

#### `0xc26977310bC89DAee5823C2e2a73195E85382cC7` (SecurityCouncil LivenessGuard), council path

- **Key:** `0xee4378be6a15d4c71cb07a5a47d8ddc4aba235142e05cb828bb7141206657e27`
  - **Summary:** `lastLive[0xca11bde05977b3631167028862bE2a173976CA11]` set to the simulation timestamp, a simulation
    artifact (the simulation makes Multicall3 the sole signer of the child safe).

Tenderly also shows `Nonce N → N+1` (no storage key) on the Safe owner used as the simulation's
sender. Its protocol account nonce, unrelated to the Safe's signing nonce.

### Post-execution verification calls

```bash
L2RPC=https://sepolia.unichain.org
OV=0x420000000000000000000000000000000000001b

cast call $OV "recipient()(address)" -r $L2RPC              # 0xc9EDDd1852e84164A2Be3a1743F492C93EB0aC52
cast call $OV "withdrawalNetwork()(uint8)" -r $L2RPC        # 0
cast call $OV "minWithdrawalAmount()(uint256)" -r $L2RPC    # 150000000000000000
```
