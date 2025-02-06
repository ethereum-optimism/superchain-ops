#!/bin/bash

# Path to the addresses.json file
ADDRESSES_PATH="lib/superchain-registry/superchain/extra/addresses/addresses.json"

# Path to the hash.txt file
HASH_FILE_PATH="hash.txt"

# Check if the file exists
if [ -f "$HASH_FILE_PATH" ]; then
    # Check if the addresses.json file exists
    if [ ! -f "$ADDRESSES_PATH" ]; then
        echo "Error: File not found at $ADDRESSES_PATH"
        exit 1
    fi

    # Calculate the new hash of the addresses.json file
    NEW_HASH=$(sha256sum "$ADDRESSES_PATH" | awk '{ print $1 }')

    # Read the old hash from the hash.txt file
    OLD_HASH=$(cat "$HASH_FILE_PATH")

    # Compare the hashes
    if [ "$NEW_HASH" == "$OLD_HASH" ]; then
        echo "Hashes match: superchain-registry is up to date."
    else
        echo "Hashes do not match: superchain-registry is not up to date."
        exit 1
    fi
else
    # Check if the addresses.json file exists
    if [ ! -f "$ADDRESSES_PATH" ]; then
        echo "Error: File not found at $ADDRESSES_PATH"
        exit 1
    fi

    # Compute the SHA-256 hash of the file
    HASH=$(sha256sum "$ADDRESSES_PATH" | awk '{ print $1 }')

    # Write the hash to a file
    echo "$HASH" > hash.txt

    echo "Hash has been written to hash.txt"
fi