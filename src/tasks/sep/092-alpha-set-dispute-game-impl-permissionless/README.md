# 092-alpha-set-dispute-game-impl-permissionless

Status: READY TO SIGN

## Objective

Alpha analogue of task
[087-betanet-set-dispute-game-impl-permissionless](../087-betanet-set-dispute-game-impl-permissionless),
applied to the `karst-u19-alpha-1` network (chainId `420100011`).

Wires the permissionless `CANNON` (game type 0) implementation into
`karst-u19-alpha-1`'s DisputeGameFactory by calling
`factory.setImplementation(CANNON, 0x2DDA3584b51eF5236f7726Dea5A0FB6B3cA94AeC, gameArgs)`.
We re-use the shared `FaultDisputeGame` impl that was already deployed during the
alphanet's op-deployer run (`chain.yaml -> opChainDeployment.FaultDisputeGameImpl`)
— no fresh game contract deploy needed.

On-chain state confirmed on Sepolia before this task:

- `DGF.gameImpls(0)` (CANNON) = `0x0` → not set, wired here for the first time
- `DGF.gameImpls(1)` (PERMISSIONED_CANNON) = `0xe1dFFCBE4e22B813F26d2106D943C102e7cAb87e` → already wired
- `ASR.respectedGameType()` = `1` (PERMISSIONED) → flipped to `0` in task 093

This is the first half of the "switch to permissionless" flip for
`karst-u19-alpha-1`. The second half (set respected game type → `CANNON`) is
[093-alpha-set-respected-game-type-permissionless](../093-alpha-set-respected-game-type-permissionless).
Once both have executed, the chain is officially permissionless.

The `PERMISSIONED_CANNON` (game type 1) slot is left untouched: the config passes
the current on-chain impl + `gameArgs`, which causes `SetDisputeGameImpl` to
early-return for the PDG path (see
[_setPDGImplementation](../../../template/SetDisputeGameImpl.sol)).

## Simulation & Signing

```bash
cd src/tasks/sep/092-alpha-set-dispute-game-impl-permissionless
just simulate-stack sep 092-alpha-set-dispute-game-impl-permissionless
SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env sign
```
