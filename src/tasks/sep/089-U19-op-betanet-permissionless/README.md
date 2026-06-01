# 089-U19-op-betanet-permissionless

Status: READY TO SIGN

## Objective

Redo of task
[079-U19-op-betanet-permissionless](../079-U19-op-betanet-permissionless) against
the fresh `karst-u19-beta` replacement network.

Upgrades the (now-Permissionless) OP Labs Betanet `karst-u19-beta-1` (chainId
`420110024`) to Upgrade 19 (`op-contracts/v7.1.17`) via
`OPCM.upgradeSuperchain` + `OPCM.upgrade`.

This task assumes the two preceding tasks have already made `karst-u19-beta-1`
officially permissionless:
- [087-betanet-set-dispute-game-impl-permissionless](../087-betanet-set-dispute-game-impl-permissionless)
  wired the permissionless `CANNON` impl into the DisputeGameFactory.
- [088-betanet-set-respected-game-type-permissionless](../088-betanet-set-respected-game-type-permissionless)
  flipped ASR.respectedGameType to 0 (CANNON).

After this upgrade runs, OPCMv2 will:

- Rewire `PERMISSIONED_CANNON` to its v7.1.17 impl (kept as Guardian fallback).
- Install `CANNON_KONA` with the configured `cannonKonaPrestate`.
- Rotate the AnchorStateRegistry `respectedGameType` to `CANNON_KONA` (8).
- Per V700 template, leave `CANNON` as `_isEnabled=false`. Whether the OPCM
  preserves the existing CANNON wiring or zeroes it out is what tasks 087–089
  collectively test.

The companion U19 task for the Permissioned betanet (`karst-u19-beta-0`) is
[086-U19-op-betanet-permissioned](../086-U19-op-betanet-permissioned).

## Simulation & Signing

```bash
cd src/tasks/sep/089-U19-op-betanet-permissionless

# Testing
just simulate-stack sep 089-U19-op-betanet-permissionless

# Commands to execute
just --dotenv-path $(pwd)/.env simulate
USE_KEYSTORE=1 just --dotenv-path $(pwd)/.env sign
# or USE_KEYSTORE=1 just sign-stack sep 089-U19-op-betanet-permissionless
SIGNATURES=0x just execute
```
