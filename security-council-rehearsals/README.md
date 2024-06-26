# Security Council Rehearsals

This directory contains templates and ceremonies related to onboarding
security council members.

## Creating a new rehearsal ceremony

To create a new rehearsal ceremony, run the following commands:

``` shell
cd superchain-ops
git pull
just install
cd security-council-rehearsals
just setup [rehearsal-name] [optional-suffix]
```

where `rehearsal-name` can be one of the following rehearsal names:

1. `r1-hello-council`: a simple rehearsal to ensure that all the
   signers feel confident running the tooling and performing the
   validations required to execute an onchain action.
2. `r2-remove-signer`: a rehearsal to remove one security council
   members from the multisig.
3. `r4-jointly-upgrade`: a rehearsal to perform a protocol upgrade
   jointly with Optimism Foundation via a nested 2-of-2 multisig.
3. `r5-guardian-override`: a rehearsal to unpause withdrawals and
   remove the Deputy Guardian Module.

`optional-suffix` is optional and will be appended to newly-created
folder's name.
