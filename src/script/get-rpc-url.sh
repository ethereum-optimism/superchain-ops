#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${OVERRIDE_RPC_URL:-}" ]]; then
    echo "$OVERRIDE_RPC_URL"
    exit 0
fi

case "${1:-}" in
    eth)
        echo "mainnet"
        ;;
    sep)
        echo "sepolia"
        ;;
    oeth)
        echo "opMainnet"
        ;;
    opsep)
        echo "opSepolia"
        ;;
    "")
        echo "Error: Must provide a network (eth|sep|oeth|opsep)" >&2
        exit 1
        ;;
    *)
        echo "Error: Invalid network '$1' (use eth|sep|oeth|opsep)" >&2
        exit 1
        ;;
esac
