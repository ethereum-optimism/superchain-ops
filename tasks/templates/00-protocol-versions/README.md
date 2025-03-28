# Mainnet Protocol Versions Update - X.0.0 (Forkname TODO)

Status: DRAFT, NOT READY TO SIGN

## Objective

This is the playbook for updating the required/recommended(TODO) protocol versions of the `ProtocolVersions` contract on Ethereum mainnet to X.0.0 (Forkname TODO).

Both versions are currently set to X.Y.0 (Old Forkname TODO).

## _TODO: TX Creation_

_Transactions can be created using
```
export PV_ENC=$(cd $(git rev-parse --show-toplevel)/lib/optimism && go run ./op-chain-ops/cmd/protocol-version encode --major <TODO:major-version>)
# 0x0000000000000000000000000000000000000005000000000000000000000000
export PV_ADDR=$(yq .protocol_versions_addr "$(git rev-parse --show-toplevel)/lib/superchain-registry/superchain/configs/mainnet/superchain.yaml")
just add-transaction $(git rev-parse --show-prefix)input.json $PV_ADDR 'setRecommended(uint256)' $PV_ENC
just add-transaction $(git rev-parse --show-prefix)input.json $PV_ADDR 'setRequired(uint256)' $PV_ENC
```
This batches setting both, the recommended and required versions in one multicall.

Adapt accordingly if only setting one of require/recommended or if setting different versions._

## Signing and execution

Please see the signing and execution instructions in [SINGLE.md](../../../SINGLE.md).

## State Validations

Now click on the "State" tab. Verify that:

_TODO: Adapt to actual changes._

* For the `ProtocolVersions` Proxy at `0x8062AbC286f5e7D9428a0Ccb9AbD71e50d93b935` both the
  recommended and required storage slots are updated from the encoded form of `3.1.0` to `5.0.0`.
  * key `0x4aaefe95bd84fd3f32700cf3b7566bc944b73138e41958b5785826df2aecace0`
    * before: `0x0000000000000000000000000000000000000003000000010000000000000000`
    * after : `0x0000000000000000000000000000000000000005000000000000000000000000`
  * key `0xe314dfc40f0025322aacc0ba8ef420b62fb3b702cf01e0cdf3d829117ac2ff1a`
    * before: `0x0000000000000000000000000000000000000003000000010000000000000000`
    * after : `0x0000000000000000000000000000000000000005000000000000000000000000`
* All other state changes (2) are a nonce change of the sender account and the multisig.

On the "Events" tab, you can verify that two `ConfigUpdate` events were emitted from the `ProtocolVersions` proxy,
as well as an `ExecutionSuccess` event by the multisig.

![](./images/tenderly-state.png)

You can verify the correctness of the storage slots with `chisel`.
Just start it up and enter the slot definitions as found in the contract source code.
```
➜ bytes32(uint256(keccak256("protocolversion.required")) - 1)
Type: bytes32
└ Data: 0x4aaefe95bd84fd3f32700cf3b7566bc944b73138e41958b5785826df2aecace0
➜ bytes32(uint256(keccak256("protocolversion.recommended")) - 1)
Type: bytes32
└ Data: 0xe314dfc40f0025322aacc0ba8ef420b62fb3b702cf01e0cdf3d829117ac2ff1a
```

Alternatively, `cast keccak` can be used.
Call it with the storage slot string identifier, and subtract `1` form the result:
```
cast keccak protocolversion.required
# 0x4aaefe95bd84fd3f32700cf3b7566bc944b73138e41958b5785826df2aecace1

cast keccak protocolversion.recommended
# 0xe314dfc40f0025322aacc0ba8ef420b62fb3b702cf01e0cdf3d829117ac2ff1b
```

## Continue signing

At this point you may resume following the signing and execution instructions in section 3.3 of [SINGLE.md](../../../SINGLE.md).
