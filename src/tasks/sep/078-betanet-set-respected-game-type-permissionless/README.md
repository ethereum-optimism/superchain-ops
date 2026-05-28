# 078-betanet-set-respected-game-type-permissionless

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x93a13e48eaf8b37da09a5477483e8bf6581f8a5980af6936daff8a1e80ca066d)

## Objective

Switches the respected dispute game type in `u19-beta-1`'s AnchorStateRegistry
from `PERMISSIONED_CANNON` (1) to the permissionless `CANNON` (0). Together with
[077-betanet-set-dispute-game-impl-permissionless](../077-betanet-set-dispute-game-impl-permissionless)
(which wires the `CANNON` impl into the DGF), this is the flip that makes
`u19-beta-1` (chainId `420120036`) officially permissionless ahead of its U19
upgrade in [079-U19-op-betanet-permissionless](../079-U19-op-betanet-permissionless).

This is the analogue of sepolia task 051 — the "set respected" half of the
U18-era 050 + 051 flip, but applied to u19-beta-1 in the U19 sequence.

The Guardian-mediated call is signed by the betanet ProxyAdminOwner Safe
(`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`) because the betanet ASR checks
`msg.sender == SystemConfig.guardian()`, and the betanet guardian is the PAO
Safe EOA — not a separate GuardianSafe multisig as on OP Sepolia.

## Simulation & Signing

```bash
cd src/tasks/sep/078-betanet-set-respected-game-type-permissionless
just simulate-stack sep 078-betanet-set-respected-game-type-permissionless
SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env sign
```
