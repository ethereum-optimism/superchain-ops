# Deputy Guardian - Enable Permissioness Dispute Game

Status: READY TO SIGN

## Objective

> [!WARNING]
> The first task, `ink-001-permissionless-proofs`, needs to be executed first to set the game implementations. 
> This task should only be executed after the permissionless fault proofs have been tested in the cold path and the chain operator is ready to enable permissionless proofs.

This task updates the `respectedGameType` in the `OptimismPortalProxy` to `CANNON`, enabling users to permissionlessly propose outputs as well as for anyone to participate in the dispute of these proposals. This action requires all in-progress withdrawals to be re-proven against a new `FaultDisputeGame` that was created after this update occurs. To execute, collect signatures and execute the action according to the instructions in [SINGLE.md](../../../../SINGLE.md).

