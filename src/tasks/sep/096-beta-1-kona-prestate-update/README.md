# 096-beta-1-kona-prestate-update

Status: DRAFT, NOT READY TO SIGN

## Objective

Final step of this PR: update the `CANNON_KONA` (game type 8) absolute prestate for the
permissionless betanet chain `karst-u19-beta-1` (chainId `420110024`).

`karst-u19-beta-1` is already live on U19 (`op-contracts/v7.1.17`) — permissionless, with
`respectedGameType = 8` and `gameImpls(8) = 0x2DDA3584b51eF5236f7726Dea5A0FB6B3cA94AeC`, wired by
the executed betanet tasks
[086](../086-U19-op-betanet-permissioned)–[090](../090-U19-betanet-kona-prestate-update). This
task does **not** re-run any upgrade or game-type flip; it only re-points the kona prestate.

- Old prestate (from executed task 090): `0x0335abee576086a6d8628e809ed166af671c643e98d678d66dee27b8bb307a28`
- New prestate: `0x03550cad406d92b986a67047befd635b6dc90b14eae2b7733e8b60c05f429ec2`

Uses [SetDisputeGameArgs](../../../template/SetDisputeGameArgs.sol): it reads the live
`gameArgs(8)`, keeps every field (impl, vm, anchorStateRegistry, delayedWETH, chainId, bond) and
swaps only the 32-byte prestate, then calls `DisputeGameFactory.setImplementation(8, sameImpl,
newGameArgs)`. The template is idempotent and asserts the slot ends up holding exactly the new
gameArgs.

The companion permissionless alphanet chain `karst-u19-alpha-1` is introduced fresh in this PR, so
its final prestate `0x03aabfc1…dac94` is set at wire time in task
[091-alpha-set-dispute-game-impl-permissionless](../091-alpha-set-dispute-game-impl-permissionless)
— it needs no separate bump. **End state after this PR fully executes:** alpha-1 kona prestate
`0x03aabfc1…`, beta-1 kona prestate `0x03550cad…`.

## Simulation & Signing

```bash
cd src/tasks/sep/096-beta-1-kona-prestate-update
just simulate-stack sep 096-beta-1-kona-prestate-update
SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env sign
```
