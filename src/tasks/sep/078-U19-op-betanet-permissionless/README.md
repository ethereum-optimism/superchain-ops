# 078-U19-op-betanet-permissionless

Status: READY TO SIGN

## Objective

Upgrades the (now-Permissionless) OP Labs Betanet `u19-beta-1` (chainId
`420120036`) to Upgrade 19 (`op-contracts/v7.1.17`) via
`OPCM.upgradeSuperchain` + `OPCM.upgrade`.

This task assumes
[077-betanet-set-respected-game-type-permissionless](../077-betanet-set-respected-game-type-permissionless)
has already flipped `u19-beta-1`'s respected game type to permissionless
`CANNON` (0). After this upgrade runs, OPCMv2 will:

- Rewire `PERMISSIONED_CANNON` to its v7.1.17 impl (kept as Guardian fallback).
- Install `CANNON_KONA` with the configured `cannonKonaPrestate`.
- Disable the legacy `CANNON` slot in the DisputeGameFactory (existing games still resolve).
- Rotate the AnchorStateRegistry `respectedGameType` to `CANNON_KONA` (8).

The companion U19 task for the Permissioned betanet (`u19-beta-0`) is
[076-U19-op-betanet-permissioned](../076-U19-op-betanet-permissioned).

## Simulation & Signing

```bash
cd src/tasks/sep/078-U19-op-betanet-permissionless

# Testing
just simulate-stack sep 078-U19-op-betanet-permissionless

# Commands to execute
just --dotenv-path $(pwd)/.env simulate
USE_KEYSTORE=1 just --dotenv-path $(pwd)/.env sign
# or USE_KEYSTORE=1 just sign-stack sep 078-U19-op-betanet-permissionless
SIGNATURES=0x just execute
```
