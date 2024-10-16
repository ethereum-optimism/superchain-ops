# Mainnet - Ecotone Blobs Gas Configuration

Status: [DRAFT]

## Objective

This is the playbook for updating the onchain gas limit of the `SystemConfig`. When combined with setting the `GETH_MINER_EFFECTIVEGASLIMIT = 30_000_000` env var on the sequencers, this has the effect of keeping the gas limit at 30Mgas/block and  
increasing the gas target from 5Mgas/block to 15Mgas/block.

### Timing

The transaction is scheduled for execution on October 17, 2024. This date has already been communicated to external parties.

## Transaction creation

The transaction was created in the root directory with

```
just add-transaction tasks/eth/020-set-gas-target/input.json 0x229047fed2591dbec1eF1118d64F7aF3dB9EB290 'setGasLimit(uint64)' 90000000
```

## Signing and execution

Please see the signing and execution instructions in [SINGLE.md](../../../SINGLE.md).

## Validations

### State

On the "State" tab, you can verify that the following state change occured on the `SystemConfigProxy` at `0x229047fed2591dbec1ef1118d64f7af3db9eb290`:

* `gasLimit` changed from `30_000_000` to `90_000_000`

The other two state changes are nonce increases by the multisig Proxy at `0x9ba6e03d8b90de867373db8cf1a58d2f7f006b3a`
and the sender account.

### Events

On the "Events" tab, you can verify that one `ConfigUpdate` event was emitted from the `SystemConfigProxy`,
of `updateType = 2` and `data` containing the encoded gasLimit value.

The multisig proxy emits an `ExecutionSuccess` event.
