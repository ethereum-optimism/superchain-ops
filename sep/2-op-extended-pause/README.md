# Sepolia Extended Pause Upgrade

## Objective

This is the playbook for executing the second Extended Pause upgrade ceremony on OP Sepolia.

## Approving the transaction

### 1. Update repo and move to the appropriate folder for this rehearsal task:

```
cd superchain-ops
git pull
just install
cd sep/2-op-extended-pause
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

1. "Network": Check the network is Sepolia.
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
   `0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B`, which overrides
   storage slot `0x4` to new value `0x1`. This override is only
   intended to change the Foundation multisig's quorum threshold to 1
   so we can perform a tenderly simulation of the execution,
1. Any state changes not listed below are nonce changes only.
1. The Address Manager (at `0x9bfe9c5609311df1c011c47642253b78a4f33f4b`) has the address of the L1CrossDomainMessenger (at key `0x515216935740e67dfdda5cf8e248ea32b3277787818ab59153061ac875c9385e`) updated to `0x7c9b3a3455714f25525f31e91412715f06062fd`.
1. The implementation slot (`0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`) for
   each of the following addresses is updated such that the new implementation is:

| Name                              | Proxy Address                              | New Implementation Address                 |
| --------------------------------- | ------------------------------------------ | ------------------------------------------ |
| SystemConfigProxy                 | 0x034edD2A225f7f429A63E0f1D2084B9E0A93b538 | 0xDcDbe0A5fb83f0D59959A9eb13c4061173E4c602 |
| OptimismPortalProxy               | 0x16Fc5058F25648194471939df75CF27A2fdC48BC | 0x9e714EF35d8E9a44a509ebf40924EeD8E7dE461B |
| OptimismMintableERC20FactoryProxy | 0x868D59fF9710159C2B330Cc0fBDF57144dD7A13b | 0x122F08d07037f706CCf546b7d0B81A97097D4E08 |
| L2OutputOracleProxy               | 0x90E9c4f8a994a250F6aEfd61CAFb4F2e895D458F | 0xA98Bb793B451F7bCcFFb8d09E53dB74a448200B4 |
| L1ERC721BridgeProxy               | 0xd83e03D576d23C9AEab8cC44Fa98d058D2176D1f | 0x0ba60F74Ac6F5D0ED35884a7d64B4536E4194Ba8 |
| L1StandardBridgeProxy             | 0xFBb0621E0B23b5478B630BD55a5f21f67730B0F1 | 0x462765817deB624731BF118A27Ce83c3FfAa405c |


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
