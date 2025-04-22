#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Run noncey.py using uv
uv run "$SCRIPT_DIR/noncey.py" "$@" 