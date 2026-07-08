# 062-ink-revert-system-config-owner: ROLLBACK — revert Ink SystemConfig ownership to the Gelato Safe

Status: DRAFT — CONTINGENCY / ROLLBACK. NOT READY TO SIGN. Use only if the Ink mainnet Gelato → OPE migration must be aborted.

## Objective

Reverts ownership of the Ink (mainnet, chainId `57073`) `SystemConfigProxy` from the post-migration OP-side owner (`FoundationOperationsSafe`) **back to the original Ink/Gelato Safe**. This is the exact reverse of [`eth/055-ink-transfer-system-config-owner`](../055-ink-transfer-system-config-owner) (PR #1462, Gelato → FOS).

- **Target**: `SystemConfigProxy` [`0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364`](https://etherscan.io/address/0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364) ([superchain-registry](https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/mainnet/ink.toml))
- **Current owner** (signer): [`0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`](https://etherscan.io/address/0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A) — `FoundationOperationsSafe` (the post-migration owner; see [`src/addresses.toml`](../../../addresses.toml))
- **New owner**: [`0xBeA2Bc852a160B8547273660E22F4F08C2fa9Bbb`](https://etherscan.io/address/0xBeA2Bc852a160B8547273660E22F4F08C2fa9Bbb) — the original Ink/Gelato 3-of-5 Safe

> [!IMPORTANT]
> This task assumes the forward migration has completed and `SystemConfig.owner()` is the `FoundationOperationsSafe`. Before the forward migration executes, `owner()` is still the Gelato Safe on-chain; [config.toml](./config.toml) overrides slot `0x33` → FOS for standalone simulation. Verify the live owner before signing:
> ```bash
> cast call 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364 "owner()(address)" --rpc-url mainnet
> ```

> [!CAUTION]
> Once executed, only the Gelato Safe can change SystemConfig parameters or transfer ownership again — the OP side gives up control. Confirm the destination `0xBeA2Bc…9Bbb` is the pre-migration owner recorded in the role audit (§3.1) / execution log before signing.

## Rollback order

Run the setter reverts first, then this ownership revert **last**:

1. [`063-ink-revert-batcher-unsafe-signer`](../063-ink-revert-batcher-unsafe-signer) — restore Gelato batcher + unsafe block signer (signed by FOS, while it still owns SystemConfig).
2. [`064-ink-revert-proposer-rotation`](../064-ink-revert-proposer-rotation) — restore Gelato proposer on the PDG (signed by L1PAO — independent).
3. **This task (062)** — hand SystemConfig ownership back to Gelato.

## Signers

`FoundationOperationsSafe` is a single-layer Safe (v1.3.0). See [SINGLE.md](../../../../docs/SINGLE.md).

## Simulation & Signing

```bash
cd src/tasks/eth/062-ink-revert-system-config-owner
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../justfile simulate
just --dotenv-path $(pwd)/.env --justfile ../../../justfile sign
```

## Post-execution verification

```bash
cast call 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364 "owner()(address)" --rpc-url mainnet
# Expected: 0xBeA2Bc852a160B8547273660E22F4F08C2fa9Bbb
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, calldata breakdown, and expected state changes.
