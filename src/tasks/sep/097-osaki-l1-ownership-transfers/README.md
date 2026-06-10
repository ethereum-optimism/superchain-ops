# 097-osaki-l1-ownership-transfers: Transfer L1 owners for Osaki Sepolia (ProxyAdmin + DisputeGameFactory)

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0xec5c2801dab2f9030df813116835799462d0695de793e971f08fc97c7f8eff3d)

## Objective

Transfer L1 ownership of the Osaki Sepolia chain (chainId 9111973) from the
standard Sepolia L1PAO Safe (`0x1Eb2fFc903729a0F03966B917003800b145F56E2`) to
the new owner Safe `0xFB0F8937A0d6999C67E8a01310eBf7fe1859205F`.

Contracts moved by this task (`TransferOwners` template):

- ProxyAdmin (`0x2f3369b81c2b6e1e80a98f7de44be8cfff314db0`) — `transferOwnership`
- DisputeGameFactoryProxy (`0xfa695fc017d374cfa2b1dcbd3e4617a9c3891dda`) — `transferOwnership`

The chain's DelayedWETH is v1.5.0 (post-U16) and not ownable, so the template
skips it at build time.

Osaki is a new devnet that is not in the public superchain-registry; its
addresses are loaded via `fallbackAddressesJsonPath` from `addresses.json`. It
reuses OP Sepolia's standard SuperchainConfig
(`0xC2Be75506d5724086DEB7245bd260Cc9753911Be`).

The L2 ProxyAdmin transfer is the follow-up task `098-osaki-l2pao-transfer`,
which must be executed after this one (its template asserts the L1 ProxyAdmin
owner has already been moved).

## Simulation & Signing

The L1PAO Safe is a 2-of-2 nested Safe (FoundationUpgradeSafe + SecurityCouncil),
so simulation and signing are run once per child Safe.

Simulation commands for each safe:
```bash
cd src/tasks/sep/097-osaki-l1-ownership-transfers
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate <foundation|council>
```

Signing commands for each safe:
```bash
cd src/tasks/sep/097-osaki-l1-ownership-transfers
just --dotenv-path $(pwd)/.env sign <foundation|council>
```
