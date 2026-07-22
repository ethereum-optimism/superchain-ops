# 055-swell-l1-ownership-transfers: Transfer L1 owners for Swell (ProxyAdmin + DisputeGameFactory)

Status: [DRAFT, NOT READY TO SIGN]()

## Objective

Transfer L1 ownership of the Swell chain (chainId 1923) from the standard OP
Mainnet L1PAO Safe (`0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`) to AltLayer's
new owner Safe `0xa83F1334c6a8Daca576Dc14020d9d2b1b16a8Dfa`.

Swell is winding down and AltLayer is taking over to finish the wind-down, so
the upgrade keys are returned to AltLayer's Safe.

Contracts moved by this task (`TransferOwners` template):

- ProxyAdmin (`0x4C4710a4Ec3F514A492CC6460818C4A6A6269dd6`) — `transferOwnership`
- DisputeGameFactoryProxy (`0x87690676786cDc8cCA75A472e483AF7C8F2f0F57`) — `transferOwnership`

The chain's DelayedWETH is v1.5.0 (post-U16) and not ownable, so the template
skips it at build time.

Swell has been removed from the public superchain-registry
(ethereum-optimism/superchain-registry#1247); its addresses are loaded via
`fallbackAddressesJsonPath` from `addresses.json` and were verified with
`op-fetcher`. It reuses OP Mainnet's standard SuperchainConfig
(`0x95703e0982140D16f8ebA6d158FccEde42f04a4C`).

This task transfers L1 ownership only (ProxyAdmin + DisputeGameFactory); the
Swell L2 ProxyAdmin owner is intentionally left unchanged.

This task is the first of the broader handover effort (execution order:
Swell → Dust → Unichain) and requires Optimism Governance approval before
signing.

## Simulation & Signing

The L1PAO Safe is a 2-of-2 nested Safe (FoundationUpgradeSafe + SecurityCouncil),
so simulation and signing are run once per child Safe.

Simulation commands for each safe:
```bash
cd src/tasks/eth/055-swell-l1-ownership-transfers
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate <foundation|council>
```

Signing commands for each safe:
```bash
cd src/tasks/eth/055-swell-l1-ownership-transfers
just --dotenv-path $(pwd)/.env sign <foundation|council>
```
