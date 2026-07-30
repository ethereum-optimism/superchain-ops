# 064-swell-l2pao-transfer: Transfer L2 ProxyAdmin Owner for Swell Mainnet

Status: DRAFT, NOT READY TO SIGN

## Objective

Transfer the L2 ProxyAdmin Owner of Swell Mainnet (chainId 1923) from the
current value (`0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b` — the alias of the
standard mainnet L1PAO Safe) to the L1-to-L2 alias of AltLayer's Safe
`0xa83F1334c6a8Daca576Dc14020d9d2b1b16a8Dfa`.

This task executes the L2 half of the approved governance proposal
[Maintenance Upgrade Proposal: Swell Ownership Transfer to AltLayer](https://vote.optimism.io/proposals/55157120062626112833592164692393784963640643805353175342472662837980214398880).

The transfer is executed via a deposit transaction through the L1
OptimismPortal (`0x758E0EE66102816F5C3Ec9ECc1188860fbb87812`), which is then
forwarded to the L2 ProxyAdmin predeploy
(`0x4200000000000000000000000000000000000018`). The `TransferL2PAOFromL1`
template aliases the provided unaliased owner automatically; the resulting
aliased owner that lands on L2 is:

```
0xb9501334c6a8Daca576Dc14020d9d2b1b16a9F0b
```

This task is stacked after task `063-swell-l1-ownership-transfers`. The
template asserts that the L1 ProxyAdmin owner already equals the unaliased
`newOwnerToAlias`, so task 063 must be executed first. A `stateOverrides`
entry in `config.toml` pre-applies the L1 transfer so this task can also be
simulated standalone.

To gain additional assurance that the corresponding L2 deposit transaction
works as expected, follow
[`docs/simulate-l2-ownership-transfer.md`](../../../../docs/simulate-l2-ownership-transfer.md)
and record the result in `VALIDATION.md`. Note that Swell's public RPC
(`https://swell-mainnet.alt.technology`) now requires authentication —
request an endpoint from AltLayer in `#oplabs-altlayer` if needed.

## Simulation & Signing

The L1PAO Safe is a 2-of-2 nested Safe (FoundationUpgradeSafe + SecurityCouncil),
so simulation and signing are run once per child Safe.

Simulation commands for each safe:
```bash
cd src/tasks/eth/064-swell-l2pao-transfer
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env simulate <foundation|council>
```

Signing commands for each safe:
```bash
cd src/tasks/eth/064-swell-l2pao-transfer
just --dotenv-path $(pwd)/.env sign <foundation|council>
```

## Manual Post-Execution Checks

1. Find the L2 deposit transaction on Swell Mainnet from the L1 caller (the
   standard mainnet L1PAO Safe aliased to L2 as
   `0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b`) to the L2 ProxyAdmin predeploy
   `0x4200000000000000000000000000000000000018`.
2. Verify the `OwnershipTransferred` event:
   - `previousOwner`: `0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b`
   - `newOwner`:      `0xb9501334c6a8Daca576Dc14020d9d2b1b16a9F0b`
3. Confirm the final state:
   ```bash
   cast call 0x4200000000000000000000000000000000000018 "owner()(address)" --rpc-url <swell-mainnet-rpc>
   # Expected: 0xb9501334c6a8Daca576Dc14020d9d2b1b16a9F0b
   ```
   (Or check via the explorer: https://explorer.swellnetwork.io)
4. AltLayer confirms receipt of ownership in `#oplabs-altlayer`.
