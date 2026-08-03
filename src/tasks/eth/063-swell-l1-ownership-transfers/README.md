# 063-swell-l1-ownership-transfers: Transfer L1 owners for Swell Mainnet (ProxyAdmin + DisputeGameFactory)

Status: DRAFT, NOT READY TO SIGN

## Objective

Transfer L1 ownership of the Swell Mainnet chain (chainId 1923) from the
standard mainnet L1PAO Safe (`0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A`) to
AltLayer's Safe `0xa83F1334c6a8Daca576Dc14020d9d2b1b16a8Dfa`.

Swell is winding down and AltLayer (its RaaS provider) is the operator
completing the wind-down. This task executes the approved governance proposal
[Maintenance Upgrade Proposal: Swell Ownership Transfer to AltLayer](https://vote.optimism.io/proposals/55157120062626112833592164692393784963640643805353175342472662837980214398880).
AltLayer confirmed the receiving Safe address in `#oplabs-altlayer` (a 1-of-1
Safe whose sole member is `0x6967D304E9b7E26b5eb3f5A1FD1239DaAD3215E6`).

Contracts moved by this task (`TransferOwners` template):

- ProxyAdmin (`0x4C4710a4Ec3F514A492CC6460818C4A6A6269dd6`) — `transferOwnership`
- DisputeGameFactoryProxy (`0x87690676786cDc8cCA75A472e483AF7C8F2f0F57`) — `transferOwnership`

The chain's DelayedWETH (`0xdD525E7E8fA35345D30e88018c9925F3C2876107`) is
skipped: the fallback `addresses.json` intentionally omits the
PermissionedWETH/PermissionlessWETH keys, so the template performs no DWETH
transfer. That is safe because the contract is v1.5.0 (post-U16) and not
ownable — an `owner()` call returns no data on-chain — so there is no ownership to transfer.

Swell was removed from the public superchain-registry ("Remove Arena-Z and
Swell (sunsetting chains)"), so its addresses are loaded via
`fallbackAddressesJsonPath` from `addresses.json`. It uses the standard
OP Mainnet SuperchainConfig (`0x95703e0982140D16f8ebA6d158FccEde42f04a4C`).

The L2 ProxyAdmin transfer is the follow-up task `064-swell-l2pao-transfer`,
which must be executed after this one (its template asserts the L1 ProxyAdmin
owner has already been moved).

## Simulation & Signing

The L1PAO Safe is a 2-of-2 nested Safe (FoundationUpgradeSafe + SecurityCouncil),
so simulation and signing are run once per child Safe.

Simulation commands for each safe:
```bash
cd src/tasks/eth/063-swell-l1-ownership-transfers
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate <foundation|council>
```

Signing commands for each safe:
```bash
cd src/tasks/eth/063-swell-l1-ownership-transfers
just --dotenv-path $(pwd)/.env sign <foundation|council>
```
