# 054-betanet-safersafes-enable

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x56c4dbd2d0e15cc0118bd5e2963d3d77798011228079f755425d00cf52e8c9f6)

## Objective

This task enables SaferSafes on the Betanet Safe on Sepolia.

SaferSafes provides enhanced liveness guarantees for the Safe by:
1. Enabling the SaferSafes module on the Safe
2. Configuring the liveness module with a 1-minute response period
3. Setting the Security Council as the fallback owner

## Configuration

- **Target Safe**: Betanet Safe (`0x0e0375aFAb3AB4b19A329ea94a6C67FaEfd352Cd`)
- **SaferSafes Contract**: `0xA8447329e52F64AED2bFc9E7a2506F7D369f483a`
- **Liveness Response Period**: 1 minute (60 seconds)
- **Fallback Owner**: Security Council (`0xf64bc17485f0B4Ea5F06A96514182FC4cB561977`)

## Simulation

To simulate this task in the context of the full task stack:

```bash
cd src
SIMULATE_WITHOUT_LEDGER=1 just simulate-stack sep 054-betanet-safersafes-enable
```

To simulate just this task standalone:

```bash
cd src/tasks/sep/054-betanet-safersafes-enable
SIMULATE_WITHOUT_LEDGER=1 just simulate
```

## Signing

```bash
cd src
just sign-stack sep 054-betanet-safersafes-enable
```
