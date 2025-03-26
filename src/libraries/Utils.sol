// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "lib/forge-std/src/Vm.sol";

library Utils {
    VmSafe private constant vm = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));

    function isFeatureEnabled(string memory _feature) internal view returns (bool) {
        return vm.envOr(_feature, false) || vm.envOr(_feature, uint256(0)) == 1;
    }
}
