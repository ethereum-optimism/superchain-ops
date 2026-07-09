# Validation

This document can be used to validate the inputs and result of the execution of the transaction which you are signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes)
2. [Transaction Inputs](config.toml): inputs can be verified in the config.toml file.
3. State Changes: the template's `_validate` block asserts `SystemConfig.batcherHash()` and `SystemConfig.unsafeBlockSigner()` equal the configured (Gelato) values.

> [!IMPORTANT]
> This is a **contingency / rollback** task. The hashes below were generated against the **modelled post-migration state** (SystemConfig owner → FOS; batcherHash → OPE batcher; unsafeBlockSigner → OPE sequencer; FOS nonce 118 as of 2026-07-09) so the diff shows a genuine OPE → Gelato revert. At an actual rollback that state is live on-chain (remove the overrides) and the FOS nonce will have advanced — **you MUST re-run `just simulate` and replace these hashes before signing.**

## Expected Domain and Message Hashes

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### FoundationOperationsSafe (`0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`)
>
> - Domain Hash:  `0x2e5ad244d335c45fbace4ebd1736b0fad81b01591a2819baedad311ead5bce76`
> - Message Hash: `0xc27e57573bf7803c079ba4bb3500f9de3e60d0b28a5725f7febec3a7852bfb5e`
> - Safe Hash:    `0xc95ef10fe91e99d155f84514d077f16440e1237e91520335985b874c89b4f090`

## Understanding Task Calldata

The task batches two `SystemConfig` setters through Multicall3, targeting the Ink mainnet `SystemConfigProxy` (`0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364`).

```bash
# setBatcherHash(bytes32) — Gelato batcher left-padded to 32 bytes
cast calldata "setBatcherHash(bytes32)" 0x000000000000000000000000500d7ea63cf2e501dadaa5feec1fc19fe2aa72ac
# Expected: 0xc9b26f61000000000000000000000000500d7ea63cf2e501dadaa5feec1fc19fe2aa72ac

# setUnsafeBlockSigner(address) — Gelato unsafe block signer
cast calldata "setUnsafeBlockSigner(address)" 0x7D056B99AA2021864c42E25B4F8cE3BdEAc9463C
# Expected: 0x18d139180000000000000000000000007d056b99aa2021864c42e25b4f8ce3bdeac9463c
```

## Task State Changes

### `0x62c0a111929fa32cec2f76adba54c16afb6e8364` (SystemConfigProxy) — Chain ID 57073

- `batcherHash()` (slot `0x67`) reverts `0x0000000000000000000000006db6161fc5662450e801398bad62dd9921216b98` (OPE) → `0x000000000000000000000000500d7ea63cf2e501dadaa5feec1fc19fe2aa72ac` (Gelato).
- `unsafeBlockSigner()` (slot `0x65a7ed542fb37fe237fdfbdd70b31598523fe5b32879e307bae27a0bd9581c08`) reverts `0x7b322282DF45E537E5de76D60E1432Db3cF3F8E1` (OPE) → `0x7D056B99AA2021864c42E25B4F8cE3BdEAc9463C` (Gelato).

### `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A` (FoundationOperationsSafe)

Nonce `118` → `119`.

> [!NOTE]
> The `SystemConfig.owner()` (slot `0x33`), `batcherHash()` and `unsafeBlockSigner()` **pre-state** values shown here are simulation-only overrides modelling the post-migration state; they are not written by this task. Remove all three overrides at actual rollback time — the real post-migration values will be live on-chain.

## Post-execution verification

```bash
cast call 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364 "batcherHash()(bytes32)" --rpc-url mainnet
# Expected: 0x000000000000000000000000500d7ea63cf2e501dadaa5feec1fc19fe2aa72ac
cast call 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364 "unsafeBlockSigner()(address)" --rpc-url mainnet
# Expected: 0x7D056B99AA2021864c42E25B4F8cE3BdEAc9463C
```
