#!/bin/bash

# Path to the addresses.json file
ADDRESSES_PATH="lib/superchain-registry/superchain/extra/addresses/addresses.json"

# Path to the hash.txt file
HASH_FILE="hash.txt"

# Calculate the new hash of the addresses.json file
NEW_HASH=$(sha256sum "$ADDRESSES_PATH" | awk '{ print $1 }')

# Read the old hash from the hash.txt file
OLD_HASH=$(cat "$HASH_FILE")

# Compare the hashes
if [ "$NEW_HASH" == "$OLD_HASH" ]; then
    echo "Hashes match: superchain-registry is up to date."
else
    echo "Hashes do not match: superchain-registry is not up to date."
    exit 1
fi  