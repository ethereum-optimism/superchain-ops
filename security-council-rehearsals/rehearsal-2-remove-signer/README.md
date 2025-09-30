# Rehearsal 2 - Signer Removal

## Objective

In this rehearsal, we will be removing one of the owners from the Safe.

Once completed:
- The Safe will have one fewer owner
- The threshold will remain unchanged

The call executed by the Safe contract is defined in the `build` function of the [`GnosisSafeRemoveOwner`](../../src/template/GnosisSafeRemoveOwner.sol) template.

Note: No onchain actions will occur during this rehearsal. You are not submitting a transaction, and your wallet does not need to be funded. You will simply sign an offchain message with your wallet. These signatures will be collected by a Facilitator, who will submit them for execution.
Once the required number of signatures is collected, anyone can finalize the execution. For convenience, a Facilitator will handle this step.

## Approving the transaction

### 1. Update repo and move to the appropriate folder for this rehearsal task:

```
cd superchain-ops
git pull
# Make sure you've installed the dependencies for the repository.
cd src/tasks/<network>/rehearsals/<rehearsal-task-name> # This path should be shared with you by the Facilitator.
```

See the [README](../../src/README.md) for more information on how to install the dependencies for the repository.

### 2. Setup Ledger

Your Ledger needs to be connected and unlocked. The Ethereum
application needs to be opened on Ledger with the message “Application
is ready”.

### 3. Simulate and validate the transaction

Make sure your ledger is still unlocked and run the following.

``` shell
cd src/tasks/<network>/rehearsals/<rehearsal-task-name>
just --dotenv-path $(pwd)/.env simulate
# For a different derivation path, use: HD_PATH=1 just --dotenv-path $(pwd)/.env simulate
```

You will see a "Simulation link" URL in the output.

Copy this URL from the output and and open it with your browser. A prompt may ask you to choose a
project, any project will do. You can create one if necessary.

Click "Simulate Transaction".

We will be performing 3 validations and ensure the domain hash and
message hash are the same between the Tenderly simulation and your
Ledger:

1. Validate integrity of the simulation.
2. Validate correctness of the state diff.
3. Validate and extract domain hash and message hash to approve.

#### 3.1. Validate integrity of the simulation.

To validate integrity of the simulation, we need to check the following:

1. "Network": Check the network is Ethereum Mainnet.
2. "Timestamp": Check the simulation is performed on a block with a
   recent timestamp (i.e. close to when you run the script).
3. "Sender": Check the address shown is your signer account. If not,
   you will need to determine which “number” it is in the list of
   addresses on your ledger. By default the script will assume the
   derivation path is `m/44'/60'/0'/0/0`.

Here is an example screenshot, note that the Timestamp and Sender
might be different in your simulation:

![](./images/1-simulation-success.png)

#### 3.2. Validate correctness of the state diff.

Now click on the "State" tab. Verify that:

1. The rehearsal Safe's `ownerCount` is reduced by one.
2. The `owners` mapping will have one less entry. You'll see 2 state changes that represent the removal of the signer from the `owners` mapping.
3. You will see a `threshold` change from `1` to a new value. This only exists in the simulation and is safe to ignore as long as the new value is equal to the actual threshold of the Safe.
4. You'll see 2 nonce changes from the Safe and the signer address.
5. You may see some LivenessGuard state changes which are safe to ignore, as per the screenshot below. These are a result of using the production Security Council safe for the simulation, which has LivenessGuard enabled.
6. You will see a state override (not a state change). This is expected and its purpose is to generate a successful Safe execution simulation without collecting any signatures.

Here is an example screenshot. Note that the addresses may be
different:

![](./images/2-state-diff.png)

#### 3.3. Extract the domain hash and the message hash to approve.

Now that we have verified the transaction performs the right
operation, we need to extract the domain hash and the message hash to
approve.

Go back to the "Overview" tab, and find the first
`GnosisSafe.domainSeparator` call. This call's return value will be
the domain hash that will show up in your Ledger.

Here is an example screenshot. Note that the hash value may be
different:

![](./images/3-tenderly-hashes.png)

Right before the `GnosisSafe.domainSeparator` call, you will see a
call to `GnosisSafe.encodeTransactionData`. Its return value will be a
concatenation of `0x1901`, the domain hash, and the message hash:
`0x1901[domain hash][message hash]`.

Here is an example screenshot. Note that the hash value may be
different:

![](./images/4-tenderly-hashes.png)

Note down both the domain hash and the message hash. You will need to
compare them with the ones displayed in your terminal AND on the Ledger screen at signing.

### 4. Approve the signature on your ledger

Once the validations are done, it's time to actually sign the
transaction. Make sure your ledger is still unlocked and run the
following:

``` shell
cd src/tasks/<network>/rehearsals/<rehearsal-task-name>
just --dotenv-path $(pwd)/.env sign
# For a different derivation path, use: HD_PATH=1 just --dotenv-path $(pwd)/.env sign
```

> [!IMPORTANT] This is the most security critical part of the
> playbook: make sure the domain hash and message hash in the
> following three places match:

1. In your terminal output.
2. On your Ledger screen.
3. In the Tenderly simulation. You should use the same Tenderly
   simulation as the one you used to verify the state diffs, instead
   of opening the new one printed in the console.

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

Format should be something like this:

```
Data:  <DATA>
Signer: <ADDRESS>
Signature: <SIGNATURE>
```

Share the `Data`, `Signer` and `Signature` with the Facilitator, and
congrats, you are done!

## [For Facilitator ONLY] How to prepare and execute the rehearsal

### [Before the rehearsal] Prepare the rehearsal

#### 1. Create a new task in the `eth` directory:

```bash
cd superchain-ops/src
just new task # Follow the prompts to create a new rehearsals task. 
# (a) choose 'eth' 
# (b) choose 'GnosisSafeRemoveOwner' 
# (c) press enter to answer 'no' to 'Is this a test task?'
# (d) press 'y' for 'Is this a security council rehearsal task?'
# (e) enter a name of the task in the format of '<yyyy-mm-dd>-<task-name>'

# This creates a new directory in the `src/tasks/eth/rehearsals` directory.
```

Next, make sure your `config.toml` is correct. You should use the TOML below as a starting point.

```toml
templateName = "GnosisSafeRemoveOwner"

safeAddressString = "SecurityCouncil"
allowOverwrite = ["SecurityCouncil"] # We know that we want to overwrite the default SecurityCouncil address in [addresses].
ownerToRemove = "<enter-the-owner-address-to-remove>" # This address must exist on the Gnosis Safe below.

[addresses]
SecurityCouncil = "<enter-your-multisig-address>" # This should be the address of the Gnosis Safe that you created.
```

#### 2. Test the rehearsal and commit the files to Github

1. Test the newly created rehearsal by following the security council
   steps in the `Approving the transaction` section above.
2. Commit the newly created files to Github.

### [After the rehearsal] Execute the output

1. Collect outputs from all participating signers.
2. Concatenate all signatures and export it as the `SIGNATURES`
   environment variable, i.e. `export
   SIGNATURES="0x[SIGNATURE1][SIGNATURE2]..."`.
3. Execute the transaction onchain.

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
cd src/tasks/<network>/rehearsals/<rehearsal-task-name>
just --dotenv-path $(pwd)/.env execute
```

For posterity, you should make a `README.md` file in the tasks directory that contains a link to the executed transaction e.g. see [here](../../src/tasks/eth/rehearsals/2025-11-28-R2-remove-signer/README.md).
