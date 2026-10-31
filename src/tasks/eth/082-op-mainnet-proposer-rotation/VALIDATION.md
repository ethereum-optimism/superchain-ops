# Validation

This document can be used to validate the inputs and result of the execution of the
transaction which you are signing.

## Expected Domain and Message Hashes

Validate the domain and message hashes. These values should match both the values on your
ledger and the values printed to the terminal when you run the task. The hashes assume the pinned nonces in [config.toml](./config.toml) (L1PAO 48,
FoundationUpgradeSafe 80, SecurityCouncil 75) and move
only if those inputs move.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### FoundationUpgradeSafe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `0xa4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672`
> - Message Hash: `0xa798c2865cf3cb2fc5b41a26672eb0a12e8b3b847947ebae430e2ef7c982be8f`
>
> ### SecurityCouncil (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash:  `0xdf53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967`
> - Message Hash: `0x6c620f09411044481b233a3812885b280dae0dbccf3a9923cc5b24d45e27ec91`

Root L1PAO (`0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`) safe transaction hash (identical on both signing paths):
`0x97dc2f234607ba494af753493f1c7d2740ac9b84826a2436a1568473a13bfbd6`

## For Signers

Simulate the task and check the output against this file before signing.

```bash
cd src/tasks/eth/082-op-mainnet-proposer-rotation
just simulate-stack eth 082-op-mainnet-proposer-rotation council   # or foundation
```

Check:

1. The domain and message hashes printed to the terminal match the ones at the top of this
   file.
2. In the Tenderly link printed by the simulation: paste the **entire execution calldata printed
   beneath the link** into the **Raw input data** field and simulate. It starts with `0x174dea71`
   (`aggregate3Value` on Multicall3 `0xcA11bde05977b3631167028862bE2a173976CA11`) and bundles two
   `execTransaction` calls: the child safe approving the L1PAO transaction hash, then the L1PAO
   executing the task. It is longer than the [task calldata](#task-calldata) below, which also
   starts with `0x174dea71`. The storage writes must match
   [Task State Changes](#task-state-changes), which also explains the simulation's nonce overrides
   and sender nonce bump.
3. The call trace shows one `setImplementation` on `0xe5965Ab5962eDc7477C8520243A95517CD252fA9` with `_gameType = 5`, `_impl = 0x5C3eb47cB0174aea522a2a9Ae79487139A53D691` and the 40-byte `_args` in the [Understanding Task Calldata](#understanding-task-calldata) table, and no other call.

## For Facilitators and Reviewers

Everything from here on is for facilitators executing the task and for reviewers. Signers only
need the two sections above.

### Task Calldata

The inner `aggregate3Value` payload, for decoding and verification. It is what the L1PAO
delegatecalls into `Multicall3DelegateCall`. It is not the Tenderly input: the full simulation
payload printed by `just simulate-stack` (see step 2 above) also starts with `0x174dea71`, but is
the outer Multicall3 bundle of the child safe approval and the L1PAO `execTransaction`, which
wraps this payload.

```
0x174dea71000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000e5965ab5962edc7477c8520243a95517cd252fa900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000c4b107095700000000000000000000000000000000000000000000000000000000000000050000000000000000000000005c3eb47cb0174aea522a2a9ae79487139a53d6910000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000002823b2c62946350f4246f9f9d027e071f0264fd113c27ba3e0fc01567a5e57ae0c391aa98cecba5be000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
```

### Understanding Task Calldata

The task is a single `Multicall3DelegateCall.aggregate3Value` from the L1PAO (selector
`0x174dea71`) containing **1** call(s), each with `allowFailure = false` and
`value = 0`:

| # | Target | Function | Arguments |
|---|---|---|---|
| 1 | `0xe5965Ab5962eDc7477C8520243A95517CD252fA9` (DisputeGameFactoryProxy) | `setImplementation(uint32,address,bytes)` | `_gameType = 5`, `_impl = 0x5C3eb47cB0174aea522a2a9Ae79487139A53D691`, `_args = 0x23b2c62946350f4246f9f9d027e071f0264fd113c27ba3e0fc01567a5e57ae0c391aa98cecba5be0` (anchorStateRegistry \| proposer) |

To verify the payload fingerprints:

```bash
cast calldata "setImplementation(uint32,address,bytes)" 5 0x5C3eb47cB0174aea522a2a9Ae79487139A53D691 0x23b2c62946350f4246f9f9d027e071f0264fd113c27ba3e0fc01567a5e57ae0c391aa98cecba5be0
# Expected: 0xb107095700000000000000000000000000000000000000000000000000000000000000050000000000000000000000005c3eb47cb0174aea522a2a9ae79487139a53d6910000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000002823b2c62946350f4246f9f9d027e071f0264fd113c27ba3e0fc01567a5e57ae0c391aa98cecba5be0000000000000000000000000000000000000000000000000
```

The payload and the target each appear exactly once. To decode the full calldata:

```bash
cast calldata-decode "aggregate3Value((address,bool,uint256,bytes)[])" <task calldata>
```

### Pre-execution checks and execution

```bash
RPC=https://ethereum-rpc.publicnode.com

cast call 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A "nonce()(uint256)" -r $RPC   # 48
cast call 0x847B5c174615B1B7fDF770882256e2D3E95b9D92 "nonce()(uint256)" -r $RPC   # 80
cast call 0xc2819DC788505Aac350142A7A707BF9D03E3Bd03 "nonce()(uint256)" -r $RPC   # 75
cast call 0xe5965Ab5962eDc7477C8520243A95517CD252fA9 "gameImpls(uint32)(address)" 5 -r $RPC   # 0x5C3eb47cB0174aea522a2a9Ae79487139A53D691
cast call 0xe5965Ab5962eDc7477C8520243A95517CD252fA9 "gameArgs(uint32)(bytes)" 5 -r $RPC    # 0x23b2c62946350f4246f9f9d027e071f0264fd113473300df21d047806a082244b417f96b32f13a33
```

Then execute with the collected signatures:

```bash
cd src/tasks/eth/082-op-mainnet-proposer-rotation

SIGNATURES=0x... just approve council
SIGNATURES=0x... just approve foundation
just execute
```

### Task State Changes

#### `0xe5965Ab5962eDc7477C8520243A95517CD252fA9` (OP Mainnet DisputeGameFactoryProxy)

- **Key:** `0x7879f54b7a738fb6adc3b9585859cd2970241c1545ca5cbe8b1895abdfa5acf7`
  - **Before:** `0x23b2c62946350f4246f9f9d027e071f0264fd113473300df21d047806a082244`
  - **After:**  `0x23b2c62946350f4246f9f9d027e071f0264fd113c27ba3e0fc01567a5e57ae0c`
- **Key:** `0x7879f54b7a738fb6adc3b9585859cd2970241c1545ca5cbe8b1895abdfa5acf8`
  - **Before:** `0xb417f96b32f13a33000000000000000000000000000000000000000000000000`
  - **After:**  `0x391aa98cecba5be0000000000000000000000000000000000000000000000000`
  - **Summary:** the two data slots of the `gameArgs[5]` bytes value: the first 20 bytes (anchorStateRegistry) are unchanged, the proposer moves to `0xc27ba3E0Fc01567a5E57Ae0c391AA98cECBA5bE0`. `gameImpls[5]` is rewritten with its current value (no diff); `initBonds[5]` is not written (no `bond` in the config, live value 0).

#### `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (L1PAO, root safe)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `48` → **After:** `49`
  - **Summary:** nonce increment of the root safe. The before-value reflects the nonce state
    override in [config.toml](./config.toml).
- **Key (foundation path):** `0xb29240af3a63af3492f52a80c2b07bd6d192550d1380d75c3e3458fa963967ff`
- **Key (council path):** `0xf6c300399dfe4c9b8553735ae35ee58f152c8ee378dace7fb5b0d6e7fbdf6fc7`
  - **Before:** `0` → **After:** `1`
  - **Summary:** `approvedHashes[<child safe>][0x97dc2f23…]`, the child safe's approval. Only the
    key of the path being simulated is written. Derive with
    `cast index bytes32 0x97dc2f234607ba494af753493f1c7d2740ac9b84826a2436a1568473a13bfbd6 $(cast index address <child> 8)`.

#### `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` (FoundationUpgradeSafe), foundation path

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `80` → **After:** `81`
  - **Summary:** nonce increment of the approving child safe.

#### `0xc2819DC788505Aac350142A7A707BF9D03E3Bd03` (SecurityCouncil), council path

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005`
  - **Before:** `75` → **After:** `76`
  - **Summary:** nonce increment of the approving child safe.

#### `0x24424336F04440b1c28685a38303aC33C9D14a25` (SecurityCouncil LivenessGuard), council path

- **Key:** `0xee4378be6a15d4c71cb07a5a47d8ddc4aba235142e05cb828bb7141206657e27`
  - **Summary:** `lastLive[0xca11bde05977b3631167028862bE2a173976CA11]` set to the simulation timestamp, a simulation
    artifact (the simulation makes Multicall3 the sole signer of the child safe).

Tenderly also shows `Nonce N → N+1` (no storage key) on the Safe owner used as the simulation's
sender. Its protocol account nonce, unrelated to the Safe's signing nonce.

### Post-execution verification calls

```bash
RPC=https://ethereum-rpc.publicnode.com

cast call 0xe5965Ab5962eDc7477C8520243A95517CD252fA9 "gameArgs(uint32)(bytes)" 5 -r $RPC    # 0x23b2c62946350f4246f9f9d027e071f0264fd113c27ba3e0fc01567a5e57ae0c391aa98cecba5be0
cast call 0xe5965Ab5962eDc7477C8520243A95517CD252fA9 "gameImpls(uint32)(address)" 5 -r $RPC   # 0x5C3eb47cB0174aea522a2a9Ae79487139A53D691 (unchanged)
cast call 0xe5965Ab5962eDc7477C8520243A95517CD252fA9 "initBonds(uint32)(uint256)" 5 -r $RPC   # 0 (unchanged)
```
