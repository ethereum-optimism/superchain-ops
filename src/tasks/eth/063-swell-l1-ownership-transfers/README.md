# 063-swell-l1-ownership-transfers: Transfer L1 owners for Swell Mainnet (ProxyAdmin + DisputeGameFactory)

Status: DRAFT, NOT READY TO SIGN

## Objective

Transfer L1 ownership of Swell Mainnet (chainId 1923) to AltLayer's Safe
`0xa83F1334c6a8Daca576Dc14020d9d2b1b16a8Dfa`, executing the L1 half of the
approved [Maintenance Upgrade Proposal: Swell Ownership Transfer to AltLayer](https://vote.optimism.io/proposals/55157120062626112833592164692393784963640643805353175342472662837980214398880).
Swell is winding down and AltLayer, its RaaS provider, is completing the
wind-down.

| Contract | Current owner | New owner |
|---|---|---|
| ProxyAdmin `0x4C4710a4Ec3F514A492CC6460818C4A6A6269dd6` | `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (L1PAO) | `0xa83F1334c6a8Daca576Dc14020d9d2b1b16a8Dfa` |
| DisputeGameFactoryProxy `0x87690676786cDc8cCA75A472e483AF7C8F2f0F57` | `0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A` (L1PAO) | `0xa83F1334c6a8Daca576Dc14020d9d2b1b16a8Dfa` |

The follow-up L2 ProxyAdmin transfer is `064-swell-l2pao-transfer`, which must
be executed after this task.

## Simulation & Signing

The root safe is the 2-of-2 nested L1PAO, so run each command once per child
safe (`foundation`, then `council`).

```bash
cd src/tasks/eth/063-swell-l1-ownership-transfers
SIMULATE_WITHOUT_LEDGER=1 just --dotenv-path $(pwd)/.env --justfile ../../../justfile simulate <foundation|council>
# then, to sign:
just --dotenv-path $(pwd)/.env --justfile ../../../justfile sign <foundation|council>
```

> [!CAUTION]
> The pinned Safe nonces assume `eth/061` and `eth/062` execute first.
> Re-verify the live nonces before signing — see [VALIDATION.md](./VALIDATION.md).

## Post-execution verification

```bash
cast call 0x4C4710a4Ec3F514A492CC6460818C4A6A6269dd6 "owner()(address)" --rpc-url mainnet
cast call 0x87690676786cDc8cCA75A472e483AF7C8F2f0F57 "owner()(address)" --rpc-url mainnet
# Both expected: 0xa83F1334c6a8Daca576Dc14020d9d2b1b16a8Dfa
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hashes and
state changes. Task inputs and the rationale for the address fallback and nonce
overrides are documented in [config.toml](./config.toml).
