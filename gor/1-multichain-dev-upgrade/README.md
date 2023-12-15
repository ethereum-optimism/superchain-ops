# dev-superchain-upgrade

This upgrades the chaosnet chain on the goerli dev superchain target.
It skips the internal devnet chain because it is still owned by an
unknown EOA and the internal devnet artifacts that were in the monorepo
are not the correct artifacts.

The implementation versions are as follows:

```
l1_cross_domain_messenger: 1.7.0
l1_erc721_bridge: 1.4.0
l1_standard_bridge: 1.4.0
l2_output_oracle: 1.6.0
optimism_mintable_erc20_factory: 1.6.0
optimism_portal: 1.10.0
system_config: 1.10.0
```

The included chains are:
- op-labs-chaosnet-0

This particular upgrade does not include a `justfile` as it should be executed
via the Safe UI.
