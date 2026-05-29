# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are signing.

> [!CAUTION]
> These hashes were generated with **placeholder prestates** (`0xdead...`). They will change when real prestates are filled in.
>
> Additionally, task 056 (Unichain) cannot be simulated without the SuperchainConfig implementation stateOverride — Unichain's L1PAO cannot authorize ProxyAdmin.upgrade() on the shared SuperchainConfig. In production, tasks 053–055 run first, upgrading the superchain before 056 executes.

## Expected Domain and Message Hashes

TODO: populate after full stacked simulation (053 → 054 → 055 → 056) succeeds.

## Task Calldata

TODO: fill in calldata after simulation with real prestates.
