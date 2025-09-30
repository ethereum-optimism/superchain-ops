// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Test} from "forge-std/Test.sol";
import {Utils} from "src/libraries/Utils.sol";
import {MockXDeployer} from "test/mock/MockXDeployer.sol";

contract UtilsTest is Test {
    using Utils for address[];

    function test_getCreate2Address(uint256 _saltSeed) public {
        bytes32 salt = bytes32(uint256(_saltSeed));
        bytes memory initCode = abi.encode(0x6080);
        MockXDeployer deployer = new MockXDeployer();
        address create2Address = Utils.getCreate2Address(salt, initCode, address(deployer));
        assertEq(create2Address, deployer.deploy(0, salt, initCode));
    }

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

    function test_contains_EmptyArray() public pure {
        address[] memory emptyArray = new address[](0);
        address testAddr = address(0x1234567890123456789012345678901234567890);

        bool result = Utils.contains(emptyArray, testAddr);
        assertFalse(result, "Empty array should not contain any address");
    }

    function test_contains_SingleElementArray() public pure {
        address testAddr = address(0x1234567890123456789012345678901234567890);
        address[] memory singleElementArray = new address[](1);
        singleElementArray[0] = testAddr;

        bool result = Utils.contains(singleElementArray, testAddr);
        assertTrue(result, "Array should contain the address that was added");

        address differentAddr = address(0x0987654321098765432109876543210987654321);
        result = Utils.contains(singleElementArray, differentAddr);
        assertFalse(result, "Array should not contain a different address");
    }

    function test_contains_MultipleElementArray() public pure {
        address addr1 = address(0x1111111111111111111111111111111111111111);
        address addr2 = address(0x2222222222222222222222222222222222222222);
        address addr3 = address(0x3333333333333333333333333333333333333333);

        address[] memory multiElementArray = new address[](3);
        multiElementArray[0] = addr1;
        multiElementArray[1] = addr2;
        multiElementArray[2] = addr3;

        bool result = Utils.contains(multiElementArray, addr1);
        assertTrue(result, "Array should contain the first address");
        result = Utils.contains(multiElementArray, addr2);
        assertTrue(result, "Array should contain the middle address");
        result = Utils.contains(multiElementArray, addr3);
        assertTrue(result, "Array should contain the last address");

        address nonExistentAddr = address(0x4444444444444444444444444444444444444444);
        result = Utils.contains(multiElementArray, nonExistentAddr);
        assertFalse(result, "Array should not contain a non-existent address");
    }

    function test_contains_String_EmptyArray() public pure {
        string[] memory emptyArray = new string[](0);
        string memory testStr = "test";

        bool result = Utils.contains(emptyArray, testStr);
        assertFalse(result, "Empty string array should not contain any string");
    }

    function test_contains_String_SingleElementArray() public pure {
        string memory testStr = "hello";
        string[] memory singleElementArray = new string[](1);
        singleElementArray[0] = testStr;

        bool result = Utils.contains(singleElementArray, testStr);
        assertTrue(result, "String array should contain the string that was added");

        string memory differentStr = "world";
        result = Utils.contains(singleElementArray, differentStr);
        assertFalse(result, "String array should not contain a different string");
    }

    function test_contains_String_MultipleElementArray() public pure {
        string memory str1 = "apple";
        string memory str2 = "banana";
        string memory str3 = "cherry";

        string[] memory multiElementArray = new string[](3);
        multiElementArray[0] = str1;
        multiElementArray[1] = str2;
        multiElementArray[2] = str3;

        bool result = Utils.contains(multiElementArray, str1);
        assertTrue(result, "String array should contain the first string");

        result = Utils.contains(multiElementArray, str2);
        assertTrue(result, "String array should contain the middle string");

        result = Utils.contains(multiElementArray, str3);
        assertTrue(result, "String array should contain the last string");

        string memory nonExistentStr = "orange";
        result = Utils.contains(multiElementArray, nonExistentStr);
        assertFalse(result, "String array should not contain a non-existent string");
    }

    function test_contains_String_EmptyString() public pure {
        string memory emptyStr = "";
        string[] memory array = new string[](2);
        array[0] = "hello";
        array[1] = emptyStr;

        bool result = Utils.contains(array, emptyStr);
        assertTrue(result, "String array should contain empty string");

        result = Utils.contains(array, array[0]);
        assertTrue(result, "String array should contain non-empty string");
    }

    /// @notice Using Base mainnet safe architecture to test the order function.
    function test_validateSafesOrder() public {
        vm.createSelectFork("mainnet", 23147844);
        address[] memory safes = new address[](3);
        safes[0] = address(0x20AcF55A3DCfe07fC4cecaCFa1628F788EC8A4Dd); // BaseSCSafe
        safes[1] = address(0x9855054731540A48b28990B63DcF4f33d8AE46A1); // BaseNestedSafe
        safes[2] = address(0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c); // Base L1PAO
        safes.validateSafesOrder();
    }

    /// @notice Test validateSafesOrder with invalid order.
    function test_validateSafesOrder_InvalidOrder() public {
        vm.createSelectFork("mainnet", 23147844);
        address[] memory safes = new address[](2);
        safes[0] = address(0x9855054731540A48b28990B63DcF4f33d8AE46A1); // BaseNestedSafe
        safes[1] = address(0x20AcF55A3DCfe07fC4cecaCFa1628F788EC8A4Dd); // BaseSCSafe
        UtilsHarness utilsHarness = new UtilsHarness();
        vm.expectRevert(
            "Utils: Safe 0x9855054731540A48b28990B63DcF4f33d8AE46A1 is not an owner of 0x20AcF55A3DCfe07fC4cecaCFa1628F788EC8A4Dd"
        );
        utilsHarness.exposed_validateSafesOrder(safes);
    }

    /// @notice Test validateSafesOrder with no safes.
    /// forge-config: default.allow_internal_expect_revert = true
    function test_validateSafesOrder_NoSafes() public {
        address[] memory safes = new address[](0);
        vm.expectRevert("Utils: no safes provided");
        safes.validateSafesOrder();
    }

    function setAndAssert(string memory feature, string memory value, bool expected) internal {
        vm.setEnv(feature, value);
        assertEq(Utils.isFeatureEnabled(feature), expected);
    }
}

contract UtilsHarness {
    using Utils for address[];
    /// @notice Must use this harness for when validateSafesOrder is called and reverts with
    /// owner check. Technically the 'next' call doesn't revert so we need the harness.

    function exposed_validateSafesOrder(address[] memory _allSafes) public view {
        return _allSafes.validateSafesOrder();
    }
}
