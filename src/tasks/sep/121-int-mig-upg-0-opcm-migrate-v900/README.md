# 121-int-mig-upg-0-opcm-migrate-v900

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0xee5c8bd191d877c1d2745e44da7bc8684f84f87227e8ef42a174b1ed7417e15c)

## Objective

Migrates both chains of the int-mig-upg-0 devnet onto shared dispute contracts with `OPCMv2.migrate`, from the
shared devnet ProxyAdminOwner Safe
[`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`](https://sepolia.etherscan.io/address/0xe934Dc97E347C6aCef74364B50125bb8689c40ff)
(1-of-1). A single delegatecall:

- deploys a shared ETHLockbox, DisputeGameFactory and AnchorStateRegistry;
- moves each portal's and lockbox's ETH into the shared lockbox;
- points both portals at the shared dispute contracts and enables INTEROP on both chains;
- registers SUPER_PERMISSIONED (5) and SUPER_CANNON_KONA (9) on the shared DisputeGameFactory.

Migration is one-way and invalidates all prior withdrawal proofs.

Depends on [120-int-mig-upg-0-opcm-upgrade-v900](../120-int-mig-upg-0-opcm-upgrade-v900/README.md):
`migrate` requires every chain to be on the v9 OPCM.

| Chain | Chain ID | SystemConfigProxy |
|---|---|---|
| int-mig-upg-0-0 | 420120270 | [`0xC23Aa06564BF0e3213026cC43926d2fa9D26459c`](https://sepolia.etherscan.io/address/0xC23Aa06564BF0e3213026cC43926d2fa9D26459c) |
| int-mig-upg-0-1 | 420120271 | [`0x2808032528881b485f4c0C46006E7344E011c97a`](https://sepolia.etherscan.io/address/0x2808032528881b485f4c0C46006E7344E011c97a) |

The chains share SuperchainConfig `0x9067…df5d`, a 302400s dispute game finality delay and a 302400s
DelayedWETH delay, which `migrate` requires.

## Inputs

| Input | Value | Notes |
|---|---|---|
| `proposer` | `0xee85f3967ee999fc7db2a50beb798bd2f8daee3f` | Chain 0's proposer. The shared game takes one proposer, so chain 1's op-proposer (`0x4ec8…5d7a`) must be stopped or repointed in the devnet inventory after migration. |
| `startingAnchorRoot` | `0x871160c9…681d` @ `1792826698` | The super root both chains' `AnchorStateRegistry`s already anchor on. |
| `startingRespectedGameType` | 5 (SUPER_PERMISSIONED) | Unchanged. |
| `superCannonKonaInitBond` | 0.08 ETH | |
| `cannonKonaPrestate` | `0x03723b53…b041` | Kona interop prestate for both chains as one cluster, built with `netchef fault-proofs generate-prestates --prestate-type konaInterop` at `kona-node/v1.9.0` using [infrastructure-services#1430](https://github.com/ethereum-optimism/infrastructure-services/pull/1430); preimage in `gs://oplabs-network-data/proofs/kona/cannon/`. |

## Execution

Executed with the same v9 OPCM as task 120 (`0xe09c417496c786abffefa676da9e11aab2c32ea9`, 9.0.5), not a
released `op-contracts/v9.0.0`. Expected validation errors: `MIG-SLOCKBOX-40,MIG-CHAIN-0-130,MIG-CHAIN-1-130`
(shared lockbox and SystemConfigs on the devnet's own SuperchainConfig) and
`OVERRIDES-L1PAOMULTISIG,SYSCON-130` per chain.

Sepolia needed about 17.0M gas, above forge's local estimate (about 4.2M), so execution used
`--gas-estimate-multiplier 500`.

Resulting shared contracts:

| Contract | Address |
|---|---|
| DisputeGameFactory | [`0xe655570C60aF4A9a1abB5dF4a16d8F6849Da49e4`](https://sepolia.etherscan.io/address/0xe655570C60aF4A9a1abB5dF4a16d8F6849Da49e4) |
| AnchorStateRegistry | [`0x7E38e439BD6C59d0994fF036fB6b1e625a5acA41`](https://sepolia.etherscan.io/address/0x7E38e439BD6C59d0994fF036fB6b1e625a5acA41) |
| ETHLockbox | [`0x8135bb82E6eE1bA61ACCa72BB20d1FE6d4172500`](https://sepolia.etherscan.io/address/0x8135bb82E6eE1bA61ACCa72BB20d1FE6d4172500) |

Devnet follow-up in `devnets-private`: one super proposer for the set, and challenger/dispute-mon pointed at
the shared DisputeGameFactory.

## Addresses

Reads the same [addresses.json](../120-int-mig-upg-0-opcm-upgrade-v900/addresses.json) as task 120 via
`fallbackAddressesJsonPath`. The template reads each chain's pre-migration DisputeGameFactory,
AnchorStateRegistry, ETHLockbox and DelayedWETH from the portal and SystemConfig at setup.

## Simulation

```
cd src
SIMULATE_WITHOUT_LEDGER=1 just simulate-stack sep 121-int-mig-upg-0-opcm-migrate-v900
```
