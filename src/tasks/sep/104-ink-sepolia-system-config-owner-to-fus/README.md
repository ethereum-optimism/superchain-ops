# 104-ink-sepolia-system-config-owner-to-fus

Status: [READY TO SIGN]

## Objective

Transfers ownership of the **Ink Sepolia** (chainId 763373) `SystemConfigProxy` from the **Foundation Operations Safe (FOS)** to the **Foundation Upgrade Safe (FUS)**, as a follow-up to the completed Gelato > OP Enterprise migration.

- **Current owner** (signer): [`0x837DE453AD5F21E89771e3c06239d8236c0EFd5E`](https://github.com/ethereum-optimism/superchain-ops/blob/ecef506a2033a8d0c62a41af7f26892a27859338/src/addresses.toml#L21) — **Foundation Operations Safe**. This Safe received SystemConfig ownership from the Gelato Safe with the migration cutover
- **New owner**: [`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`](https://github.com/ethereum-optimism/superchain-ops/blob/ecef506a2033a8d0c62a41af7f26892a27859338/src/addresses.toml#L18) — **Foundation Upgrade Safe**
- **Target**: `SystemConfigProxy` [`0x05C993e60179f28bF649a2Bb5b00b5F4283bD525`](https://github.com/ethereum-optimism/superchain-registry/blob/bb104b09fcd60fc01c8f8daf0f534aee88ff26de/superchain/configs/sepolia/ink.toml#L52)

> [!IMPORTANT]
> Ownership transfers are **irreversible**, verify the `newOwner` address before signing.

## Simulation & Signing

Simulation commands:
```bash
cd src/
just simulate-stack sep 104-ink-sepolia-system-config-owner-to-fus
```

Signing commands:
```bash
cd src/tasks/sep/104-ink-sepolia-system-config-owner-to-fus
SKIP_DECODE_AND_PRINT=1 just sign-stack sep 104-ink-sepolia-system-config-owner-to-fus
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes and the calldata fingerprint.
