The VALIDATIONS.md file should include the domain hash and message hash in a toml block, headed by [validation_hashes] and ended by two blank lines. Inside [validation_hashes] you should have a block named after each safe to simulate, with the `domain_hash` and `message_hash` keys.


[validation_hashes]
[foundation]
domain_hash = "0x96c653b6193d04eb71ad87ac1577524661acf1e1e0c492a68c88a1deb059927f"
message_hash = "0xb6525061ebd285287cc9f758bd19fde972f4a8054fe4d154b8e8e3fe9ae86232"

