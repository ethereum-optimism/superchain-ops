# 065-ink-system-config-owner-to-fus

Status: READY TO SIGN

## Objective

Transfers ownership of the **Ink Mainnet** (chainId 57073) `SystemConfigProxy` from the **Foundation Operations Safe (FOS)** to the **Foundation Upgrade Safe (FUS)**, as a follow-up to the completed Gelato → OP Enterprise rollup-operator migration ([solutions#973](https://github.com/ethereum-optimism/solutions/issues/973)).

- **Current owner** (signer): [`0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`](https://etherscan.io/address/0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A) — **Foundation Operations Safe** (5-of-7)
- **New owner**: [`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`](https://etherscan.io/address/0x847B5c174615B1B7fDF770882256e2D3E95b9D92) — **Foundation Upgrade Safe** (5-of-7)
- **Target**: `SystemConfigProxy` [`0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364`](https://etherscan.io/address/0x62C0a111929fA32ceC2F76aDba54C16aFb6E8364) (resolved from the superchain-registry)

> [!IMPORTANT]
> **Policy going forward: the FUS is the standard owner for all `SystemConfig` proxies.** New chains and migrations should set (or transfer) `SystemConfig` ownership to the FUS, matching the Foundation-owned chains where the FUS already holds this role (e.g. OP Mainnet). This task brings Ink Mainnet in line with that policy; [sep/104](../../sep/104-ink-sepolia-system-config-owner-to-fus/README.md) does the same for Ink Sepolia.

> [!CAUTION]
> Ownership transfers are **irreversible** (only the new owner could transfer it back). Verify the `newOwner` address against `src/addresses.toml` (`FoundationUpgradeSafe`, `[eth]`) with **≥3 OP Labs engineers** before signing.

## Simulation & Signing

Simulation commands:
```bash
cd src/
just simulate-stack eth 065-ink-system-config-owner-to-fus
```

Signing commands:
```bash
cd src/tasks/eth/065-ink-system-config-owner-to-fus
SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env sign
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes and the calldata fingerprint.
