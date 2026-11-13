# sep-devnets

Tasks for OP Labs devnets that settle to Sepolia (e.g. `sepolia-devnet-*` chains).

- Put a task here only if every Safe it touches is devnet-only. A task that also touches a
  production Sepolia Safe stays in `sep/`, so the stacked simulation sees all of that Safe's nonces.
- Tasks are numbered from `001` independently of `sep/`. Simulate with
  `just simulate-stack sep-devnets [task]`. CI runs this as `stacked_simulation_sep_devnets`.
- The L1 RPC and the `[sep]` table in `src/addresses.toml` are the same as for `sep/`.
- Devnet tasks executed before this directory existed stay in `sep/`.
