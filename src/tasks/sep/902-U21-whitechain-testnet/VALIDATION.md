# Validation — 902-U21-whitechain-testnet

**NOT YET GENERATED.** This task cannot be simulated until sep/900 (U19) and sep/901 (U20) have executed, so there are no hashes, no
calldata and no verified state diff. Do not sign anything against this file in its current form.

## What has to happen first

See [README.md](./README.md), section "Before this can be signed". In short:

1. Execute sep/900 (U19), then sep/901 (U20), in that order.
2. Refresh `addresses.json` with the post-U19 DelayedWETH proxy.
3. Confirm `op-contracts/v9.0.0` is a final release; the registry still lists only
   `v9.0.0-rc.1` and the notice page is provisional with no governance proposal linked.
4. Re-read `expectedValidationErrors` from the first simulation.

## How to fill this in

```bash
cd src/tasks/sep/902-U21-whitechain-testnet
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

The Safe was at nonce 4 on 2026-11-06. sep/900 (U19) consumes one, and sep/901 (U20) another, so this task should sign at nonce 6. Re-verify before signing.

## Expected shape, from the rehearsal

The replica devnet (chain id 18740) **executed** this upgrade, and its post-execution state matched
the predicted diff exactly, including the ETHLockbox landing at the address the simulation
predicted. So the shape below is verified rather than merely simulated. Use it as a cross-check,
**not** as expected values: the addresses differ.

Verified on the replica after execution: Safe nonce 3, SystemConfig 4.3.0, OptimismPortal2 6.1.0,
AnchorStateRegistry 4.0.0, DelayedWETH 2.0.0, SuperchainConfig 2.5.0, the new ETHLockbox at 2.0.0
with a zero balance, `isCustomGasToken` still true, `respectedGameType` still 5 and the anchor root
unchanged. Proposals kept flowing afterwards.

- **8 accounts, 17 storage slots** on the replica, including **one newly deployed ETHLockbox
  proxy**. Whitechain should match, since U21 touches nothing that differs between the two chains.
- Implementation moves: SystemConfig to 4.3.0 `0xADe27248…4377`, OptimismPortal2 to 6.1.0
  `0xb20B23af…9645`, AnchorStateRegistry to 4.0.0 `0x2b27299C…52D0`, DelayedWETH to 2.0.0
  `0xF024e963…0e15`, SuperchainConfig to 2.5.0 `0xA303a644…01e7`, and L1CrossDomainMessenger to
  2.13.0 `0x7d4ec7fb…9448` through the AddressManager.
- A new ETHLockbox proxy: implementation `0xDF75E6b0…0aFe` (2.0.0), SuperchainConfig wired in,
  admin set to the chain's ProxyAdmin, and `authorizedPortals[portal] = true` at
  `cast index address <portal> 1`.
- `ethLockbox()` set on the portal, and the lockbox recorded on SystemConfig, DelayedWETH and
  packed into AnchorStateRegistry slot 6.
- `isFeatureEnabled[ETH_LOCKBOX] = true` at `cast index bytes32 <"ETH_LOCKBOX" bytes32> 0x6d`.
- `systemconfig.opcm` moved to the v9 OPCM.
- Safe nonce increment.

**What must NOT appear**: any DisputeGameFactory write, any change to the anchor root or
sequence number, any change to `isCustomGasToken`, any balance change. The lockbox must end with a
zero balance, because Whitechain is a custom gas token chain whose portal holds no ETH.

Full rehearsal diffs are in the git history of the removed replica tasks.
