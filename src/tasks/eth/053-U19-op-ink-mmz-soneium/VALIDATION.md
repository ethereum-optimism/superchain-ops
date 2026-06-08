# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are signing.

> [!IMPORTANT]
> The hashes and calldata below cannot be populated until the canonical
> `cannon64-kona` absolute prestate is published in
> `superchain-registry/validation/standard/standard-prestates.toml` and
> wired into [config.toml](./config.toml) (replacing the
> `0xdeaddeaddead...` placeholder on `cannonKonaPrestate` for OP and Ink).
> Once that lands, re-run `just simulate-stack eth` and fill the values in.
> Until then `stacked_simulation_eth` in CI will fail on this task because
> the simulator cannot find the placeholder-derived hashes in this file.

## Expected Domain and Message Hashes

First, validate the domain and message hashes. These values should match both the values on your ledger and the values printed to the terminal when you run the task.

> [!CAUTION]
>
> Before signing, ensure the below hashes match what is on your ledger.
>
> ### Security Council (`0xc2819DC788505Aac350142A7A707BF9D03E3Bd03`)
>
> - Domain Hash:  `TODO`
> - Message Hash: `TODO`
>
> ### Foundation Upgrade Safe (`0x847B5c174615B1B7fDF770882256e2D3E95b9D92`)
>
> - Domain Hash:  `TODO`
> - Message Hash: `TODO`

## Task Calldata

TODO — populate after replacing the `0xdead...` placeholder prestate(s) with
the canonical kona absolute prestate(s) from
`superchain-registry/validation/standard/standard-prestates.toml` and
re-running the simulation.
