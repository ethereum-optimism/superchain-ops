The VALIDATIONS.md file should include the domain hash and message hash in a toml block, headed by [validation_hashes] and ended by two blank lines. Inside [validation_hashes] you should have a block named after each safe to simulate, with the `domain_hash` and `message_hash` keys.


[validation_hashes]
[council]
domain_hash = "0xe84ad8db37faa1651b140c17c70e4c48eaa47a635e0db097ddf4ce1cc14b9ecb"
message_hash = "0xf55e2ed894ddff4c0045537c8239db1c4b3ac5700049164b5823ecaa045d7334"

