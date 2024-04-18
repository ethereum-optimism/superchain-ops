# Metal Sepolia MCP L1 Upgrade

Status: READY TO SIGN

## Objective

This is the playbook for executing the following security council changes on Sepolia.

1. Finalize the configuration of a newly deployed Security Council Safe
1. Increase the threshold of the Security Council (this is not required on Sepolia, as the SC Safe was setup accordingly, but is included here for convenience when copying this for mainnet)
1. Transfer Ownership of the L1 Proxy Admin to a new 2 of 2 Safe (already setup)

Reduce Pause: Reduce non-SC's ability to pause indefinitely.

### Key addresses involved:

1. L1 ProxyAdmin: 0x189aBAAaa82DfC015A588A7dbaD6F13b1D3485Bc
2. L1 FoundationMockSafe: 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B
3. SuperchainConfig: 0xC2Be75506d5724086DEB7245bd260Cc9753911Be
4. SecurityCouncilSafe: 0xa87675ebb9501C7baE8570a431c108C1577478Fa #new contract
5. DeputyGuardianModule: 0x2329EfD0bFc72Aa7849D9DFc2e131D83F4680d85 #new contract
6. LivenessGuard: 0x54E8baCcC67fA3c6b3e9A94BAa4d70d1668f0820 #new contract
7. LivenessModule: 0xefd77C23A8ACF13E194d30C6DF51F1C43B0f9932 #new contract
8. 2 of 2 Safe: 0xeD3d7D9f610a8ACcBe9CACA172B7F3d70530E89D

Question:
- do we need a runbook to add the LivenessModule, or can we just do it?
  - well, we're gonna need it on Mainnet, and in fact on Mainnet we will need a more complex ceremony
    to add all the modules and guard at once.

conclusion:
- two runbooks (006-0 and 006-1)
-
- option 1:
  - focus on state diff checking by comparing well annotated solidity structs to the recorded state accesses.
  - Can also assert that untouched contracts are not present in isWrite accesses (both Account and Storage)
    - then i can delete the checkX functions for those contracts
  - larger diff from metal and mode runbooks
  - maybe more review work for Matt?
  - add new checkX() functions to verify the behaviour of
    - security council safe
    - foundation safe
    - the modules and guard
- option 2:
  - keep pretty much everything in the metal runbook, tweaking the chain name should just work pretty much
  - add new checkX() functions to verify the behaviour of
    - security council safe
    - foundation safe
    - the modules and guard

### Flow

1. From the SecurityCouncilSafe...
  the SecurityCouncilSafe is currently deployed and has the LivenessGuard set and DeputyGuardianModule enabled.
  The final setup will require a threshold of signers to
       1. call enableModule() to enable the LivenessModule deployed at 0xefd77C23A8ACF13E194d30C6DF51F1C43B0f9932
       2. remove the deployer (0x78339d822c23D943E4a2d4c3DD5408F66e6D662D) which is still an owner (could cut this scope).
1. From the FoundationSafe...
   Transfer ownership of the L1 Proxy Admin to the 2 of 2.

## Simulation

Please see the "Simulating and Verifying the Transaction" instructions in [SINGLE.md](../../../SINGLE.md).
When simulating, ensure the logs say `Using script Using script /your/path/to/superchain-ops/tasks/sep/metal-001-MCP-L1/SignFromJson.s.sol`.
Thus ensures all safety checks are run. If the default `SignFromJson.s.sol` script is shown
(without the full path), something is wrong and the safety checks will not run.

Do NOT yet proceed to the "Execute the Transaction" section.

## State Validations

Please see the instructions for [validation](./VALIDATION.md).

## Execution

At this point you may resume following the execution instructions in the "Execute the Transaction" section of [SINGLE.md](../../../SINGLE.md).
