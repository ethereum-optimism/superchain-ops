# Security Council Phase 0 Multisig Ceremony.

Status: DRAFT, NOT READY TO SIGN

> [!IMPORTANT] !!! DO NOT SIGN using this playbook yet, as the
> Security Council membership ratification proposal is not passed, and
> the final multisig is not set up yet.

## Objective

This is the playbook for executing the Security Council Phase 0 as
approved by Governance. There are two governance proposals related to
this:

1. [Security Council: Vote #1](https://vote.optimism.io/proposals/27439950952007920118525230291344523079212068327713298769307857575418374325849).
2. [Security Council Membership Ratification](https://link.to/be/determined).

Both of them should be treated as the source of truth and used by the
multisig signers to verify the correctness of the onchain operatins.

## Approving the transaction

### 1. Update repo and move to the appropriate folder for this rehearsal task:

```
cd superchain-ops
git pull
just install
cd eth/1-security-council-phase-0
```

### 2. Setup Ledger

Your Ledger needs to be connected and unlocked. The Ethereum
application needs to be opened on Ledger with the message "Application
is ready".

### 3. Simulate and validate the transaction

Make sure your ledger is still unlocked and run the following.

Remember that by default just is running with the address derived from
`/0` (first nonce). If you wish to use a different account, run `just
simulate [X]`, where X is the derivation path of the address
that you want to use.

``` shell
just simulate
```

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
validate integrity of the simulation, we need to

1. "Network": Check the network is Ethereum Mainnet.
2. "Timestamp": Check the simulation is performed on a block with a
   recent timestamp (i.e. close to when you run the script).
3. "Sender": Check the address shown is your signer account. If not,
   you will need to determine which “number” it is in the list of
   addresses on your ledger. By default the script will assume the
   derivation path is m/44'/60'/0'/0/0. By calling the script with
   `just simulate 1` it will derive the address using
   m/44'/60'/1'/0/0 instead.

![](./images/tenderly-overview-network.png)

#### 3.2. Validate correctness of the state diff.

Now click on the "State" tab. Verify that:

1. There is only a single state override at address
   `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`, which overrides
   storage slot `0x4` to new value `0x1`. This override is only
   intended to change the Foundation multisig's quorum threshold to 1
   so we can perform a tenderly simulation of the execution,
2. The `ProxyAdmin` contract at
   `0x543ba4aadbab8f9025686bd03993043599c6fb04`'s `_owner` is changed
   to a new multisig, and the configuration of this new multisig
   correctly implements the two approved proposals:
   1. [Security Council: Vote #1](https://vote.optimism.io/proposals/27439950952007920118525230291344523079212068327713298769307857575418374325849).
   2. [Security Council Membership Ratification](https://link.to/be/determined).
3. Both of the other state changes are nonce changes only.


All of these addresses should be part of the Optimism Governance vote
that approves this upgrade if this is a [Normal
Operation](https://github.com/ethereum-optimism/OPerating-manual/blob/1f42a3766d084864a818b93ce7ba0857a4a846ea/Security%20Council%20Charter%20v0.1.md#normal-operation).

![](./images/tenderly-state-diff.png)


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
