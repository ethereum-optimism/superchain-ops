# 065-ink-system-config-owner-to-fus

Status: [READY TO SIGN]

## Objective

Transfers ownership of the **Ink Mainnet** (chainId 57073) `SystemConfigProxy` from the **Foundation Operations Safe (FOS)** to the **Foundation Upgrade Safe (FUS)**, as a follow-up to the completed Gelato > OP Enterprise migration.

- **Current owner** (signer): [`0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`](https://github.com/ethereum-optimism/superchain-ops/blob/ecef506a2033a8d0c62a41af7f26892a27859338/src/addresses.toml#L10) — **Foundation Operations Safe**. This Safe received SystemConfig ownership from the Gelato Safe with the migration cutover
- **New owner**: [`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`](https://github.com/ethereum-optimism/superchain-ops/blob/ecef506a2033a8d0c62a41af7f26892a27859338/src/addresses.toml#L6) — **Foundation Upgrade Safe**
- **Target**: `SystemConfigProxy` [`0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364`](https://github.com/ethereum-optimism/superchain-registry/blob/bb104b09fcd60fc01c8f8daf0f534aee88ff26de/superchain/configs/mainnet/ink.toml#L51)

> [!IMPORTANT]
> Ownership transfers are **irreversible**, verify the `newOwner` address before signing.

## Simulation & Signing

Simulation commands:
```bash
cd src/
just simulate-stack eth 065-ink-system-config-owner-to-fus
```

Signing commands:
```bash
cd src/tasks/eth/065-ink-system-config-owner-to-fus
SKIP_DECODE_AND_PRINT=1 just sign-stack eth 065-ink-system-config-owner-to-fus
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes and the calldata fingerprint.
