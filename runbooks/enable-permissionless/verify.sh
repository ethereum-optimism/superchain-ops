#!/usr/bin/env bash
set -euo pipefail

OPTIMISM_PORTAL_PROXY=0x5d66c1782664115999c47c9fa5cd031f495d3e4f

cat << EOF
**OptimismPortalProxy ($OPTIMISM_PORTAL_PROXY)**

    - Key: 0x000000000000000000000000000000000000000000000000000000000000003b
    - Value: 0x00000000000000000000000000000000000000000000000TIMESTAMP00000000
    - Description: Sets the respectedGameType to 0 (permissionless cannon game) and sets the respectedGameTypeUpdatedAt timestamp to the time when the upgrade transaction was executed (will be a dynamic value)
EOF
