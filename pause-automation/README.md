



https://github.com/user-attachments/assets/e09f0a5c-5d2a-4df3-b7cd-3249d3a8b1e4
## Automation Pause (AP)

_Automation Pause_ (AP) is a script that pause the superchain fast and simply.
This tool is used in **CLI** and have a **TUI** interface to choose which network you desired to pause in case of emergency.
Remember pausing the network will only affect the withdrawals, the L2 will still be progressing.

### Usage

```bash
git clone git@github.com:ethereum-optimism/superchain-ops.git && cd superchain-ops/pause-automation/;
just --justfile pause-automation.just pause
```

The script will ask for **1** confirmation with the "yes" or "no" option.
Once "yes" is selected, the network will be paused and the script will return the transactionHash.

> [!WARNING]
> There is no cancel option after the "yes" confirmation is selected.




The necessaries informations like the `DeputyPauseModule`, `SuperchainConfig` or the `Foundation Operation Safe`, will be dynamically pulled from the [Superchain Registry](https://github.com/ethereum-optimism/superchain-registry) and on-chain.
The only information asked to the **operator** is to select the network from the TUI and confirm with "yes" or "no".


