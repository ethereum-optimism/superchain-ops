# 087-betanet-set-dispute-game-impl-permissionless

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0xdd56a3bbf5d6f4bbd3f8ffbbcfaedf8b18209b3282a1bf73886d0da7e0c49e35)

## Objective

Redo of task
[077-betanet-set-dispute-game-impl-permissionless](../077-betanet-set-dispute-game-impl-permissionless)
against the fresh `karst-u19-beta` replacement network.

Wires the permissionless `CANNON` (game type 0) implementation into
`karst-u19-beta-1`'s DisputeGameFactory by calling
`factory.setImplementation(CANNON, 0x6dDBa09bc4cCB0D6Ca9Fc5350580f74165707499, gameArgs)`.
This is the chain-side analogue of sepolia task
[050-op-betanet-add-game-type](../050-op-betanet-add-game-type) but uses
[SetDisputeGameImpl](../../../template/SetDisputeGameImpl.sol) so we re-use the
`FaultDisputeGame` impl that was already deployed during the betanet's
op-deployer run — no fresh game contract deploy needed.

This is the first half of the "switch to permissionless" flip for
`karst-u19-beta-1`. The second half (set respected game type → `CANNON`) is
[088-betanet-set-respected-game-type-permissionless](../088-betanet-set-respected-game-type-permissionless).
Once both have executed, the chain is "officially permissionless" and ready for
U19 upgrade in
[089-U19-op-betanet-permissionless](../089-U19-op-betanet-permissionless).

The `PERMISSIONED_CANNON` (game type 1) slot is left untouched: the config
passes the current on-chain impl + `gameArgs`, which causes `SetDisputeGameImpl`
to early-return for the PDG path (see [_setPDGImplementation](../../../template/SetDisputeGameImpl.sol)).

## Simulation & Signing

```bash
cd src/tasks/sep/087-betanet-set-dispute-game-impl-permissionless
just simulate-stack sep 087-betanet-set-dispute-game-impl-permissionless
SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env sign
```
