# 073-gas-limit-ink

Status: [READY TO SIGN]

## Objective

Sets the **Ink Mainnet** (chainId 57073) `SystemConfig` gas limit from 60,000,000 back to
30,000,000 with a single `SystemConfig.setGasLimit(uint64)` call, executed directly by the
SystemConfig owner, the [Foundation Upgrade Safe](../../../addresses.toml#L6)
(`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`, owner since
[065-ink-system-config-owner-to-fus](../065-ink-system-config-owner-to-fus/README.md)).

| Chain | Chain ID | SystemConfigProxy | `gasLimit` |
|---|---|---|---|
| Ink | 57073 | [`0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/mainnet/ink.toml#L51) | 60,000,000 → 30,000,000 |

30,000,000 is Ink's genesis gas limit
([`ink.toml`, `genesis.system_config.gasLimit`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/mainnet/ink.toml#L43))
and the value Ink Sepolia runs with. The call emits a `ConfigUpdate` event that Ink adopts
once the L1 block containing it becomes an L1 origin. No other `SystemConfig` parameter
(fee scalars, EIP-1559 denominator and elasticity) changes.

> [!IMPORTANT]
> This task is sequenced after `071-U20-op-ink-soneium-uni` and
> `072-soneium-fee-vault-recipient-update`, each of which consumes one Foundation Upgrade Safe
> nonce as an L1PAO child; the nonce pin in [config.toml](./config.toml) assumes both have
> executed.

## Simulation & Signing

This is a **single-safe** task executed directly by the Foundation Upgrade Safe.

```bash
cd src/tasks/eth/073-gas-limit-ink

just simulate-stack eth 073-gas-limit-ink

SKIP_DECODE_AND_PRINT=1 just sign-stack eth 073-gas-limit-ink
```

## Execution

For facilitators, once the Foundation Upgrade Safe has collected its signatures. Run the
pre-execution checks in [VALIDATION.md](./VALIDATION.md) first. `just execute` refuses to run
without `SIGNATURES`.

```bash
cd src/tasks/eth/073-gas-limit-ink

SIGNATURES=0x... just execute
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the signer
checklist, the calldata breakdown, the pre-execution checks, the expected state changes and
the post-execution checks.
