# 111-soneium-minato-system-config-owner-to-fus

Status: [DRAFT, NOT READY TO SIGN]

## Objective

Transfers ownership of the **Soneium Minato** (chainId 1946) `SystemConfigProxy` from the
Soneium SystemConfig owner Safe (`0xB278818732E5BEbb742dc4Aa0617ccd1Dec76b65`, 2-of-5) to the Sepolia
[Foundation Upgrade Safe](../../../addresses.toml#L18) (`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`), with a single
`SystemConfig.transferOwnership(address)` call. Executes ahead of the Soneium Minato migration cutover.

| Chain | Chain ID | SystemConfigProxy | `owner()` |
|---|---|---|---|
| Soneium Minato | 1946 | [`0x4Ca9608Fef202216bc21D543798ec854539bAAd3`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/sepolia/soneium-minato.toml#L52) | `0xB278818732E5BEbb742dc4Aa0617ccd1Dec76b65` → `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B` |

After this task the Foundation Upgrade Safe signs the migration's SystemConfig changes
(batcher, unsafe block signer).

> [!IMPORTANT]
> `SystemConfig` uses single-step `Ownable`: the transfer takes effect immediately and cannot be
> undone by the current owner. Verify `newOwner` before signing.

## Simulation & Signing

This is a **single-safe** task executed directly by the Soneium SystemConfig owner Safe.

```bash
cd src/tasks/sep/111-soneium-minato-system-config-owner-to-fus

just simulate-stack sep 111-soneium-minato-system-config-owner-to-fus

SKIP_DECODE_AND_PRINT=1 just sign-stack sep 111-soneium-minato-system-config-owner-to-fus
```

## Execution

For facilitators, once the Safe has collected its signatures. Run the pre-execution checks in
[VALIDATION.md](./VALIDATION.md) first. `just execute` refuses to run without `SIGNATURES`.

```bash
cd src/tasks/sep/111-soneium-minato-system-config-owner-to-fus

SIGNATURES=0x... just execute
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the signer
checklist, the calldata breakdown, the pre-execution checks, the expected state changes and
the post-execution checks.
