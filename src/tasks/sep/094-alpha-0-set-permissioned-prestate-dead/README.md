# 094-alpha-0-set-permissioned-prestate-dead

Status: DRAFT, NOT READY TO SIGN

## Objective

`karst-u19-alpha-0` (chainId `420100010`) stays **permissioned** under U19. This task only
normalizes the `PERMISSIONED_CANNON` (game type 1) prestate to the `0xdead…` placeholder,
matching the permissioned betanet (beta-0) and the U19 clarification: a permissioned chain keeps
`respectedGameType = 1`, must **not** wire game type 8, and its permissioned game prestate may be
the `0xdead` placeholder (op-program deprecated).

What this does (and does not) change:
- game type 1 prestate `0x0385…` → `0xdead…` (impl `0xe1dF…` unchanged)
- game type 0 stays `0x0`; game type 8 stays `0x0` (no `[[konaGameImplConfig]]`)
- `respectedGameType` stays `1` (no SetRespectedGameType task for alpha-0)

Uses [SetDisputeGameImpl](../../../template/SetDisputeGameImpl.sol) (PDG-only change; FDG is a
zero passthrough).

## Simulation

```bash
cd src && just simulate-stack sep 094-alpha-0-set-permissioned-prestate-dead
```
