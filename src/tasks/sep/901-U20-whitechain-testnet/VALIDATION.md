# Validation — 901-U20-whitechain-testnet

Simulated 2026-11-20 against live Sepolia state, PAO Safe nonce 6, after U19 (sep/900) and the
Karst L2 fork.

## Expected hashes

```
Safe Hash:      0x742af910a0da81a1444c71aacf312ff7aaf3a94c56ebc4bace6b3b5b2d14ae68
Domain Hash:    0x51f29ca0551362b92587cd685e062d74d8f6189c847da73569ffd14f97ab1552
Message Hash:   0x6e43f8a38cf65b3dbcf9acab844c966ddd827c44a4b03bb50c0b1d54ea1c3ddf
```

Data to sign (`0x1901 || domain || message`):

```
0x190151f29ca0551362b92587cd685e062d74d8f6189c847da73569ffd14f97ab15526e43f8a38cf65b3dbcf9acab844c966ddd827c44a4b03bb50c0b1d54ea1c3ddf
```

The Safe transaction hash was confirmed against the live Safe at nonce 6. The task calldata
(2468 bytes) is in [u20-task-calldata.txt](./u20-task-calldata.txt):

```bash
cast call 0x044a91B182C3B4c1b645421d9a3c498Dfa7cCb85 \
  "getTransactionHash(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,uint256)(bytes32)" \
  0x93dc480940585D9961bfcEab58124ffD3d60f76a 0 "$(cat u20-task-calldata.txt)" 1 0 0 0 \
  0x0000000000000000000000000000000000000000 0x0000000000000000000000000000000000000000 6 \
  --rpc-url "$SEPOLIA_RPC"
# 0x742af910a0da81a1444c71aacf312ff7aaf3a94c56ebc4bace6b3b5b2d14ae68
```

**These hashes are valid only at nonce 6.** If the Safe signs anything else first, regenerate.

Two of the three Safe owners carry an EIP-7702 delegation, which `MultisigTask.sol` misreads as a
nested Safe. `just simulate` needs the local patch that treats 23-byte `0xef0100…` code as an EOA.
The patch does not affect the calldata or the hashes; the `cast call` above proves that.

## Starting anchor root

| Config key | Value |
|---|---|
| `startingAnchorRootRoot` | `0x7664bf40cd54b297c9c7c15ac09dc32c8ce294ee490e7aaafa833d491507a1d4` |
| `startingAnchorRootL2SequenceNumber` | `1795176222` (L2 timestamp of block 13579854) |

Block 13579854 is finalized, 222 blocks after the Karst activation block 13579632, and inside the
safedb range of every Whitechain op-node. The root was derived from the public RPC with
`eth_getProof` (output root `0x050804a4b736c6481c7ea9fa9df7cc96ae84b57c6396c1e1b03bd368eb65c7c5`)
and matches what Whitechain's op-nodes return. Signers verify it against their own node:

```bash
cast rpc superroot_atTimestamp $(cast 2h 1795176222) --rpc-url $OPNODE | jq -r .data.super_root
# 0x7664bf40cd54b297c9c7c15ac09dc32c8ce294ee490e7aaafa833d491507a1d4
```

## State changes

**6 accounts, 22 storage slots.** No balance changes, no new contracts. `0x3608…2bbc` is the
ERC-1967 implementation slot.

### `0xfaa2fAA8912C069c01abc169c33713c79027c833` — DisputeGameFactoryProxy

`gameImpls` is mapping slot `0x65`, `gameArgs` slot `0x69`. A long `bytes` value keeps
`2 * length + 1` in its slot and its data from `keccak256(slot)` onward.

| Key | Before | After | Meaning |
|---|---|---|---|
| `0x4d5a9bd2…5f9e` | `0xe1dFFCBE…b87e` | `0x0` | `gameImpls[1]` cleared |
| `0xc073f36c…6add` | `0x149` | `0x0` | `gameArgs[1]` length cleared (was 164 bytes) |
| `0x9afb513d…fa7c` to `…fa81` | PERMISSIONED_CANNON args | `0x0` | `gameArgs[1]` data, 6 words cleared |
| `0xa658daa5…e9b2` | `0x0` | `0x5c3EB47c…d691` | `gameImpls[5]` → SuperPermissionedDisputeGame 1.1.0 |
| `0x58181d40…d979` | `0x0` | `0x51` | `gameArgs[5]` length, 40 bytes |
| `0x7879f54b…acf7` | `0x0` | `0x4da16596…a32c422af6c5…cb8d` | `gameArgs[5]` word 0: AnchorStateRegistry ‖ start of Proposer |
| `0x7879f54b…acf8` | `0x0` | `0xf68716b7…c63d00…` | `gameArgs[5]` word 1: rest of Proposer `0x422aF6C5…C63d` |

```bash
cast index uint32 1 0x65                  # 0x4d5a9bd2…5f9e
cast index uint32 5 0x65                  # 0xa658daa5…e9b2
cast index uint32 1 0x69                  # 0xc073f36c…6add, keccak of it = 0x9afb513d…fa7c
cast index uint32 5 0x69                  # 0x58181d40…d979, keccak of it = 0x7879f54b…acf7
```

### `0x4Da165963420dEeb0788f338b7A1Df41e535A32c` — AnchorStateRegistryProxy

The implementation does not change; v8 keeps AnchorStateRegistry 3.9.0.

| Key | Before | After | Meaning |
|---|---|---|---|
| `0x…02` | `0xc8fe9FA4…6BaA` | `0x0` | `anchorGame` cleared (was a type-1 game) |
| `0x…03` | `0xdead0000…0000` | `0x7664bf40…a1d4` | starting anchor root → the super root above |
| `0x…04` | `0x0` | `0x6b00371e` | starting anchor sequence number → 1795176222 |
| `0x…06` | `0x…6a3100d0 00000001` | `0x…6a3100d0 00000005` | `respectedGameType` 1 → 5, retirement timestamp unchanged |

### `0x9328Ea869949f33c57B7b680B6EdB58769e2181c` — SystemConfigProxy

| Key | Before | After | Meaning |
|---|---|---|---|
| `0x3608…2bbc` | `0x42Ad0173…4db9` | `0x670b850A…71fA` | implementation → SystemConfig 4.0.0 |
| `0x71ac1282…c597` | `0x00be0E81…d43e` | `0x0` | `systemconfig.batchinbox` zeroed; v8 removes `batchInbox()` |
| `0x99f45962…ff42` | `0x44e19705…8297` | `0x6AbfAbBC…f4Ca` | `systemconfig.opcm` → the v8 OPCM |

Zeroing the batch inbox is safe only because op-node and op-batcher read it from `rollup.json`.
**Confirm `batch_inbox_address` there is `0x00be0E81141C6Fb68542d5F4B29900c42AD8d43e` before
executing.** `minBaseFee` in slot `0x6c` is not touched.

### Implementation-only changes

| Account | Before → After | Version |
|---|---|---|
| `0xFF9b597b…D0C3` OptimismPortalProxy | `0xe89F13c5…D3C2` → `0x1005217a…6748` | OptimismPortal2 5.8.0 |
| `0x11854D31…426E` SuperchainConfig | `0xE4F9779a…D550` → `0x5570b1f2…7504` | SuperchainConfig 2.4.3 |

### `0x044a91B182C3B4c1b645421d9a3c498Dfa7cCb85` — ProxyAdminOwner Safe

| Key | Before | After | Meaning |
|---|---|---|---|
| `0x…05` | `6` | `7` | Safe nonce increment |

## After execution

```bash
cast call $SC "version()(string)" --rpc-url $RPC                  # 4.0.0
cast call $PORTAL "version()(string)" --rpc-url $RPC              # 5.8.0
cast call $SCC "version()(string)" --rpc-url $RPC                 # 2.4.3
cast call $DGF "gameImpls(uint32)(address)" 1 --rpc-url $RPC      # 0x0000000000000000000000000000000000000000
cast call $DGF "gameImpls(uint32)(address)" 5 --rpc-url $RPC      # 0x5c3EB47cB0174aEA522a2a9AE79487139a53D691
cast call $ASR "respectedGameType()(uint32)" --rpc-url $RPC       # 5
cast call $ASR "getAnchorRoot()(bytes32,uint256)" --rpc-url $RPC  # 0x7664bf40…a1d4, 1795176222
cast call $SC "isCustomGasToken()(bool)" --rpc-url $RPC           # true
cast call $SC "minBaseFee()(uint64)" --rpc-url $RPC               # 5000000000
cast call $SAFE "nonce()(uint256)" --rpc-url $RPC                 # 7
```

Then switch op-proposer to game type 5 with `--superroot-rpcs`, within 3.5 days. See
[README.md](./README.md), section "Component changes".
