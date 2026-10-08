# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the pinned nonces in [config.toml](./config.toml) (L1PAO 46,
FoundationUpgradeSafe 76, SecurityCouncil 73) and move
only if those inputs move.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### FoundationUpgradeSafe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0x7832ca86091c221f35556113a7fefd11e23a49663af09f6e8a8dc4f0d3c08be9`
>
> ### SecurityCouncil (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash:  `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0x830eb79f4e954722b771c36abb81021f9ba484b460194a7a9acb595e4d05da3f`

Root L1PAO (`0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`) safe transaction hash (identical on both signing paths):
`0xa2118925aa1a2e0bc5a54dee86cdd616cace28f22b2485ff412a32fd95dad487`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/eth/078-unichain-operator-fee-vault
just simulate-stack eth 078-unichain-operator-fee-vault council   # or foundation
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
3. The call trace shows three `depositTransaction` calls on `0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2` targeting `0x420000000000000000000000000000000000001b` with the payloads in the [Understanding Task Calldata](#understanding-task-calldata) table, and three `TransactionDeposited` events.

## For Facilitators and Reviewers

Everything from here on is for facilitators executing the task and for reviewers. Signers only
need the two sections above.

### Task Calldata

The inner `aggregate3Value` payload, for decoding and verification. It is what the L1PAO
delegatecalls into `Multicall3DelegateCall`; the Tenderly simulation takes the outer
`execTransaction` wrapper printed by `just simulate-stack` (see step 2 above).

```
0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000022000000000000000000000000000000000000000000000000000000000000003e00000000000000000000000000bd48f6b86a26d3a217d0fa6ffe2b491b956a7a20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c42000000000000000000000000420000000000000000000000000000000000001b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000249f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000243bbed4a0000000000000000000000000dead00000000000000000000000000000004dead00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bd48f6b86a26d3a217d0fa6ffe2b491b956a7a20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c42000000000000000000000000420000000000000000000000000000000000001b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000249f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000024307f2962000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bd48f6b86a26d3a217d0fa6ffe2b491b956a7a20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000104e9e05c42000000000000000000000000420000000000000000000000000000000000001b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000249f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000002485b5b14d0000000000000000000000000000000000000000000000000214e8348c4f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
```

### Understanding Task Calldata

The task is a single `Multicall3DelegateCall.aggregate3Value` from the L1PAO (selector
`0x174dea71`) containing **3** call(s), each with `allowFailure = false` and
`value = 0`:

| # | Target | Function | Arguments |
|---|---|---|---|
| 1 | `0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2` (OptimismPortalProxy) | `depositTransaction(address,uint256,uint64,bool,bytes)` | `_to = 0x4200…001b`, `_gasLimit = 150000`, `_data = setRecipient(0xdead00000000000000000000000000000004dead)` |
| 2 | `0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2` (OptimismPortalProxy) | `depositTransaction(address,uint256,uint64,bool,bytes)` | `_to = 0x4200…001b`, `_gasLimit = 150000`, `_data = setWithdrawalNetwork(0)` |
| 3 | `0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2` (OptimismPortalProxy) | `depositTransaction(address,uint256,uint64,bool,bytes)` | `_to = 0x4200…001b`, `_gasLimit = 150000`, `_data = setMinWithdrawalAmount(150000000000000000)` |

To verify the payload fingerprints:

```bash
cast calldata "setRecipient(address)" 0xdead00000000000000000000000000000004dead
# Expected: 0x3bbed4a0000000000000000000000000dead00000000000000000000000000000004dead

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
RPC=https://ethereum-rpc.publicnode.com

cast call 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A "nonce()(uint256)" -r $RPC   # 46
cast call 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 "nonce()(uint256)" -r $RPC   # 76
cast call 0xc2819DC788505Aac350142A7A707BF9D03E3Bd03 "nonce()(uint256)" -r $RPC   # 73
cast call 0x4200000000000000000000000000000000000018 "owner()(address)" -r https://mainnet.unichain.org   # 0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b (aliased L1PAO)
```

Then execute with the collected signatures:

```bash
cd src/tasks/eth/078-unichain-operator-fee-vault

SIGNATURES=0x... just approve council
SIGNATURES=0x... just approve foundation
just execute
```

### Task State Changes

#### `0x0bd48f6B86a26D3a217d0Fa6FfE2B491B956A7a2` (Unichain OptimismPortalProxy)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000001`
  - **Summary:** `ResourceMetering.ResourceParams`: `prevBoughtGas` becomes 450,000 (3 × 150,000) and `prevBlockNum` the simulation block; both are block-dependent. Only this slot of the portal may change.

On L2, once relayed, the OperatorFeeVault changes `recipient` / `withdrawalNetwork` (slot `2`) and `minWithdrawalAmount` (slot `1`); see the post-execution checks.

#### `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (L1PAO, root safe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `46` → **After:** `47`
  - **Summary:** nonce increment of the root safe. The before-value reflects the nonce state
    override in [config.toml](./config.toml).
- **Key (foundation path):** `0x5feb90d290db00fe85116d8bff6a5fc8349d22c1ec5f18248a1259a522847c94`
- **Key (council path):** `0xfd8d07d502f9ff07229ebb27fa47b28fb00d08466d7be93f1d72a5b780bc7807`
  - **Before:** `0` → **After:** `1`
  - **Summary:** `approvedHashes[<child safe>][0xa2118925…]`, the child safe's approval. Only the
    key of the path being simulated is written. Derive with
    `cast index bytes32 0xa2118925aa1a2e0bc5a54dee86cdd616cace28f22b2485ff412a32fd95dad487 $(cast index address <child> 8)`.

#### `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (FoundationUpgradeSafe), foundation path

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `76` → **After:** `77`
  - **Summary:** nonce increment of the approving child safe.

#### `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03` (SecurityCouncil), council path

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `73` → **After:** `74`
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
OV=0x420000000000000000000000000000000000001b

cast call $OV "recipient()(address)" -r $L2RPC              # 0xdead00000000000000000000000000000004dead
cast call $OV "withdrawalNetwork()(uint8)" -r $L2RPC        # 0
cast call $OV "minWithdrawalAmount()(uint256)" -r $L2RPC    # 150000000000000000
```
