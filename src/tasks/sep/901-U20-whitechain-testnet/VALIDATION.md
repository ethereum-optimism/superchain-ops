# Validation — 901-U20-whitechain-testnet

**NOT YET GENERATED.** This task cannot be simulated until sep/900 (U19) has executed and the starting anchor root has been obtained from Whitechain, so there are no hashes, no
calldata and no verified state diff. Do not sign anything against this file in its current form.

## What has to happen first

See [README.md](./README.md), section "Before this can be signed". In short:

1. Execute sep/900 (U19).
2. Refresh `addresses.json` with the new DelayedWETH proxy that U19 deploys.
3. Obtain a finalized single-chain super root from Whitechain's own op-node and set
   `startingAnchorRootRoot` / `startingAnchorRootL2SequenceNumber`. This is the hard blocker and
   needs Whitechain to expose an op-node serving `superroot_atTimestamp`.
4. Re-read `expectedValidationErrors` from the first simulation.

## How to fill this in

```bash
cd src/tasks/sep/901-U20-whitechain-testnet
OP_CI_SEPOLIA_L1_ARCHIVE_RPC_URL=<sepolia archive rpc> SIMULATE_WITHOUT_LEDGER=1 just simulate
```

The simulation prints the domain hash, message hash, Safe transaction hash, the task calldata and
the full state diff between the two "Attention" markers. Copy the diff in here, decode every
storage key, and confirm the Safe transaction hash independently against the live Safe:

```bash
cast call 0x044a91B182C3B4c1b645421d9a3c498Dfa7cCb85 \
  "getTransactionHash(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,uint256)(bytes32)" \
  0x93dc480940585D9961bfcEab58124ffD3d60f76a 0 "$(cat <task-calldata>)" 1 0 0 0 \
  0x0000000000000000000000000000000000000000 0x0000000000000000000000000000000000000000 <nonce> \
  --rpc-url "$SEPOLIA_RPC"
```

The Safe was at nonce 4 on 2026-11-06. sep/900 (U19) consumes one, so this task should sign at nonce 5. Re-verify before signing.

## Expected shape, from the rehearsal

The replica devnet (chain id 18740) executed this upgrade successfully, so the diff here should
match its shape. Use this as a cross-check, **not** as expected values: the addresses differ.

- **6 accounts, 21 storage slots** on the replica. Whitechain should be the same **minus the
  DisputeGameFactory owner write**, because its DGF owner is already the ProxyAdminOwner Safe where
  the replica's was an EOA. So expect 6 accounts and 20 slots, or 5 accounts if the DGF has no other
  write.
- Implementation moves: SystemConfig to 4.0.0 `0x670b850A…71fA`, OptimismPortal2 to 5.8.0
  `0x1005217a…6748`, SuperchainConfig to 2.4.3 `0x5570b1f2…7504`.
- `gameImpls(1)` cleared, `gameImpls(5)` set to the v8 SuperPermissionedDisputeGame, with 40 bytes
  of game args that are `AnchorStateRegistry ‖ Proposer`.
- `respectedGameType` 1 → 5 in AnchorStateRegistry slot 6, packed with an unchanged retirement
  timestamp.
- The anchor root and sequence number set to the super root from step 3.
- `batchInbox` zeroed in SystemConfig, since v8 removes `batchInbox()`. Safe only because the node
  and batcher read the inbox from `rollup.json`; **confirm Whitechain's rollup config carries
  `batch_inbox_address` before executing.**
- Safe nonce increment.
- `isCustomGasToken` must be **unchanged** at true, and `minBaseFee` untouched.

Full rehearsal diffs are in the git history of the removed replica tasks.
