# 091-alpha-set-dispute-game-impl-permissionless

Status: DRAFT, NOT READY TO SIGN

## Objective

Alpha analogue of task
[087-betanet-set-dispute-game-impl-permissionless](../087-betanet-set-dispute-game-impl-permissionless),
applied to the `karst-u19-alpha-1` network (chainId `420100011`).

Wires the `CANNON_KONA` (game type 8) implementation into `karst-u19-alpha-1`'s
DisputeGameFactory by calling
`factory.setImplementation(CANNON_KONA, 0x2DDA3584b51eF5236f7726Dea5A0FB6B3cA94AeC, gameArgs)`,
with the alpha kona absolute prestate
`0x03aabfc194f3a1181bf58e5a59ce4287c3153ea283728297e2f253ee423dac94` carried in
`gameArgs`. We re-use the shared `FaultDisputeGame` impl that was already deployed
during the alphanet's op-deployer run (`chain.yaml -> opChainDeployment.FaultDisputeGameImpl`)
— no fresh game contract deploy needed. The same task also rewrites the
`PERMISSIONED_CANNON` (game type 1) prestate to the `0xdead` placeholder (the
Guardian fallback game; op-program deprecated).

On-chain state confirmed on Sepolia before this task:

- `DGF.gameImpls(0)` (CANNON) = `0x0` → stays `0x0` (op-program retired; passthrough)
- `DGF.gameImpls(1)` (PERMISSIONED_CANNON) = `0xe1dFFCBE4e22B813F26d2106D943C102e7cAb87e`,
  prestate `0x0385…` → prestate rewritten to `0xdead…` (impl unchanged)
- `DGF.gameImpls(8)` (CANNON_KONA) = `0x0` → wired here for the first time
- `ASR.respectedGameType()` = `1` (PERMISSIONED) → flipped to `8` (CANNON_KONA) in task 092

This is the first half of the "switch to permissionless" flip for
`karst-u19-alpha-1`. The second half (set respected game type → `CANNON_KONA` / 8) is
[092-alpha-set-respected-game-type-permissionless](../092-alpha-set-respected-game-type-permissionless).
Once both have executed, the chain is officially permissionless. The final kona
prestate is set here at wire time; the end-of-PR prestate-sync task
[096-beta-1-kona-prestate-update](../096-beta-1-kona-prestate-update) only touches
`karst-u19-beta-1` (which is already live), not alpha-1.

The `CANNON` (game type 0) slot is left untouched: the config passes a zero impl +
empty `gameArgs` matching the current on-chain slot, which causes `SetDisputeGameImpl`
to early-return for the FDG path (see
[_setPDGImplementation](../../../template/SetDisputeGameImpl.sol)).

## Simulation & Signing

```bash
cd src/tasks/sep/091-alpha-set-dispute-game-impl-permissionless
just simulate-stack sep 091-alpha-set-dispute-game-impl-permissionless
SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env sign
```
