# 026-transition-to-liveness-module2

Status: [EXAMPLE TASK]

## Objective

Perform a complete transition from the current liveness setup to LivenessModule2 on the Guardian Safe. This task will:

1. Disable the current liveness module
2. Deactivate the LivenessGuard by setting the guard to address(0)  
3. Enable the new LivenessModule2
4. Configure LivenessModule2 with appropriate parameters for Sepolia

The LivenessModule2 provides stronger guarantees around system liveness and improves the robustness of the protocol's fault-handling mechanisms.

## Pre-requisites

- The current LivenessModule must be enabled at the address specified in config
- The LivenessGuard must be currently set on the Safe
- The LivenessModule2 must be deployed at `0xBF83aCe11Fa979b90C1e914cC5565271f22C6615`
- The Guardian Safe must have the current liveness setup that needs to be transitioned

## Transaction Details

This task will perform the following operations in sequence:

1. **Clear current module configuration** (if supported by the current module)
2. **Disable current liveness module** from the Guardian Safe
3. **Deactivate LivenessGuard** by calling `setGuard(address(0))`
4. **Enable LivenessModule2** on the Guardian Safe
5. **Configure LivenessModule2** with:
   - Liveness response period: 30 days (2592000 seconds)
   - Fallback owner: Foundation Operations Safe (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`)

## Configuration Parameters

The task requires these parameters in `config.toml`:

- `currentModule`: Address of the current liveness module to disable
- `previousModule`: Address of the previous module in the Safe's module linked list (use `0x1` if current module is first)
- `newModule`: Address of the new LivenessModule2 to enable
- `currentGuard`: Address of the current LivenessGuard (required - must not be address(0))
- `livenessResponsePeriod`: Time period for liveness responses (30 days = 2592000 seconds)
- `fallbackOwner`: Address that will serve as the fallback owner
- `livenessModuleVersion`: Expected version string of LivenessModule2 for validation

### Safe Address Configuration

You can specify the Safe address in two ways:

1. **Using registry name** (default):
   ```toml
   safeAddressString = "GuardianSafe"
   ```

2. **Using direct address override**:
   ```toml
   safeAddress = "0x7a50f00e8d05b95f98fe38d8bee366a7324dcf7e"
   ```

## Execution

1. Run the task:
   ```bash
   SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../../../src/improvements/justfile simulate
   ```

## Validation

The task will validate:

- The current liveness module is properly disabled from the Safe
- The LivenessGuard is deactivated (guard set to address(0))
- The new LivenessModule2 is enabled on the Safe
- The new module is properly configured with the specified parameters
- All storage writes are as expected for the complete transition

## Post-execution

After successful execution:

- The old liveness module will be disabled and cleared
- The LivenessGuard will be deactivated  
- The LivenessModule2 will be active on the Guardian Safe
- The fallback owner mechanism will be in place with a 30-day response period
- The Safe will have a clean transition to the new liveness architecture

## Security Considerations

- This operation temporarily disables liveness protections during the transition
- The transaction should be executed promptly to minimize the window without liveness protection
- Verify all addresses in the configuration are correct before execution
- Ensure the new LivenessModule2 is properly audited and deployed