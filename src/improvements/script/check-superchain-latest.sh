#!/bin/bash

# Attempt to automatically determine the repository's root directory.
# If not inside a Git repo, this will fail.
ROOT_DIR=$(git rev-parse --show-toplevel 2>/dev/null)

if [ -z "$ROOT_DIR" ]; then
    echo "Error: Not inside a Git repository. Please run this script from within a repository."
    exit 1
fi

check_superchain_hash() {
    local ADDRESSES_PATH="${ROOT_DIR}/lib/superchain-registry/superchain/extra/addresses/addresses.json"
    local HASH_FILE_PATH="${ROOT_DIR}/hash.txt"

    if [ -f "$HASH_FILE_PATH" ]; then
        if [ ! -f "$ADDRESSES_PATH" ]; then
            echo "Error: File not found at $ADDRESSES_PATH"
            exit 1
        fi

        local NEW_HASH
        NEW_HASH=$(sha256sum "$ADDRESSES_PATH" | awk '{ print $1 }')
        local OLD_HASH
        OLD_HASH=$(cat "$HASH_FILE_PATH")

        if [ "$NEW_HASH" == "$OLD_HASH" ]; then
            echo "Hashes match: superchain-registry is up to date."
        else
            echo "Hashes do not match: superchain-registry is not up to date."
            exit 1
        fi
    else
        if [ ! -f "$ADDRESSES_PATH" ]; then
            echo "Error: File not found at $ADDRESSES_PATH"
            exit 1
        fi

        local HASH
        HASH=$(sha256sum "$ADDRESSES_PATH" | awk '{ print $1 }')
        echo "$HASH" > "$HASH_FILE_PATH"
        echo "Hash has been written to $HASH_FILE_PATH"
    fi
}

check_superchain_hash
