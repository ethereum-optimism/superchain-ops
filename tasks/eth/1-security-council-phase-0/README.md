# Security Council Phase 0 Multisig Ceremony.

Status: EXECUTED

## Objective

This is the playbook for executing the Security Council Phase 0 as
approved by Governance. There are two governance proposals and one
forum update related to this:

1. [Security Council: Vote #1](https://vote.optimism.io/proposals/27439950952007920118525230291344523079212068327713298769307857575418374325849).
2. [Security Council Membership Ratification](https://vote.optimism.io/proposals/85591583404433237270543189567126336043697987369929953414380041066767718361144).
3. [Governance Post containing the threshold and signer
   addresses](https://gov.optimism.io/t/security-council-vote-2-initial-member-ratification/7118/20)

All of them should be treated as the source of truth and used by the
multisig signers to verify the correctness of the onchain operations.

## Approving the transaction

### 1. Update repo and move to the appropriate folder for this rehearsal task:

```
cd superchain-ops
git pull
just install
cd task/eth/1-security-council-phase-0
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
validate integrity of the simulation, we need to check the following:

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

1. There are only two state overrides at address
   `0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`:

   a. One of them overrides storage slot `0x4` to new value
   `0x1`. This override is only intended to change the Foundation
   multisig's quorum threshold to 1 so we can perform a tenderly
   simulation of the execution,

   b. One of them overrides storage slot `0x5` to `0x56`. This
   override is an no-op to override the nonce of the multisig to 86,
   which is the same as it's current value. You can see the current
   value of the nonce in the "State Changes" section.

2. The `ProxyAdmin` contract at
   `0x543ba4aadbab8f9025686bd03993043599c6fb04`'s `_owner` is changed
   to a new multisig, and the configuration of this new multisig
   correctly implements the two approved proposals and the one forum
   update in the Objectives section. Some example things to check:

   a. Verify that the `_owner` of `ProxyAdmin` is changed to a 2 of 2
   multisig.

   b. Verify that the 2 signers are the new Foundation multisig
   (`eth:0x847B5c174615B1B7fDF770882256e2D3E95b9D92`) and the Security
   Council multisig
   (`eth:0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`).
   
   c. Verify that the new Foundation multisig's threshold and signers
   are identical to the old Foundation multisig.
   
   d. Verify that the Security Council multisig's threshold and
   signers match what's published in the governance forum.

4. Both of the other state changes are nonce changes only.


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
