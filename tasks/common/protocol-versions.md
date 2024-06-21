# `ProtocolVersions` State Changes

The `ProtocolVersions` contract signals the _recommended_ and _required_ protocol versions to nodes.
Halting on incompatible protocol versions is currently opt-in.

It has two functions `setRecommended` and `setRequired` to set both versions individually.
We usually aim to set the _recommended_ version *2 weeks* before a protocol upgrade and the _required_
version *2 days* before.

## Deployments

* Mainnet: [`0x8062AbC286f5e7D9428a0Ccb9AbD71e50d93b935`](https://github.com/ethereum-optimism/superchain-registry/blob/67128af695e57d6e32a740f8587aca4e0bded888/superchain/configs/mainnet/superchain.yaml#L7)
* Sepolia: [`0x79ADD5713B383DAa0a138d3C4780C7A1804a8090`](https://github.com/ethereum-optimism/superchain-registry/blob/67128af695e57d6e32a740f8587aca4e0bded888/superchain/configs/sepolia/superchain.yaml#L7)

## Storage Slots

It has two storage slots:

* `0xe314dfc40f0025322aacc0ba8ef420b62fb3b702cf01e0cdf3d829117ac2ff1a` - recommended version
* `0x4aaefe95bd84fd3f32700cf3b7566bc944b73138e41958b5785826df2aecace0` - required version

The correctness of these keys can be verified with `chisel --use 0.8.15  --evm-version london`.
Just start it up and enter the slot definitions as found in the contract source code.
```
➜ bytes32(uint256(keccak256("protocolversion.recommended")) - 1)
Type: bytes32
└ Data: 0xe314dfc40f0025322aacc0ba8ef420b62fb3b702cf01e0cdf3d829117ac2ff1a
➜ bytes32(uint256(keccak256("protocolversion.required")) - 1)
Type: bytes32
└ Data: 0x4aaefe95bd84fd3f32700cf3b7566bc944b73138e41958b5785826df2aecace0
```

Alternatively, `cast keccak` can be used.
Call it with the storage slot string identifier, and subtract `1` from the result:
```
cast keccak protocolversion.recommended
# 0xe314dfc40f0025322aacc0ba8ef420b62fb3b702cf01e0cdf3d829117ac2ff1b

cast keccak protocolversion.required
# 0x4aaefe95bd84fd3f32700cf3b7566bc944b73138e41958b5785826df2aecace1
```

## Version Encoding

Each of the two aforementioned slots holds an _encoded_ protocol version that has the four typical
semver components _major, minor, patch_ and _pre-release_.
See [specs](https://github.com/ethereum-optimism/specs/blob/main/specs/protocol/superchain-upgrades.md#protocol-version) for more in-depth details.

An encoded version for comparison can be generated with the `protocol-version` encoding tool in the
monorepo, e.g. for a bump of the major version to 7:
```
cd $(git rev-parse --show-toplevel)/lib/optimism
go run ./op-chain-ops/cmd/protocol-version encode --major 7
```
The tool can also be used to decode an encoded protocol version.

## Events

A `ConfigUpdate` event is emitted by the `ProtocolVersions` contract for each changed protocol
version, with 
* the `data` field containing the new encoded protocol version,
* the `updateType` being `1` for the _recommended_ and `0` for the _required_ version, as can be
  validated from the [`UpdateType` enum definition](https://github.com/ethereum-optimism/optimism/blob/57c833aed031669e2847e4102118e357eb962a5c/packages/contracts-bedrock/src/L1/ProtocolVersions.sol#L18).
