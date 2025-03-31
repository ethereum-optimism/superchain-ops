// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Test} from "forge-std/Test.sol";
import {Utils} from "src/libraries/Utils.sol";

contract UtilsTest is Test {
    function test_isFeatureEnabled() public {
        string memory randomFeature = "RANDOM_FEATURE";
        assertEq(Utils.isFeatureEnabled(randomFeature), false);

        // Set it to true
        setAndAssert(randomFeature, "true", true);
        setAndAssert(randomFeature, "True", true);
        setAndAssert(randomFeature, "TRUE", true);

        // Boolean with whitespace around it
        setAndAssert(randomFeature, " true ", false);

        // Set it to false
        setAndAssert(randomFeature, "false", false);
        setAndAssert(randomFeature, "False", false);
        setAndAssert(randomFeature, "FALSE", false);

        // Empty string
        setAndAssert(randomFeature, "", false);

        // Set it to a non-boolean value
        setAndAssert(randomFeature, vm.toString(vm.randomBytes(bound(vm.randomUint(), 1, 10))), false);

        // Set it to 1
        setAndAssert(randomFeature, "1", true);

        // Set it to 0
        setAndAssert(randomFeature, "0", false);

        // Set it to a number > 1
        setAndAssert(randomFeature, vm.toString(bound(vm.randomUint(), 2, type(uint256).max)), false);

        // Hex input
        setAndAssert(randomFeature, "0x1", true);

        // Number prefixed with 0
        setAndAssert(randomFeature, "01", true);
    }

    function setAndAssert(string memory feature, string memory value, bool expected) internal {
        vm.setEnv(feature, value);
        assertEq(Utils.isFeatureEnabled(feature), expected);
    }
}
