# 076-interop-jnt-v2-opcm-upgrade-v800

Status: DRAFT, NOT READY TO SIGN

## Objective

Upgrades the `interop-jnt-v2` devnet chains to the V800 OPCM implementation set and rotates the respected game type from `SUPER_PERMISSIONED_CANNON` to `SUPER_CANNON_KONA`.

The task targets:

- `interop-jnt-v2-0` (`420120102`)
- `interop-jnt-v2-1` (`420120103`)

## Simulation & Signing

```bash
cd src/tasks/sep/076-interop-jnt-v2-opcm-upgrade-v800

# Testing
just simulate-stack sep 076-interop-jnt-v2-opcm-upgrade-v800

# Commands to execute
just --dotenv-path $(pwd)/.env simulate
USE_KEYSTORE=1 just --dotenv-path $(pwd)/.env sign
# or USE_KEYSTORE=1 just sign-stack sep 076-interop-jnt-v2-opcm-upgrade-v800
SIGNATURES=0x just execute
```

## State Validation

Please see the instructions for [validation](./VALIDATION.md).
