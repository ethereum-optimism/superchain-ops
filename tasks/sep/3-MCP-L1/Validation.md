# Validation

This document can be used to validate the state diff resulting from the execution of the upgrade
transaction.

Please ensure that the following changes (and none others) are made to each contract in the system.
The "Before" values are excluded from this list and need not be validated.

## State Overrides

There should also be a single 'State Override' in the Foundation Safe contract
(`0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A`) to enable the simulation by reducing the threshold to
1:

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000004` <br/>
  **Value:** `0x0000000000000000000000000000000000000000000000000000000000000001`

## State Changes

##### `0x9ba6e03d8b90de867373db8cf1a58d2f7f006b3a` (`SafeProxy`)

- **Key:** `0x0000000000000000000000000000000000000000000000000000000000000005` <br/>
  **After:** `0x0000000000000000000000000000000000000000000000000000000000000057` <br/>
  **Meaning:** The Safe nonce is updated.<br/>
  **Additional Note:** This number may be slightly different if other transactions have recently
  been executed. The important thing is that it should change by 1.


##### `0x034edd2a225f7f429a63e0f1d2084b9e0a93b538` (`SystemConfig`)

- 1967 Implementation slot should match the new system config implementation that we want at 0xba2492e52f45651b60b8b38d4ea5e2390c64ffb1

| Slot Name | Slot Key |
| --- | --- |
| BATCH_INBOX_SLOT | 0x71ac12829d66ee73d8d95bff50b3589745ce57edae70a3fb111a2342464dc597 |
| L1_CROSS_DOMAIN_MESSENGER_SLOT | 0x383f291819e6d54073bc9a648251d97421076bdd101933c0c022219ce9580636 |
| L1_ERC_721_BRIDGE_SLOT | 0x46adcbebc6be8ce551740c29c47c8798210f23f7f4086c41752944352568d5a7 |
| L1_STANDARD_BRIDGE_SLOT | 0x9904ba90dde5696cda05c9e0dab5cbaa0fea005ace4d11218a02ac668dad6376 |
| L2_OUTPUT_ORACLE_SLOT | 0xe52a667f71ec761b9b381c7b76ca9b852adf7e8905da0e0ad49986a0a6871815 |
| OPTIMISM_MINTABLE_ERC20_FACTORY_SLOT | 0xa04c5bb938ca6fc46d95553abf0a76345ce3e722a30bf4f74928b8e7d852320c |
| OPTIMISM_PORTAL_SLOT | 0x4b6c74f9e688cb39801f2112c14a8c57232a3fc5202e1444126d4bce86eb19ac |
| START_BLOCK_SLOT | 0xa11ee3ab75b40e88a0105e935d17cd36c8faee0138320d776c411291bdbbb19f |
| UNSAFE_BLOCK_SIGNER_SLOT | 0x65a7ed542fb37fe237fdfbdd70b31598523fe5b32879e307bae27a0bd9581c08 |

##### `0x16fc5058f25648194471939df75cf27a2fdc48bc` (`OptimismPortal`)

- slot 0x36 (54), `L2OutputOracle l2Oracle`, should be set to `90e9c4f8a994a250f6aefd61cafb4f2e895d458f`, which matches the proxy address
- slot 0x37 (55), `systemConfig`, should be set to `034edd2a225f7f429a63e0f1d2084b9e0a93b538`, which matches the proxy address
- implementation slot should be set to `2d778797049fe9259d947d1ed8e5442226dfb589`, which matches the implementation deployed above

##### `0x58cc85b8d04ea49cc6dbd3cbffd00b4b8d6cb3ef` (`L1CrossDomainMessenger`)

- slot 0xcf (207), `CrossDomainMessenger otherMessenger`, should be set to `4200000000000000000000000000000000000007`
- slot 0xfc (252), `OptimismPortal portal`, should be set to `16fc5058f25648194471939df75cf27a2fdc48bc`whch matches the portal proxy above

##### `0x868d59ff9710159c2b330cc0fbdf57144dd7a13b` (`OptimismMintableERC20Factory`)

- slot 0, initialized slots, should be set to 1
- slot 1, bridge, should be set to `fbb0621e0b23b5478b630bd55a5f21f67730b0f1`(the L1 standard bridge address)
- new value of implementation slot should match the OptimismMintableERC20Factory implementation address above

##### `0x90e9c4f8a994a250f6aefd61cafb4f2e895d458f` (`L2OutputOracle`)

these should all match what’s in the deploy config file

- slot 4, submissionInterval = 0x78 (120)
- slot 5, l2BlockTime = 0x2 (2)
- slot 6, challenger = 0xfd1d2e729ae8eee2e146c033bf4400fe75284301
- slot 7, proposer = 0x49277ee36a024120ee218127354c4a3591dc90a9
- slot 8, finalizationPeriodSeconds = 0xc (12)
- new value of implementation slot should match the L2OO implementation address above

##### `0x9bfe9c5609311df1c011c47642253b78a4f33f4b` (`AddressManager`)

- `addresses[0x3b4a6791a6879d27c0ceeea3f78f8ebe66a01905f4a1290a8c6aff3e85f4665a`] should be changed to `d3494713a5cfad3f5359379dfa074e2ac8c6fd65`, which is the new L1CrossDomainMessenger implementation address
    - verified the key by `cast keccak OVM_L1CrossDomainMessenger`to get the topic we’d expect, then should match that against the event emitted in tenderly

##### `0xd83e03d576d23c9aeab8cc44fa98d058d2176d1f ` (`L1ERC721Bridge`)

- `CrossDomainMessenger messenger` should be set to the Proxy above (`58cc85b8d04ea49cc6dbd3cbffd00b4b8d6cb3ef`)
- `StandardBridge otherBridge` should be set to the predeploy at `0x4200...0014`
- Implementation slot was properly changed to the new implementation above

##### `0xdee57160aafcf04c34c887b5962d0a69676d3c8b` (`GnosisSafeProxy`)

- Nonce bump from 4 to 5

##### `0xfbb0621e0b23b5478b630bd55a5f21f67730b0f1` (`L1StandardBridge`)

- `CrossDomainMessenger messenger` was set to the Proxy above (`58cc85b8d04ea49cc6dbd3cbffd00b4b8d6cb3ef`)
- `StandardBridge otherBridge` should be set to the predeploy at `0x42000010`
- Implementation slot was properly changed to the new implementation above

##### `0x1084092ac2f04c866806cf3d4a385afa4f6a6c97` (`EOA`)

- nonce bump from 4 to 5, this is mark’s signer on the safe