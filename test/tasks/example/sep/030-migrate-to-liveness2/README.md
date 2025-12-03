# MigrateToLiveness2 Task

## Overview

This task migrates a Safe from the v1 liveness module (which combined guard and module functionality) to the v2 SaferSafes-based liveness system.

## What This Task Does

1. Removes the guard (sets it to `address(0)`)
2. Enables the SaferSafes module
3. Configures the liveness module settings
4. Disables the old liveness module

## State Override Explanation

### Why do we need `stateOverrides` in the config?

The config includes a state override that temporarily removes the guard during simulation:

```toml
[stateOverrides]
0xB2DEfc35a51E4f2126667A9FC8D941202077aC0E = [
     {key = "0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8", value = 0}
]
```

**This is only needed for simulation, NOT for production.**

### The Problem

The old liveness guard has a `checkTransaction()` hook that runs **before** every Safe transaction. This guard checks that `msg.sender` (the caller of `execTransaction`) is a Safe owner.

**In simulation:**
- The MultisigTask framework contract calls `execTransaction()`
- The guard sees `msg.sender = MultisigTask contract` (not an owner)
- The guard blocks the transaction with error `TimelockGuard_NotOwner()`

**In production (using `just sign` and `just execute`):**
- Owners sign the transaction using `just sign`
- An owner executes the transaction using `just execute`
- The guard sees `msg.sender = owner`
- The guard allows the transaction to proceed

### The Solution

The state override temporarily sets the guard slot to `address(0)` during simulation, bypassing the guard check. This allows the simulation framework to test the transaction logic without needing to be an owner.

**Important:** This is purely a simulation workaround. In production, an owner must run `just execute` so the guard check passes. The transaction will succeed without any override.
