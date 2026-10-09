# 112-op-sepolia-system-config-owner-to-fus

Status: [CANCELLED]

DO NOT MERGE, REFERENCE ONLY, NOT A SAFE TASK

## Objective

Transfers ownership of the **OP Sepolia** (chainId 11155420) `SystemConfigProxy` from the EOA
`0xfd1D2e729aE8eEe2E146c033bf4400fE75284301` to the
[FoundationUpgradeSafe](../../../addresses.toml#L18) (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`)
with `transferOwnership(address)`.

| Chain | Chain ID | SystemConfigProxy | Field | Change |
|---|---|---|---|---|
| OP Sepolia | 11155420 | [`0x034edD2A225f7f429A63E0f1D2084B9E0A93b538`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/sepolia/op.toml#L52) | `owner()` | `0xfd1D2e729aE8eEe2E146c033bf4400fE75284301` → `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B` |

The current owner is an EOA, so this is a single transaction signed by that key and sent with
`cast`, not a Safe task: there is no `config.toml`, and `just simulate-stack` skips this folder.
It is kept here as a reference with the same validation shape as the other tasks.

> [!IMPORTANT]
> This is the prerequisite for the OP Sepolia OPE key rotation tasks (batcher and unsafe block
> signer), which are executed by the FoundationUpgradeSafe as SystemConfig owner. Until this
> transaction lands they simulate with a `SystemConfig.owner()` state override.

## Execution

For the holder of the EOA key. Run the pre-execution checks in [VALIDATION.md](./VALIDATION.md)
first, then send the transaction with one of the signer options below.

```bash
RPC=https://ethereum-sepolia-rpc.publicnode.com

# Ledger:
cast send 0x034edD2A225f7f429A63E0f1D2084B9E0A93b538 "transferOwnership(address)" 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B --rpc-url $RPC --ledger

# Raw private key, prompted at run time:
cast send 0x034edD2A225f7f429A63E0f1D2084B9E0A93b538 "transferOwnership(address)" 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B --rpc-url $RPC --interactive

# Raw private key imported once into an encrypted foundry keystore:
cast wallet import op-sep-sysconfig-owner --interactive
cast send 0x034edD2A225f7f429A63E0f1D2084B9E0A93b538 "transferOwnership(address)" 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B --rpc-url $RPC --account op-sep-sysconfig-owner
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the calldata breakdown, the pre-execution checks, the
expected state change and the post-execution checks.
