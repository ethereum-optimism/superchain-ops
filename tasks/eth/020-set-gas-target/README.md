# Mainnet - Gas Target Increase

Status: [READY TO SIGN]

## Objective

This is the playbook for updating the onchain gas limit of the `SystemConfig`. When combined with setting the `GETH_MINER_EFFECTIVEGASLIMIT = 30_000_000` env var on the sequencers, this has the effect of keeping the gas limit at 30Mgas/block and increasing the gas target from 5Mgas/block (2.5Mgas/sec) to 10Mgas/block (5Mgas/sec).

### Timing

The transaction is scheduled for execution on October 22, 2024.

## Transaction creation

The transaction was created in the root directory with

```
just add-transaction tasks/eth/020-set-gas-target/input.json 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290 'setGasLimit(uint64)' 60000000
```

## Signing and execution

Please see the signing and execution instructions in [SINGLE.md](../../../SINGLE.md).
