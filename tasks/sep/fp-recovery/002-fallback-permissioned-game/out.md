# Guardian - Fall back to `PermissionedDisputeGame`
This batch udates the `respectedGameType` to `PERMISSIONED_CANNON` in the `OptimismPortal`. This action requires all in-progress withdrawals to be re-proven against a new `PermissionedDisputeGame` that was created after this update occurs.

The batch will be executed on chain ID `11155111`, and contains `1` transactions.

## Tx #1: Update `respectedGameType` in the `OptimismPortal`
Updates the `respectedGameType` to `PERMISSIONED_CANNON` in the `OptimismPortal`, enabling permissioned proposals and challenging.

**Function Signature:** `setRespectedGameType(uint32)`

**To:** `0x16Fc5058F25648194471939df75CF27A2fdC48BC`

**Value:** `0 WEI`

**Raw Input Data:** `0x7fc485040000000000000000000000000000000000000000000000000000000000000001`

### Inputs
**_gameType:** `1`

