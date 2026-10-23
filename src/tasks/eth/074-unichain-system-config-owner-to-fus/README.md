# 074-unichain-system-config-owner-to-fus

Status: [DRAFT, NOT READY TO SIGN]

## Objective

Transfers ownership of the **Unichain** (chainId 130) `SystemConfigProxy` from the
Unichain SystemConfig owner Safe (`0x9245d5D10AA8a842B31530De71EA86c0760Ca1b1`, 3-of-5) to the Mainnet
[Foundation Upgrade Safe](../../../addresses.toml#L6) (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`), with a single
`SystemConfig.transferOwnership(address)` call. Planned for the second half of October, ahead of the Unichain Mainnet migration cutover.

| Chain | Chain ID | SystemConfigProxy | `owner()` |
|---|---|---|---|
| Unichain | 130 | [`0xc407398d063f942feBbcC6F80a156b47F3f1BDA6`](https://github.com/ethereum-optimism/superchain-registry/blob/9dce5d25fb6a3d4fb372ce92dc8eed3a4a17175c/superchain/configs/mainnet/unichain.toml#L51) | `0x9245d5D10AA8a842B31530De71EA86c0760Ca1b1` → `0x847B5c174615B1B7fDF770882256e2D3E95b9D92` |

After this task the Foundation Upgrade Safe signs the migration's SystemConfig changes
(batcher, unsafe block signer).

> [!IMPORTANT]
> `SystemConfig` uses single-step `Ownable`: the transfer takes effect immediately and cannot be
> undone by the current owner. Verify `newOwner` before signing.

## Simulation & Signing

This is a **single-safe** task executed directly by the Unichain SystemConfig owner Safe.

```bash
cd src/tasks/eth/074-unichain-system-config-owner-to-fus

just simulate-stack eth 074-unichain-system-config-owner-to-fus

SKIP_DECODE_AND_PRINT=1 just sign-stack eth 074-unichain-system-config-owner-to-fus
```

## Execution

For facilitators, once the Safe has collected its signatures. Run the pre-execution checks in
[VALIDATION.md](./VALIDATION.md) first. `just execute` refuses to run without `SIGNATURES`.

```bash
cd src/tasks/eth/074-unichain-system-config-owner-to-fus

SIGNATURES=0x... just execute
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes, the signer
checklist, the calldata breakdown, the pre-execution checks, the expected state changes and
the post-execution checks.
