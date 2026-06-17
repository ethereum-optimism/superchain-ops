# 056-gas-params-ink

Status: [REFERENCE — CALLDATA ONLY]()

## Objective

Karst (U19) gas-limit reset for **Ink Mainnet** (chainId `57073`).

The Karst hardfork leaves the effective L2 block gas limit ~55 MGas above the value stored
in the SystemConfig (an op-node/kona bug that fails to reset the gas limit after the
activation block — see Notion "P/PS: Karst Gas Limit Bug"). Re-issuing the SystemConfig gas
params re-emits the gas `ConfigUpdate`, which resets the effective gas limit back to the
on-chain value. Run **after Karst activates on Mainnet (July 8, 2026)**.

This re-affirms Ink Mainnet's current effective gas params:
- `gasLimit`: 60,000,000 (unchanged)
- `eip1559Denominator`: 250, `eip1559Elasticity`: 6 (Ink predates on-chain EIP-1559 config;
  these are its genesis/Canyon defaults from the superchain-registry, confirmed via the L2
  block-header `extraData`. Writing them explicitly is a behavioral no-op.)

## Why calldata-only (no superchain-ops task)

Ink Mainnet's SystemConfig is owned by the operator Safe
`0xBeA2Bc852a160B8547273660E22F4F08C2fa9Bbb` (a 3-of-5 Safe). One of its signers
(`0x6a0A93Cd6d6FB7a36bF6234ef4650Bf9474e7682`) is an **EIP-7702-delegated EOA** (it has
code). The superchain-ops simulator (`MultisigTask`) treats any owner-with-code as a Safe
and calls `nonce()` on it during simulation, which reverts for a 7702 account — so this task
cannot be driven through `just simulate-stack`. (The transaction itself is valid; only the
repo's simulator is affected. The other U19 gas-reset tasks rooted at standard Safes
simulate normally.)

The operator should execute the two SystemConfig calls below via their own Safe tooling
(e.g. the Safe{Wallet} transaction builder), batched or sequential.

## Calldata

Target SystemConfig (Ink Mainnet): `0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364`
([superchain-registry](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/ink.toml)).
Both calls are sent from the SystemConfig owner Safe `0xBeA2Bc852a160B8547273660E22F4F08C2fa9Bbb`.

### 1. `setGasLimit(uint64 _gasLimit)` — `_gasLimit = 60000000`

```bash
cast calldata "setGasLimit(uint64)" 60000000
```
```
0xb40a817c0000000000000000000000000000000000000000000000000000000003938700
```

### 2. `setEIP1559Params(uint32 _denominator, uint32 _elasticity)` — `_denominator = 250`, `_elasticity = 6`

```bash
cast calldata "setEIP1559Params(uint32,uint32)" 250 6
```
```
0xc0fd4b4100000000000000000000000000000000000000000000000000000000000000fa0000000000000000000000000000000000000000000000000000000000000006
```

> `setGasLimit` is the essential mitigation (it re-emits the gas `ConfigUpdate`).
> `setEIP1559Params` makes Ink's implicit genesis EIP-1559 params explicit (behavioral no-op).
> Verify the resulting values after execution: `gasLimit()` = 60000000, `eip1559Denominator()` = 250, `eip1559Elasticity()` = 6.
