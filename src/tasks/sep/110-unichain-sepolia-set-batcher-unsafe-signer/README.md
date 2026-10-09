# 110-unichain-sepolia-set-batcher-unsafe-signer

Status: [READY TO SIGN]

## Objective

Unichain Sepolia migration, cutover steps 2 and 3: registers the OP Enterprise batcher and unsafe
block signer on the **Unichain Sepolia** (chainId 1301) `SystemConfigProxy` with `setBatcherHash(bytes32)` and
`setUnsafeBlockSigner(address)`, executed by the SystemConfig owner, the
[FoundationUpgradeSafe](../../../addresses.toml#L18) (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`).

| Chain | Chain ID | SystemConfigProxy | Field | Change |
|---|---|---|---|---|
| Unichain Sepolia | 1301 | [`0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/sepolia/unichain.toml#L52) | `batcherHash()` | `0x4AB3387810eF500bfe05a49dc53A44C222cbab3e` → `0xf10b9B33Ae8da0581E08AB7cA9eCE394301843A9` |
| | | | `unsafeBlockSigner()` | `0x565B71025Ab4de80AcA33c62E51439af56301493` → `0x23449Eae2BC890db1649AA3071b0e6A9Aa97433b` |

## Simulation & Signing

This is a **single-safe** task executed directly by the FoundationUpgradeSafe.

```bash
cd src/tasks/sep/110-unichain-sepolia-set-batcher-unsafe-signer

just simulate-stack sep 110-unichain-sepolia-set-batcher-unsafe-signer

SKIP_DECODE_AND_PRINT=1 just sign-stack sep 110-unichain-sepolia-set-batcher-unsafe-signer
```

## Execution

For facilitators, once the Safe has collected its signatures. Run the pre-execution checks in
[VALIDATION.md](./VALIDATION.md) first. `just execute` refuses to run without `SIGNATURES`.

```bash
cd src/tasks/sep/110-unichain-sepolia-set-batcher-unsafe-signer

SIGNATURES=0x... just execute
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the signer
checklist, the calldata breakdown, the pre-execution checks, the expected state changes and
the post-execution checks.
