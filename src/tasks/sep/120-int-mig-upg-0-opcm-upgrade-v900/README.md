# 120-int-mig-upg-0-opcm-upgrade-v900

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x62189e057776d05fab11a99f6ba2a6d732737b702077ecbdb3dad323ff52c6dc)

## Objective

Upgrades both chains of the int-mig-upg-0 devnet from `op-contracts/v8` (`lastUsedOPCMVersion` 8.0.1) to
`op-contracts/v9` from the shared devnet ProxyAdminOwner Safe
[`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`](https://sepolia.etherscan.io/address/0xe934Dc97E347C6aCef74364B50125bb8689c40ff)
(1-of-1). Calls `OPCMv2.upgradeSuperchain` once on the devnet's own SuperchainConfig
[`0x9067907a5131cB2b61De646b9c16d132a771dF5D`](https://sepolia.etherscan.io/address/0x9067907a5131cB2b61De646b9c16d132a771dF5D),
then `OPCMv2.upgrade` per chain.

This is the first half of the v9 rollout. It must execute before
[121-int-mig-upg-0-opcm-migrate-v900](../121-int-mig-upg-0-opcm-migrate-v900/README.md), because `migrate`
requires every chain to be on the v9 OPCM.

| Chain | Chain ID | Respected game type | SystemConfigProxy |
|---|---|---|---|
| int-mig-upg-0-0 | 420120270 | SUPER_PERMISSIONED (5), unchanged | [`0xC23Aa06564BF0e3213026cC43926d2fa9D26459c`](https://sepolia.etherscan.io/address/0xC23Aa06564BF0e3213026cC43926d2fa9D26459c) |
| int-mig-upg-0-1 | 420120271 | SUPER_PERMISSIONED (5), unchanged | [`0x2808032528881b485f4c0C46006E7344E011c97a`](https://sepolia.etherscan.io/address/0x2808032528881b485f4c0C46006E7344E011c97a) |

State before this task (read on-chain 2026-10-27): SystemConfig 4.0.0. Each `DisputeGameFactory` registers
only SUPER_PERMISSIONED (5); SUPER_CANNON_KONA (9) was never registered, so the upgrade leaves it disabled and
`cannonKonaPrestate` is an unused non-zero placeholder. Both `AnchorStateRegistry`s anchor on the same super
root, which the upgrade carries forward.

## ETHLockbox

netchef deployed an `EthLockboxProxy` per chain but never attached it: `OptimismPortal.ethLockbox()` is zero
and the `ETH_LOCKBOX` feature is off on both SystemConfigs. The v9 OPCM deploys a lockbox in that case and
reverts (`0x391074c9`, `ETHLockbox`) unless given the `PermittedProxyDeployment=ETHLockbox` instruction.
`permitEthLockboxDeployment` in [config.toml](./config.toml) opts both chains in. This config key was
added to `OPCMUpgradeV900` for this task; the template previously assumed every v8 chain already has a
lockbox.

## Expected validation errors

`OVERRIDES-L1PAOMULTISIG,SYSCON-130,SCKDG-SHAPE,SCKDG-10` for both chains:

- `OVERRIDES-L1PAOMULTISIG`: the devnet PAO Safe is not the standard L1PAO.
- `SYSCON-130`: the chains use the devnet's own SuperchainConfig, not the one the OPCM was deployed against.
- `SCKDG-SHAPE`, `SCKDG-10`: SUPER_CANNON_KONA is not registered. The migrate task registers it on the shared
  DisputeGameFactory.

## Addresses

int-mig-upg-0 is not in the superchain-registry, so the task reads its addresses from
[addresses.json](./addresses.json) via `fallbackAddressesJsonPath`. Every address was taken from
`devnets-private` `dev/int-mig-upg-0/op-deployer/state.json` and cross-checked on-chain against `SystemConfig`
and `OptimismPortal2` getters.

## Execution

Executed with v9 OPCM `0xe09c417496c786abffefa676da9e11aab2c32ea9` (9.0.5), not a released
`op-contracts/v9.0.0`; both SystemConfigs now report `lastUsedOPCMVersion` 9.0.5. Sepolia needed about 13.6M
gas, above forge's local estimate (about 5.1M), so execution used `--gas-estimate-multiplier 300`; the first
attempt at forge's default ran out of gas and reverted with `GS013`.

## Simulation

```
cd src/tasks/sep/120-int-mig-upg-0-opcm-upgrade-v900
SIMULATE_WITHOUT_LEDGER=1 just --justfile ../../../justfile simulate
```
