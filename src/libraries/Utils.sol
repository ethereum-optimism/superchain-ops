// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "lib/forge-std/src/Vm.sol";

library Utils {
    VmSafe private constant vm = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));

    /// @notice Helper function to simplify feature-flagging by reading an environment variable
    /// @param _feature The name of the feature flag environment variable to check
    /// @return bool True if the feature is enabled (env var is true or 1), false otherwise
    function isFeatureEnabled(string memory _feature) internal view returns (bool) {
        return vm.envOr(_feature, false) || vm.envOr(_feature, uint256(0)) == 1;
    }
}
