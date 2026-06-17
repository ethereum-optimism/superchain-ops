# <task-name><short-description>

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Todo: Describe the objective of the task

## Simulation & Signing

Replace `<network>` (`eth` or `sep`) and `<council|foundation>` (the safe you
are signing for; `council` or `foundation`, Unichain also has `chain-governor`)
in the commands below. For a nested task, run each command once per safe. For a
task signed by a single safe, drop the `<council|foundation>` selector entirely.

`SKIP_DECODE_AND_PRINT=1` skips the slow human-readable state-diff printout
without changing the domain/message hashes you verify or the Tenderly link. It
is set on the sign command below; you can also prefix `simulate-stack` with it
for a faster run (review state changes via the Tenderly link instead).

### For Signers

```bash
# Change directory to the task
<navigate-to-simulation-command>

# Simulate
just simulate-stack <network> <task-name> <council|foundation>

# Sign
SKIP_DECODE_AND_PRINT=1 just sign-stack <network> <task-name> <council|foundation>

# Add USE_KEYSTORE=1 before the command if you are signing with a local keystore
# instead of a connected Ledger, e.g.
#   USE_KEYSTORE=1 SKIP_DECODE_AND_PRINT=1 just sign-stack <network> <task-name> <council|foundation>
```

### For Facilitators, after signatures have been collected

```bash
# Change directory to the task
<navigate-to-signing-command>

# Approve once per safe, passing that safe's collected signatures
SIGNATURES=0x... just approve <council|foundation>

# Execute once all required safes have approved
just execute

# Add USE_KEYSTORE=1 before the command if you are using a local keystore
# instead of a connected Ledger.
```
