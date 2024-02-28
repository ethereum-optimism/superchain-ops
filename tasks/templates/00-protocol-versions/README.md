# Mainnet Protocol Versions Update - X.0.0 (Forkname TODO)

Status: DRAFT, NOT READY TO SIGN

## Objective

This is the playbook for updating the required/recommended(TODO) protocol versions of the `ProtocolVersions` contract on Ethereum mainnet to X.0.0 (Forkname TODO).

Both versions are currently set to X.Y.0 (Old Forkname TODO).

## _TODO: TX Creation_

_Transactions can be created using
```
export PV_ENC=$(cd ../../../lib/optimism && go run ./op-chain-ops/cmd/protocol-version encode --major <TODO:major-version>)
# 0x0000000000000000000000000000000000000005000000000000000000000000 
export PV_ADDR=0x8062AbC286f5e7D9428a0Ccb9AbD71e50d93b935 
just add-transaction $PV_ADDR 'setRecommended(uint256)' $PV_ENC
just add-transaction $PV_ADDR 'setRequired(uint256)' $PV_ENC
```
This batches setting both, the recommended and required versions in one multicall.

Adapt accordingly if only setting one of require/recommended or if setting different versions._

## Approving the transaction

### 1. Update repo and move to the appropriate folder for this rehearsal task:

```
cd superchain-ops
git pull
just install
cd tasks/eth/03-protocol-version
```

### 2. Setup Ledger

Your Ledger needs to be connected and unlocked. The Ethereum
application needs to be opened on Ledger with the message "Application
is ready".

### 3. Simulate and validate the transaction

Make sure your ledger is still unlocked and run the following.

Remember that by default `just` is running with the address derived from
`/0` (first nonce). If you wish to use a different account, run `just
simulate [X]`, where X is the derivation path of the address
that you want to use.

You will see a "Simulation link" from the output.

Paste this URL in your browser. A prompt may ask you to choose a
project, any project will do. You can create one if necessary.

Click "Simulate Transaction".

We will be performing 3 validations and extract the domain hash and
message hash to approve on your Ledger:

1. Validate integrity of the simulation.
2. Validate correctness of the state diff.
3. Validate and extract domain hash and message hash to approve.

#### 3.1. Validate integrity of the simulation.

Make sure you are on the "Overview" tab of the tenderly simulation, to
validate integrity of the simulation, we need to check the following:

1. "Network": Check the network is mainnet.
2. "Timestamp": Check the simulation is performed on a block with a
   recent timestamp (i.e. close to when you run the script).
3. "Sender": Check the address shown is your signer account. If not,
   you will need to determine which “number” it is in the list of
   addresses on your ledger. By default the script will assume the
   derivation path is `m/44'/60'/0'/0/0`. By calling the script with
   `just simulate 1` it will derive the address using
   `m/44'/60'/1'/0/0` instead.

#### 3.2. Validate correctness of the state diff.

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

#### 3.3. Extract the domain hash and the message hash to approve.

Now that we have verified the transaction performs the right
operation, we need to extract the domain hash and the message hash to
approve.

Go back to the "Overview" tab, and find the
`GnosisSafe.checkSignatures` call. This call's `data` parameter
contains both the domain hash and the message hash that will show up
in your Ledger.

Here is an example screenshot. Note that the hash value may be
different:

![](./images/tenderly-hash.png)

It will be a concatenation of `0x1901`, the domain hash, and the
message hash: `0x1901[domain hash][message hash]`.

Note down this value. You will need to compare it with the ones
displayed on the Ledger screen at signing.

### 4. Approve the signature on your ledger

Once the validations are done, it's time to actually sign the
transaction. Make sure your ledger is still unlocked and run the
following:

``` shell
just sign # or just sign <hdPath>
```

> [!IMPORTANT] This is the most security critical part of the
> playbook: make sure the domain hash and message hash in the
> following two places match:

1. on your Ledger screen.
2. in the Tenderly simulation. You should use the same Tenderly
   simulation as the one you used to verify the state diffs, instead
   of opening the new one printed in the console.

There is no need to verify anything printed in the console. There is
no need to open the new Tenderly simulation link either.

After verification, sign the transaction. You will see the `Data`,
`Signer` and `Signature` printed in the console. Format should be
something like this:

```
Data:  <DATA>
Signer: <ADDRESS>
Signature: <SIGNATURE>
```

Double check the signer address is the right one.

### 5. Send the output to Facilitator(s)

Nothing has occurred onchain - these are offchain signatures which
will be collected by Facilitators for execution. Execution can occur
by anyone once a threshold of signatures are collected, so a
Facilitator will do the final execution for convenience.

Share the `Data`, `Signer` and `Signature` with the Facilitator, and
congrats, you are done!

## [For Facilitator ONLY] How to execute the rehearsal

### [After the rehearsal] Execute the output

1. Collect outputs from all participating signers.
2. Concatenate all signatures and export it as the `SIGNATURES`
   environment variable, i.e. `export
   SIGNATURES="0x[SIGNATURE1][SIGNATURE2]..."`.
3. Run `just execute 0 # or 1 or ...` to execute the transaction onchain.

For example, if the quorum is 2 and you get the following outputs:

``` shell
Data:  0xDEADBEEF
Signer: 0xC0FFEE01
Signature: AAAA
```

``` shell
Data:  0xDEADBEEF
Signer: 0xC0FFEE02
Signature: BBBB
```

Then you should run

``` shell
export SIGNATURES="0xAAAABBBB"
just execute 0 # or 1 or ...
```
