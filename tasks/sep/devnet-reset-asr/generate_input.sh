#!/usr/bin/env bash

source .env
forge script ./asr_initialize.s.sol -f $FORK_URL | tail -n1 | jq > ./input.json
