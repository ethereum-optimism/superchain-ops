# 092-alpha-set-respected-game-type-permissionless

Status: DRAFT, NOT READY TO SIGN

## Objective

Alpha analogue of task
[088-betanet-set-respected-game-type-permissionless](../088-betanet-set-respected-game-type-permissionless),
applied to the `karst-u19-alpha-1` network (chainId `420100011`).

Switches the respected dispute game type in `karst-u19-alpha-1`'s
AnchorStateRegistry from `PERMISSIONED_CANNON` (1) to `CANNON_KONA` (8). Together
with
[091-alpha-set-dispute-game-impl-permissionless](../091-alpha-set-dispute-game-impl-permissionless)
(which wires the `CANNON_KONA` impl + kona prestate into the DGF), this is the flip
that makes `karst-u19-alpha-1` officially permissionless.

The guardian-mediated call is signed by the ProxyAdminOwner Safe
(`0x8E851F7d8bAeaD95F592847a020cAC7A062dafd9`) because the alphanet ASR's
`setRespectedGameType` is guarded by `SystemConfig.guardian()`, and the alphanet
guardian is the PAO Safe — not a separate GuardianSafe multisig as on OP Sepolia.
This was verified on-chain: `SystemConfig.guardian() == SuperchainConfig.guardian()
== ProxyAdmin.owner() == 0x8E851F7d8bAeaD95F592847a020cAC7A062dafd9`.

## Simulation & Signing

```bash
cd src/tasks/sep/092-alpha-set-respected-game-type-permissionless
just simulate-stack sep 092-alpha-set-respected-game-type-permissionless
SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env sign
```
