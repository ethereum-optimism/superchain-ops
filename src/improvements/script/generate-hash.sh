#!/bin/bash

# Define the path to the JSON file
ADDRESSES_PATH="lib/superchain-registry/superchain/extra/addresses/addresses.json"

# Check if the file exists
if [ ! -f "$ADDRESSES_PATH" ]; then
    echo "Error: File not found at $ADDRESSES_PATH"
    exit 1
fi

# Compute the SHA-256 hash of the file
HASH=$(sha256sum "$ADDRESSES_PATH" | awk '{ print $1 }')

# Write the hash to a file
echo "$HASH" > hash.txt

echo "Hash has been written to hash.txt"