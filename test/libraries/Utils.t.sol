// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Test} from "forge-std/Test.sol";
import {Utils} from "src/libraries/Utils.sol";

contract UtilsTest is Test {
    function test_isFeatureEnabled() public {
        string memory randomFeature = "RANDOM_FEATURE";
        assertEq(Utils.isFeatureEnabled(randomFeature), false);

        // Set it to true
        vm.setEnv(randomFeature, "true");
        assertEq(Utils.isFeatureEnabled(randomFeature), true);

        // Set it to false
        vm.setEnv(randomFeature, "false");
        assertEq(Utils.isFeatureEnabled(randomFeature), false);

        // Set it to a non-boolean value
        vm.setEnv(randomFeature, vm.toString(vm.randomBytes(bound(vm.randomUint(), 1, 10))));
        assertEq(Utils.isFeatureEnabled(randomFeature), false);

        // Set it to 1
        vm.setEnv(randomFeature, "1");
        assertEq(Utils.isFeatureEnabled(randomFeature), true);

        // Set it to 0
        vm.setEnv(randomFeature, "0");
        assertEq(Utils.isFeatureEnabled(randomFeature), false);

        // Set it to a number > 1
        vm.setEnv(randomFeature, vm.toString(bound(vm.randomUint(), 2, type(uint256).max)));
        assertEq(Utils.isFeatureEnabled(randomFeature), false);
    }
}
