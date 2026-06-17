# 101-gas-params-op

Status: [REFERENCE — CALLDATA ONLY]()

## Objective

Karst (U19) gas-limit reset for **OP Sepolia Testnet** (chainId `11155420`).

The Karst hardfork leaves the effective L2 block gas limit ~55 MGas above the value stored
in the SystemConfig (an op-node/kona bug that fails to reset the gas limit after the
activation block — see Notion "P/PS: Karst Gas Limit Bug"). Re-issuing the SystemConfig gas
params re-emits the gas `ConfigUpdate`, which resets the effective gas limit back to the
on-chain value. Run **after Karst activates on Sepolia (June 17, 2026)**.

This re-affirms OP Sepolia's current on-chain gas params:
- `gasLimit`: 40,000,000 (unchanged)
- `eip1559Denominator`: 250, `eip1559Elasticity`: 2 (current on-chain values, unchanged)

## Why calldata-only (no superchain-ops task)

OP Sepolia's SystemConfig is owned by an **EOA** (`0xfd1D2e729aE8eEe2E146c033bf4400fE75284301`),
not a Safe. The superchain-ops task framework roots tasks at a Safe, so there is no Safe
transaction to simulate — the owner EOA simply sends the calls below directly.

## Calldata

Target SystemConfig (OP Sepolia): `0x034edD2A225f7f429A63E0f1D2084B9E0A93b538`
([superchain-registry](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/op.toml)).
Send both calls from the SystemConfig owner EOA `0xfd1D2e729aE8eEe2E146c033bf4400fE75284301`.

### 1. `setGasLimit(uint64 _gasLimit)` — `_gasLimit = 40000000`

```bash
cast calldata "setGasLimit(uint64)" 40000000
```
```
0xb40a817c0000000000000000000000000000000000000000000000000000000002625a00
```

Example send (operator supplies the owner key):
```bash
cast send 0x034edD2A225f7f429A63E0f1D2084B9E0A93b538 \
  "setGasLimit(uint64)" 40000000 --rpc-url sepolia --ledger   # or --private-key / --account
```

### 2. `setEIP1559Params(uint32 _denominator, uint32 _elasticity)` — `_denominator = 250`, `_elasticity = 2`

```bash
cast calldata "setEIP1559Params(uint32,uint32)" 250 2
```
```
0xc0fd4b4100000000000000000000000000000000000000000000000000000000000000fa0000000000000000000000000000000000000000000000000000000000000002
```

> `setGasLimit` is the essential mitigation (it re-emits the gas `ConfigUpdate`).
> `setEIP1559Params` re-affirms the current on-chain EIP-1559 params (behavioral no-op).
> Verify after execution: `gasLimit()` = 40000000, `eip1559Denominator()` = 250, `eip1559Elasticity()` = 2.
