# 041-U18-uni

Status: [READY TO SIGN]

NOTE: the Developer Advisory Board vote [incorrectly shows the status as rejected](https://snapshot.box/#/s:optimismdab.eth/proposal/0x459a5bf698d12b3902011ceffcf2ec836535ef2c32a85e133a4696327cc2e5d6) because the quorum was incorrectly set to 7/7 instead of 5/7. It passed with 6/7 votes for and 0/7 against.

## Objective

U18 on Unichain Mainnet.

## Simulation & Signing

### For Signers

```bash
# Change directory to the correct task
cd src/tasks/eth/041-U18-uni

# Command to simulate
just simulate-stack eth 041-U18-uni <foundation|council|chain-governor>

# Command to sign
just sign-stack eth 041-U18-uni <foundation|council|chain-governor>
```

### For Facilitators, after signatures have been collected

```bash
# Change directory to the correct task
cd src/tasks/eth/041-U18-uni

# Command to approve
SIGNATURES=0x just approve <foundation|council|chain-governor>

# Command to execute
just execute

# Add USE_KEYSTORE=1 to the above if you are using a local keystore instead of a connected Ledger
```
