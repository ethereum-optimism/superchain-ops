# 077-betanet-set-respected-game-type-permissionless

Status: READY TO SIGN

## Objective

Switches the respected dispute game type in `u19-beta-1`'s AnchorStateRegistry
from `PERMISSIONED_CANNON` (1) to the permissionless `CANNON` (0). This is the
final flip that makes `u19-beta-1` (chainId `420120036`) officially permissionless
ahead of its U19 upgrade in
[078-U19-op-betanet-permissionless](../078-U19-op-betanet-permissionless).

> Pre-condition: the permissionless `CANNON` game type must be wired into the
> chain's `DisputeGameFactory` before this set-respected call resolves any new
> disputes. `u19-beta-1`'s `chain.yaml` currently has
> `DelayedWethPermissionlessGameProxy = 0x0`, so an `AddGameTypeTemplate` task
> (mirroring sepolia task 050) is required for u19-beta-1 first. This file is
> the analogue of sepolia task 051 (the "set respected" half of the U18-era
> 050 + 051 flip).

The Guardian-mediated call is signed by the betanet ProxyAdminOwner Safe
(`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`) because the betanet ASR checks
`msg.sender == SystemConfig.guardian()`, and the betanet guardian is the PAO
Safe EOA — not a separate GuardianSafe multisig as on OP Sepolia.

## Simulation & Signing

```bash
cd src/tasks/sep/077-betanet-set-respected-game-type-permissionless
just simulate-stack sep 077-betanet-set-respected-game-type-permissionless
SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env sign
```
