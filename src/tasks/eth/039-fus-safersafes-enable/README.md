# 039-fus-safersafes-enable

Status: DRAFT

## Objective

This task enables SaferSafes on the Foundation Upgrade Safe (FuS) on Ethereum mainnet.

SaferSafes provides enhanced liveness guarantees for the Safe by:
1. Enabling the SaferSafes module on the Safe
2. Configuring the liveness module with a 30-day response period
3. Setting the Security Council as the fallback owner

## Configuration

- **Target Safe**: Foundation Upgrade Safe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
- **SaferSafes Contract**: `0xA8447329e52F64AED2bFc9E7a2506F7D369f483a`
- **Liveness Response Period**: 30 days (2592000 seconds)
- **Fallback Owner**: Security Council (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)

## Simulation

```bash
cd src/tasks/eth/039-fus-safersafes-enable
SIMULATE_WITHOUT_LEDGER=1 just simulate
```

## Signing

```bash
cd src/tasks/eth/039-fus-safersafes-enable
just sign
```
