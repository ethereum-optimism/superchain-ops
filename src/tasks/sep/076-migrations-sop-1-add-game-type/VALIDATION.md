# Validation

This document can be used to validate the inputs and result of the execution of the upgrade transaction which you are
signing.

The steps are:

1. [Validate the Domain and Message Hashes](#expected-domain-and-message-hashes):
2. [Transaction Inputs](config.toml): inputs can be verified in the config.toml file, which includes links to the relevant Superchain Registry sources.
3. State Changes: the template's _validate block includes assertions to confirm the task ran correctly. State Changes can also be manually reviewed in Tenderly, using the link shown in the terminal during simulation.

## Expected Domain and Message Hashes

First, we need to validate the domain and message hashes. These values should match both the values on your ledger and
the values printed to the terminal when you run the task.

> [!CAUTION]
>
>
> ### Migrations-sop-1 1/1 Safe (`0xe934Dc97E347C6aCef74364B50125bb8689c40ff`)
>
> - Domain Hash:  `<TBD_DOMAIN_HASH>`
> - Message Hash: `<TBD_MESSAGE_HASH>`
>
## Task Calldata

Calldata:
```
<TBD_CALLDATA>
```
