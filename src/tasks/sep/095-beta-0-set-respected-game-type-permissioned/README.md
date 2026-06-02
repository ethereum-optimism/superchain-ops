# 095-beta-0-set-respected-game-type-permissioned

Status: DRAFT, NOT READY TO SIGN

## Objective

Corrective task (part 1 of 2) to realign `karst-u19-beta-0` (chainId `420110023`) with the U19
clarification that **permissioned chains keep `respectedGameType = 1` and must not expose game
type 8**.

beta-0 is intended to be permissioned, but the earlier U19 work — task
[086-U19-op-betanet-permissioned](../086-U19-op-betanet-permissioned), run before the
clarification — set `startingRespectedGameType = 8` and wired CANNON_KONA via OPCMUpgradeV700.
On-chain today beta-0 has `respectedGameType = 8` and `gameImpls(8) = 0x2DDA…`.

This task reverts `respectedGameType` **8 → 1**. Companion task
[096-beta-0-zero-cannon-kona-game-type](../096-beta-0-zero-cannon-kona-game-type) then zeroes the
game type 8 implementation. Running respected→1 first keeps the respected pointer on the
(still-wired) permissioned game before game type 8 is removed.

Runs as the ProxyAdminOwner Safe (beta-0's ASR guards on `SystemConfig.guardian()` == the PAO
Safe, same as betanet task 088).

## Simulation

```bash
cd src && just simulate-stack sep 095-beta-0-set-respected-game-type-permissioned
```
