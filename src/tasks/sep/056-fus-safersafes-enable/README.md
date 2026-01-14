# 056-fus-safersafes-enable

Status: [READY TO SIGN]()

## Objective

This task enables SaferSafes on the Foundation Upgrade Safe (FuS) on Sepolia.

SaferSafes provides enhanced liveness guarantees for the Safe by:
1. Enabling the SaferSafes module on the Safe
2. Configuring the liveness module with a 30-day response period
3. Setting the Security Council as the fallback owner

## Configuration

- **Target Safe**: Foundation Upgrade Safe (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`)
- **SaferSafes Contract**: `0xA8447329e52F64AED2bFc9E7a2506F7D369f483a`
- **Liveness Response Period**: 30 days (2592000 seconds)
- **Fallback Owner**: Security Council (`0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`)

## Simulation

To simulate this task in the context of the full task stack:

```bash
cd src
SIMULATE_WITHOUT_LEDGER=1 just simulate-stack sep 056-fus-safersafes-enable
```

To simulate just this task standalone:

```bash
cd src/tasks/sep/056-fus-safersafes-enable
SIMULATE_WITHOUT_LEDGER=1 just simulate
```

## Signing

```bash
cd src
just sign-stack sep 056-fus-safersafes-enable
```
