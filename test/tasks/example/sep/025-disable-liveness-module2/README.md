# 025-disable-liveness-module2

Status: [EXAMPLE TASK]

## Objective

Disable the LivenessModule2 on the Guardian Safe and clear its configuration.

This task should be executed when the LivenessModule2 needs to be temporarily or permanently disabled.

## Pre-requisites

- The LivenessModule2 must be currently enabled on the Guardian Safe at `0xBF83aCe11Fa979b90C1e914cC5565271f22C6615`
- The `previousModule` parameter in `config.toml` must be updated to reflect the current module order

## Testing Note

For testing purposes, the `config.toml` includes state overrides that simulate:
1. The LivenessModule2 being already enabled on the Guardian Safe
2. The module being configured with a 30-day response period and Foundation Ops Safe as fallback owner

These overrides allow testing the disable functionality without requiring the module to be actually enabled first.

## Important Note on `previousModule`

The `previousModule` parameter must be set correctly before execution:
1. Query the Safe's current modules using `getModulesPaginated()`
2. Find the module that points to the LivenessModule2 in the linked list
3. Update `previousModule` in `config.toml` with this address
4. If LivenessModule2 is the only module, use `0x0000000000000000000000000000000000000001` (SENTINEL_MODULE)

## Transaction Details

This task will:
1. Clear the LivenessModule2 configuration for the Safe
2. Disable the LivenessModule2 on the Guardian Safe

## Execution

1. Verify and update `previousModule` in `config.toml` as described above

2. Set up environment variables in `.env`:
   - `RPC_URL`: Sepolia RPC endpoint
   - `PRIVATE_KEY`: Private key for signing

3. Run the task:
   ```bash
   just run-task sep 025-disable-liveness-module2
   ```

## Validation

The task will validate:
- The module is disabled on the Safe
- The module configuration is cleared (response period = 0, fallback owner = address(0))
- The module is no longer in the Safe's module list
- All storage writes are as expected

## Post-execution

After successful execution:
- The LivenessModule2 will be disabled on the Guardian Safe
- The module's configuration will be cleared
- The module can be re-enabled later if needed (note that challenge start time will be reset upon re-enabling)