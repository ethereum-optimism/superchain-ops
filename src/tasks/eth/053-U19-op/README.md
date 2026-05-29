# 053-U19-op

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Upgrades OP Mainnet (chainId `10`) to Upgrade 19 (`op-contracts/v7.1.17`)
via `OPCM.upgradeSuperchain` + `OPCM.upgrade`.

U19 installs `CANNON_KONA` (game type 8) as the new primary FPVM, rotates
`AnchorStateRegistry.respectedGameType` to `CANNON_KONA` (8), and disables
the legacy `CANNON` slot (sets `gameImpls[CANNON] = address(0)`).
`PERMISSIONED_CANNON` (1) is rewired by OPCMv2 as the emergency Guardian fallback.

This task is first in the U19 Mainnet upgrade sequence (`053` → `054` → `055` → `056`)
and serves as the gas benchmark. Check Tenderly gas output against the
16,777,216 per-transaction cap before proceeding with bundled tasks.

## Simulation & Signing

```bash
# Simulate (gas benchmark)
just simulate-stack eth 053-U19-op

# Sign
USE_KEYSTORE=1 just sign-stack eth 053-U19-op

# Execute
cd src/tasks/eth/053-U19-op
SIGNATURES=0x just execute
```
