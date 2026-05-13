# 077-interop-jnt-v2-opcm-migrate-v800

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x7bf7f64f71652aec08e94254783e15028268f8fdb2a294f0305aae00247ce883)

## Objective

Migrates the `interop-jnt-v2` devnet chains with the V800 OPCM migration template and sets the migrated interop set to respect `SUPER_CANNON_KONA`.

The task targets:

- `interop-jnt-v2-0` (`420120102`)
- `interop-jnt-v2-1` (`420120103`)

## Simulation & Signing

```bash
cd src/tasks/sep/077-interop-jnt-v2-opcm-migrate-v800

# Testing
just simulate-stack sep 077-interop-jnt-v2-opcm-migrate-v800

# Commands to execute
just --dotenv-path $(pwd)/.env simulate
USE_KEYSTORE=1 just --dotenv-path $(pwd)/.env sign
# or USE_KEYSTORE=1 just sign-stack sep 077-interop-jnt-v2-opcm-migrate-v800
SIGNATURES=0x just execute
```

## State Validation

Please see the instructions for [validation](./VALIDATION.md).
