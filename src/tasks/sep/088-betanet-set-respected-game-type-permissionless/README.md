# 088-betanet-set-respected-game-type-permissionless

Status: READY TO SIGN

## Objective

Redo of task
[078-betanet-set-respected-game-type-permissionless](../078-betanet-set-respected-game-type-permissionless)
against the fresh `karst-u19-beta` replacement network.

Switches the respected dispute game type in `karst-u19-beta-1`'s
AnchorStateRegistry from `PERMISSIONED_CANNON` (1) to the permissionless `CANNON`
(0). Together with
[087-betanet-set-dispute-game-impl-permissionless](../087-betanet-set-dispute-game-impl-permissionless)
(which wires the `CANNON` impl into the DGF), this is the flip that makes
`karst-u19-beta-1` (chainId `420110024`) officially permissionless ahead of its
U19 upgrade in [089-U19-op-betanet-permissionless](../089-U19-op-betanet-permissionless).

This is the analogue of sepolia task 051 — the "set respected" half of the
U18-era 050 + 051 flip, but applied to karst-u19-beta-1 in the U19 sequence.

The Guardian-mediated call is signed by the betanet ProxyAdminOwner Safe
(`0x8E851F7d8bAeaD95F592847a020cAC7A062dafd9`) because the betanet ASR checks
`msg.sender == SystemConfig.guardian()`, and the betanet guardian is the PAO
Safe — not a separate GuardianSafe multisig as on OP Sepolia.

## Simulation & Signing

```bash
cd src/tasks/sep/088-betanet-set-respected-game-type-permissionless
just simulate-stack sep 088-betanet-set-respected-game-type-permissionless
SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env sign
```
