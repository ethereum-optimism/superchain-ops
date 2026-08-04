# 064-swell-l2pao-transfer: Transfer L2 ProxyAdmin Owner for Swell Mainnet

Status: DRAFT, NOT READY TO SIGN

## Objective

Transfer the L2 ProxyAdmin Owner of Swell Mainnet (chainId 1923) to the
L1-to-L2 alias of AltLayer's Safe, executing the L2 half of the approved
[Maintenance Upgrade Proposal: Swell Ownership Transfer to AltLayer](https://vote.optimism.io/proposals/55157120062626112833592164692393784963640643805353175342472662837980214398880).

| L2 ProxyAdmin `0x4200000000000000000000000000000000000018` | Address |
|---|---|
| Current owner | `0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b` (aliased L1PAO) |
| New owner | `0xb9501334c6a8Daca576Dc14020d9d2b1b16a9F0b` (aliased AltLayer Safe) |

The change is delivered as a deposit transaction through the L1 OptimismPortal
`0x758E0EE66102816F5C3Ec9ECc1188860fbb87812`.

> [!IMPORTANT]
> **Execute `063-swell-l1-ownership-transfers` first.** This task requires the
> L1 ProxyAdmin owner to already be AltLayer's Safe.

## Simulation & Signing

The root safe is the 2-of-2 nested L1PAO, so run each command once per child
safe (`foundation`, then `council`).

```bash
cd src/tasks/eth/064-swell-l2pao-transfer
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../justfile simulate <foundation|council>
# then, to sign:
just --dotenv-path $(pwd)/.env --justfile ../../../justfile sign <foundation|council>
```

> [!CAUTION]
> The Safe nonces are pinned in `config.toml`. Re-verify them against live
> on-chain values before signing — see [VALIDATION.md](./VALIDATION.md).

For extra assurance on the L2 deposit before signing, follow
[`docs/simulate-l2-ownership-transfer.md`](../../../../docs/simulate-l2-ownership-transfer.md)
and record the result in `VALIDATION.md`.

## Post-execution verification

The L2 change lands only once the deposit is relayed, so it cannot be confirmed
from L1. On Swell Mainnet:

1. Find the deposit transaction from `0x6B1BAE59D09fCcbdDB6C6cceb07B7279367C4E3b`
   to the L2 ProxyAdmin predeploy `0x4200000000000000000000000000000000000018`.
2. Confirm it emitted `OwnershipTransferred` with `newOwner`
   `0xb9501334c6a8Daca576Dc14020d9d2b1b16a9F0b`.
3. Confirm the final owner:
   ```bash
   cast call 0x4200000000000000000000000000000000000018 "owner()(address)" --rpc-url <swell-mainnet-rpc>
   # Expected: 0xb9501334c6a8Daca576Dc14020d9d2b1b16a9F0b
   ```
4. Ask AltLayer to confirm receipt of ownership in `#oplabs-altlayer`.

Swell's public RPC (`https://swell-mainnet.alt.technology`) requires
authentication — request an endpoint from AltLayer, or use
https://explorer.swellnetwork.io.

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes and
state changes. Task inputs and the rationale for the address fallback, alias
derivation and state overrides are documented in [config.toml](./config.toml).
