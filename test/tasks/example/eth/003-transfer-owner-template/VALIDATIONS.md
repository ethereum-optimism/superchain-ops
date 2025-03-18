The VALIDATIONS.md file should include the domain hash and message hash in a toml block, headed by [validation_hashes] and ended by two blank lines. Inside [validation_hashes] you should have a block named after each safe to simulate, with the `domain_hash` and `message_hash` keys.

[validation_hashes]
[foundation]
domain_hash = "0xdaf670b31fdf41fdaae2643ed0ebe709283539c0e61540c160b5a6403d79073f"
message_hash = "0xdabf3ec1557117959ae0c54078c8de1c5c3de641bef7f88c08b1f85cf39fbd43"
[council]
domain_hash = "0xdaf670b31fdf41fdaae2643ed0ebe709283539c0e61540c160b5a6403d79073f"
message_hash = "0xdabf3ec1557117959ae0c54078c8de1c5c3de641bef7f88c08b1f85cf39fbd43"
