# 090-U19-betanet-kona-prestate-update

Status: READY

## Objective

Updates the `CANNON_KONA` (game type 8) absolute prestate on both U19 OP Labs
Betanet chains — `karst-u19-beta-0` (chainId `420110023`) and
`karst-u19-beta-1` (chainId `420110024`) — from `0x03a887…7e88` to
`0x0335abee576086a6d8628e809ed166af671c643e98d678d66dee27b8bb307a28`.

The new prestate was built reproducibly from `kona-client/v1.6.0-rc.1`
(`ethereum-optimism/optimism` @ `1e4fe99977885a6efd517251e08afe1ef13c8334`,
variant `cannon64-kona`) with the karst-u19-beta rollup configs embedded. The
only change versus tasks 086/089 is the karst activation time: `karst_time`
moved `1780372800 → 1780421400`, which yields a new embedded prestate hash. Both
chains are embedded in the single build.

## Mechanism

Both chains are **already on U19** (`op-contracts/v7.1.17`); this task does NOT
re-run the upgrade. The `CANNON_KONA` game is a blueprint-style FaultDisputeGame
(v2.4.2) whose absolute prestate is carried in the factory's `gameArgs`
(`prestate(32) | vm(20) | anchorStateRegistry(20) | delayedWETH(20) |
chainId(32)`), not as an immutable on the impl. So the update is a single call
per chain:

```
DisputeGameFactory.setImplementation(8, 0x2DDA3584b51eF5236f7726Dea5A0FB6B3cA94AeC, newGameArgs)
```

where `0x2DDA35…` is the **existing** on-chain kona impl (reused verbatim, so its
contract version is preserved) and `newGameArgs` is the live `gameArgs(8)` value
with only the leading 32-byte prestate swapped. This is performed by the
`SetDisputeGameArgs` template, which writes only to `DisputeGameFactoryProxy`.

`AddGameType` was deliberately not used: the only OPCMs exposing `addGameType`
deploy older FaultDisputeGame versions (the v6.0.0 OPCM ships FDG v2.2.0), which
would downgrade the v2.4.2 kona game on this v7.1.17 stack, and the v7.1.17 OPCM
(OPCMv2) has no `addGameType`.

## Simulation & Signing

```bash
cd src/tasks/sep/090-U19-betanet-kona-prestate-update

# Testing
just simulate-stack sep 090-U19-betanet-kona-prestate-update

# Commands to execute
just --dotenv-path $(pwd)/.env simulate
USE_KEYSTORE=1 just --dotenv-path $(pwd)/.env sign
SIGNATURES=0x just execute
```

## Pre-flight checks

- Re-verify the ProxyAdminOwner Safe nonce before signing:
  `cast call 0x8E851F7d8bAeaD95F592847a020cAC7A062dafd9 "nonce()" --rpc-url sepolia`
  and update the `[stateOverrides]` value in [config.toml](config.toml) if it has
  advanced past `7`.
- Confirm the new kona preimage `0x0335abee…307a28.bin.gz` has been uploaded to
  `gs://oplabs-network-data/proofs/kona/cannon/` and that `op-challenger` /
  `vm-runner` are wired to serve it, before the updated game type can be played.
