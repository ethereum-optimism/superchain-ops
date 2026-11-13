# 125-sepolia-devnet-4-5-opcm-migrate-v900

Status: [EXECUTED](https://sepolia.etherscan.io/tx/0x0d52a31e01af58767efb790efe6815f68b46ccb53008cd35c85df4e4d7729c70)

## Objective

Migrates sepolia-devnet-4 and sepolia-devnet-5 (the OP Labs interop staging pair) onto shared dispute
contracts with `OPCMv2.migrate`, from the staging ProxyAdminOwner Safe
[`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`](https://sepolia.etherscan.io/address/0xe934Dc97E347C6aCef74364B50125bb8689c40ff)
(1-of-1), through the `op-contracts/v9.0.0`
[OPCM `0x160f0fe4dc1b3f4026687e8dd4b7f800879939cc`](https://github.com/ethereum-optimism/superchain-registry/blob/41553edca76a4d67d7be0b57f857ffc978295153/validation/standard/standard-versions-sepolia.toml)
(version 9.0.3) that upgraded both chains in
[122-U21-sepolia-devnet-4-5-opcm-upgrade-v900](../122-U21-sepolia-devnet-4-5-opcm-upgrade-v900/README.md).
A single delegatecall:

- deploys a shared ETHLockbox, DisputeGameFactory and AnchorStateRegistry;
- moves each chain's ETHLockbox balance into the shared lockbox;
- points both portals at the shared dispute contracts and enables INTEROP on both chains;
- registers SUPER_PERMISSIONED (5) and SUPER_CANNON_KONA (9) on the shared DisputeGameFactory.

Migration is one-way and invalidates all prior withdrawal proofs.

| Chain | Chain ID | SystemConfigProxy |
|---|---|---|
| sepolia-devnet-4 | 420130019 | [`0xa15b902f86a60cafe43034eee86a5c19db931e59`](https://sepolia.etherscan.io/address/0xa15b902f86a60cafe43034eee86a5c19db931e59) |
| sepolia-devnet-5 | 420130020 | [`0x1B68cDfDD4aE9985F21033169735e5C4A6200f2C`](https://sepolia.etherscan.io/address/0x1B68cDfDD4aE9985F21033169735e5C4A6200f2C) |

## Simulation & Signing

This is a **single-safe** task: the staging ProxyAdminOwner is a 1-of-1 Safe, so no child-safe argument is
needed.

```bash
cd src/tasks/sep/125-sepolia-devnet-4-5-opcm-migrate-v900

just simulate-stack sep 125-sepolia-devnet-4-5-opcm-migrate-v900

USE_KEYSTORE=1 SKIP_DECODE_AND_PRINT=1 just sign-stack sep 125-sepolia-devnet-4-5-opcm-migrate-v900
```

## Validation

See [VALIDATION.md](./VALIDATION.md) for the expected domain/message hash, the signer checklist, the
calldata breakdown, the expected state changes and the post-execution checks.
