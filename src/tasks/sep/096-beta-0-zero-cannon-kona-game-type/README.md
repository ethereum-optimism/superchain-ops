# 096-beta-0-zero-cannon-kona-game-type

Status: DRAFT

## Objective

Corrective task (part 2 of 2) for `karst-u19-beta-0` (chainId `420110023`): remove the
CANNON_KONA (game type 8) implementation, so a permissioned chain has no permissionless game
(per the U19 clarification). Must run after
[095-beta-0-set-respected-game-type-permissioned](../095-beta-0-set-respected-game-type-permissioned),
which reverts `respectedGameType` to 1 first.

Uses [SetDisputeGameImpl](../../../template/SetDisputeGameImpl.sol) with a `[[konaGameImplConfig]]`
whose `impl = 0x0` — the template's disable path calls
`factory.setImplementation(CANNON_KONA, 0x0, "")` to zero the slot. FDG (game type 0) and PDG
(game type 1) are passthroughs (unchanged; beta-0's permissioned prestate is already `0xdead`).

End state for beta-0: `gameImpls(0)=0x0`, `gameImpls(1)=0xe1dF…/0xdead`, `gameImpls(8)=0x0`,
`respectedGameType=1` — a compliant permissioned chain.

## Simulation

```bash
cd src && just simulate-stack sep 096-beta-0-zero-cannon-kona-game-type
```
