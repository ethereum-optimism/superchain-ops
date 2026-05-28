# 076-U19-op-betanet-permissioned

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x224438675d623a5e21a3801d0bf238a8fbf7a1f3de1091041b234ab3eacdabe6)

## Objective

Upgrades the Permissioned OP Labs Betanet (`u19-beta-0`, chainId `420120035`) to
Upgrade 19 (`op-contracts/v7.1.17`) via `OPCM.upgradeSuperchain` + `OPCM.upgrade`.

The chain stays permissioned: only `PERMISSIONED_CANNON` is wired in the
DisputeGameFactory pre- and post-upgrade. OPCMv2 will additionally install
`CANNON_KONA` and disable the legacy `CANNON` slot (no-op here, since `CANNON`
was never enabled). After the task, the AnchorStateRegistry `respectedGameType`
is rotated to `CANNON_KONA` (8), per U19 protocol design.

`u19-beta-1` is handled by tasks
[077-betanet-set-dispute-game-impl-permissionless](../077-betanet-set-dispute-game-impl-permissionless),
[078-betanet-set-respected-game-type-permissionless](../078-betanet-set-respected-game-type-permissionless),
and [079-U19-op-betanet-permissionless](../079-U19-op-betanet-permissionless).

## Simulation & Signing

```bash
cd src/tasks/sep/076-U19-op-betanet-permissioned

# Testing
just simulate-stack sep 076-U19-op-betanet-permissioned

# Commands to execute
just --dotenv-path $(pwd)/.env simulate
USE_KEYSTORE=1 just --dotenv-path $(pwd)/.env sign
# or USE_KEYSTORE=1 just sign-stack sep 076-U19-op-betanet-permissioned
SIGNATURES=0x just execute
```
