# OP Sepolia: Increase gas *limit* (P0) — limit 20M → 40M gas/s, target held at 10M gas/s

> [!NOTE]
> This is **not** a superchain-ops Safe task. OP Sepolia's `SystemConfig` is owned
> by an **EOA** (`0xfd1D2e729aE8eEe2E146c033bf4400fE75284301` — the
> `SystemConfigOwner` per the superchain-registry), not the `FoundationUpgradeSafe`.
> The change is therefore made by sending transactions directly from that EOA.
> The OP Mainnet equivalent is the Safe task at `src/tasks/eth/055-gas-params-op-p0`.

## Objective

This is the **P0** step of an incremental gas roll-out, mirroring OP Mainnet
`055-gas-params-op-p0`. Double the block `gasLimit` on OP Sepolia from `40_000_000` to
`80_000_000` **and** double `eip1559_elasticity` from `2` to `4`, keeping
`eip1559_denominator = 250`. This doubles the gas **limit** while holding the gas
**target** constant:

```
gasTarget = (onchain gasLimit) / (eip1559_elasticity) = 80M / 4 = 20Mgas/block  (unchanged)
gasLimit  = (onchain gasLimit)                        = 80Mgas        (2x)
```

With 2s blocks:
* gas **limit**: 20Mgas/s → **40Mgas/s** (2x)
* gas **target**: 10Mgas/s → **10Mgas/s** (unchanged)

> [!NOTE]
> **P0 contingency** (only if the target is reached): double the gas target to 20Mgas/s
> by lowering elasticity back to 2 (keeping the 80M limit) — `setEIP1559Params(250, 2)`.
> This mirrors OP Mainnet `056-gas-params-op-target`.
> **P1 (future):** raise the gas limit a further 2.5x to 100Mgas/s (`setGasLimit(200000000)`).

## Parameters

| Field | Value |
|---|---|
| Chain | OP Sepolia (chainId 11155420) |
| L1 | Ethereum Sepolia (chainId 11155111) |
| SystemConfig (L1) | `0x034edD2A225f7f429A63E0f1D2084B9E0A93b538` |
| Owner (sender) | `0xfd1D2e729aE8eEe2E146c033bf4400fE75284301` (EOA) |
| `gasLimit` | `40000000` → **`80000000`** |
| `eip1559Elasticity` | `2` → **`4`** |
| `eip1559Denominator` | `250` (unchanged) |

## Pre-checks

Set the L1 RPC (must be Sepolia, chainId 11155111):

```bash
export ETH_RPC_URL=<sepolia-l1-rpc>
SC=0x034edD2A225f7f429A63E0f1D2084B9E0A93b538

cast chain-id                                   # expect 11155111
cast call $SC "owner()(address)"                # expect 0xfd1D2e729aE8eEe2E146c033bf4400fE75284301
cast call $SC "gasLimit()(uint64)"              # expect 40000000
cast call $SC "eip1559Elasticity()(uint32)"     # expect 2
cast call $SC "eip1559Denominator()(uint32)"    # expect 250
```

## Execute

Send from the owner EOA. Use whichever signer you hold the key with — `--ledger`,
`--account <keystore>`, or `--private-key`. Both calls revert unless `--from` is the
owner above.

```bash
# 1. Raise the block gas limit to 80M.
cast send $SC "setGasLimit(uint64)" 80000000 \
  --rpc-url "$ETH_RPC_URL" \
  --ledger   # or: --account <keystore-name> / --private-key <key>

# 2. Raise eip1559_elasticity to 4 (denominator unchanged at 250). This holds the gas
#    target at 10Mgas/s while the limit doubles to 40Mgas/s.
cast send $SC "setEIP1559Params(uint32,uint32)" 250 4 \
  --rpc-url "$ETH_RPC_URL" \
  --ledger   # or: --account <keystore-name> / --private-key <key>
```

Encoded calldata for reference (verify against your wallet):

- `setGasLimit(uint64)` → `0xb40a817c0000000000000000000000000000000000000000000000000000000004c4b400`
- `setEIP1559Params(uint32,uint32)` → `0xc0fd4b4100000000000000000000000000000000000000000000000000000000000000fa0000000000000000000000000000000000000000000000000000000000000004`

## Post-checks

```bash
cast call $SC "gasLimit()(uint64)"            # expect 80000000
cast call $SC "eip1559Elasticity()(uint32)"   # expect 4
cast call $SC "eip1559Denominator()(uint32)"  # expect 250
```

Storage slot `0x68` should change from
`0x...000d273000001db00000000002625a00` (gasLimit 40M) to
`0x...000d273000001db00000000004c4b400` (gasLimit 80M); `basefeeScalar` (`0xd2730`)
and `blobbasefeeScalar` (`0x1db0`) are unchanged. Slot `0x6a` should change from
`0x...0002000000fa` (elasticity 2 / denominator 250) to
`0x...0004000000fa` (elasticity 4 / denominator 250).

After the change, monitor per the [Raising gas target/limit runbook (RB-180)](https://www.notion.so/13df153ee16280199d3acf26b9a50614):
base fee should rise when `gasUsed > gasTarget` and fall when below it, and no block
should exceed `gasLimit`.
