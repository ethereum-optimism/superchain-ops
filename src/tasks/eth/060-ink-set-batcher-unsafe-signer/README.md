# 060-ink-set-batcher-unsafe-signer

Status: [READY TO SIGN]()

Simulates successfully with the stacked FoundationOperationsSafe nonce recorded in [config.toml](./config.toml); domain/message/safe hashes recorded in [VALIDATION.md](./VALIDATION.md). Re-run `just simulate` to regenerate the hashes if the FOS nonce advances or the `SystemConfig.owner` override is removed (after the ownership transfer) before signing.

## Objective

Registers the OP Enterprise (OPE) batcher and unsafe block signer on the **Ink mainnet** (chainId 57073) `SystemConfig` as part of the **Gelato → OPE rollup-operator migration** (Type A Standard OP Stack takeover). This batches cutover steps **2** (`setBatcherHash`) and **3** (`setUnsafeBlockSigner`) into a single Multicall3 transaction.

Source of truth: _Ink Mainnet Migration — Engineering Plan_ (§3.3 Addresses; target cutover 2026-07-28). This task is the mainnet counterpart of the Ink Sepolia rehearsal task `sep/101-ink-sepolia-set-batcher-unsafe-signer` (executed 2026-06-22).

| Field | Current (Gelato) | New (OPE) |
|-------|------------------|-----------|
| `batcherHash()` | `0x00…500d7Ea63CF2E501dadaA5feeC1FC19FE2Aa72Ac` | `0x00…6db6161fC5662450E801398Bad62dD9921216B98` |
| `unsafeBlockSigner()` | `0x7D056B99AA2021864c42E25B4F8cE3BdEAc9463C` | `0x7b322282DF45E537E5de76D60E1432Db3cF3F8E1` |

- **Target**: `SystemConfigProxy` `0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364` (resolved from the superchain-registry).
- **Signer**: `FoundationOperationsSafe` `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A` — the SystemConfig owner after the Gelato → FOS ownership transfer.

> [!IMPORTANT]
> This task assumes the `SystemConfig` owner is the **FoundationOperationsSafe**. On Ink mainnet the owner is currently the **Gelato Safe** (`0xBeA2Bc852a160B8547273660E22F4F08C2fa9Bbb`, verified on-chain); the Gelato → FOS `transferOwnership` is performed **outside this repo** ([PR #1462](https://github.com/ethereum-optimism/superchain-ops/pull/1462), Migration Plan steps **W25/W26**). For simulation, [config.toml](./config.toml) overrides `SystemConfig.owner()` (slot `0x33`) to the FOS. **Remove that override once the ownership transfer is executed on-chain.**

> [!CAUTION]
> Per plan step **W4**, the OPE batcher and unsafe-block-signer addresses were independently verified by four OP Labs engineers (Zach, Javier, JP, and @sbvegan); the verification is attested in the [Ink Mainnet Migration Plan](https://docs.google.com/document/d/1_U5ZdPZ81MklCnJwZRVgwMOqxgUArja1/edit) (step W4, access-controlled). **Mainnet keys are NEW — not reused from the Ink Sepolia rehearsal.**

## Simulation & Signing

```bash
cd src/tasks/eth/060-ink-set-batcher-unsafe-signer
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../justfile simulate
# then, to sign:
just --dotenv-path $(pwd)/.env --justfile ../../../justfile sign
```

## Post-execution verification

```bash
cast call 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364 "batcherHash()(bytes32)" --rpc-url mainnet
# Expected: 0x0000000000000000000000006db6161fc5662450e801398bad62dd9921216b98
cast call 0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364 "unsafeBlockSigner()(address)" --rpc-url mainnet
# Expected: 0x7b322282DF45E537E5de76D60E1432Db3cF3F8E1
```

Record the executed tx hash in the migration plan execution log (cutover steps 2 & 3).

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes and the calldata fingerprints.
