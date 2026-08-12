# 104-ink-sepolia-system-config-owner-to-fus

Status: READY TO SIGN

## Objective

Transfers ownership of the **Ink Sepolia** (chainId 763373) `SystemConfigProxy` from the **Foundation Operations Safe (FOS)** to the **Foundation Upgrade Safe (FUS)**, as a follow-up to the completed Gelato → OP Enterprise rollup-operator migration ([solutions#973](https://github.com/ethereum-optimism/solutions/issues/973)).

- **Current owner** (signer): [`0x837DE453AD5F21E89771e3c06239d8236c0EFd5E`](https://sepolia.etherscan.io/address/0x837DE453AD5F21E89771e3c06239d8236c0EFd5E) — **Foundation Operations Safe** (2-of-N). This Safe received SystemConfig ownership from the Gelato Safe during the migration cutover.
- **New owner**: [`0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`](https://sepolia.etherscan.io/address/0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B) — **Foundation Upgrade Safe**
- **Target**: `SystemConfigProxy` [`0x05C993e60179f28bF649a2Bb5b00b5F4283bD525`](https://sepolia.etherscan.io/address/0x05C993e60179f28bF649a2Bb5b00b5F4283bD525) (resolved from the superchain-registry)

> [!IMPORTANT]
> **Policy going forward: the FUS is the standard owner for all `SystemConfig` proxies.** New chains and migrations should set (or transfer) `SystemConfig` ownership to the FUS, matching the Foundation-owned chains where the FUS already holds this role (e.g. OP Mainnet). This task brings Ink Sepolia in line with that policy; [eth/065](../../eth/065-ink-system-config-owner-to-fus/README.md) does the same for Ink Mainnet.

> [!CAUTION]
> Ownership transfers are **irreversible** (only the new owner could transfer it back). Verify the `newOwner` address against `src/addresses.toml` (`FoundationUpgradeSafe`, `[sep]`) with **≥3 OP Labs engineers** before signing.

## Simulation & Signing

Simulation commands:
```bash
cd src/
just simulate-stack sep 104-ink-sepolia-system-config-owner-to-fus
```

Signing commands:
```bash
cd src/tasks/sep/104-ink-sepolia-system-config-owner-to-fus
SKIP_DECODE_AND_PRINT=1 just --dotenv-path $(pwd)/.env sign
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes and the calldata fingerprint.
