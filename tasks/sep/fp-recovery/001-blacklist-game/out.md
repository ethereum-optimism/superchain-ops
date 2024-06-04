# Deputy Guardian - Blacklist Dispute Game
This task executes a `blacklistDisputeGame` operation in the `OptimismPortal` on behalf of the `Guardian` role. Blacklisting the dispute game prevents any withdrawals proven to be contained within the game's proposed output root from being finalized.

The batch will be executed on chain ID `11155111`, and contains `1` transactions.

## Tx #1: Blacklist Dispute Game
Executes the `blacklistDisputeGame` call to the `OptimismPortal` proxy

**Function Signature:** `blacklistDisputeGame(address,address)`

**To:** `0x4220C5deD9dC2C8a8366e684B098094790C72d3c`

**Value:** `0 WEI`

**Raw Input Data:** `0x629cdd4900000000000000000000000016fc5058f25648194471939df75cf27a2fdc48bc00000000000000000000000016fc5058f25648194471939df75cf27a2fdc48bc`

### Inputs
**_portal:** `0x16Fc5058F25648194471939df75CF27A2fdC48BC`

**_game:** `0x16Fc5058F25648194471939df75CF27A2fdC48BC`

