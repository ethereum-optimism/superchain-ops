# 086-U19-op-betanet-permissioned

Status: READY TO SIGN

## Objective

Upgrades the Permissioned OP Labs Betanet (`karst-u19-beta-0`, chainId
`420110023`) to Upgrade 19 (`op-contracts/v7.1.17`) via `OPCM.upgradeSuperchain`
+ `OPCM.upgrade`.

This is the redo of task
[076-U19-op-betanet-permissioned](../076-U19-op-betanet-permissioned) against the
fresh `karst-u19-beta` replacement network (the original `u19-beta` betanet had
an issue).

The chain stays permissioned: only `PERMISSIONED_CANNON` is wired in the
DisputeGameFactory pre- and post-upgrade. OPCMv2 will additionally install
`CANNON_KONA` and disable the legacy `CANNON` slot (no-op here, since `CANNON`
was never enabled). After the task, the AnchorStateRegistry `respectedGameType`
is rotated to `CANNON_KONA` (8), per U19 protocol design.

`karst-u19-beta-1` is handled by tasks
[087-betanet-set-dispute-game-impl-permissionless](../087-betanet-set-dispute-game-impl-permissionless),
[088-betanet-set-respected-game-type-permissionless](../088-betanet-set-respected-game-type-permissionless),
and [089-U19-op-betanet-permissionless](../089-U19-op-betanet-permissionless).

## Simulation & Signing

```bash
cd src/tasks/sep/086-U19-op-betanet-permissioned

# Testing
just simulate-stack sep 086-U19-op-betanet-permissioned

# Commands to execute
just --dotenv-path $(pwd)/.env simulate
USE_KEYSTORE=1 just --dotenv-path $(pwd)/.env sign
# or USE_KEYSTORE=1 just sign-stack sep 086-U19-op-betanet-permissioned
SIGNATURES=0x just execute
```
