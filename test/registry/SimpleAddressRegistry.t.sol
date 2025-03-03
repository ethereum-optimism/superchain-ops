// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {SimpleAddressRegistry} from "src/improvements/SimpleAddressRegistry.sol";
import {stdJson} from "forge-std/StdJson.sol";

contract SimpleAddressRegistryTest is Test {
    // Test addresses
    address constant alice = address(1);
    address constant bob = address(2);
    address constant charlie = address(3);

    // Path to test fixture files
    string constant FIXTURES_PATH = "test/fixtures/SimpleAddressRegistry/";

    string registryName; // Contract name being tested.
    string idReturnKind; // "identifier" or "AddressInfo"

    function setUp() public virtual {
        registryName = "SimpleAddressRegistry";
        idReturnKind = "identifier";
    }

    // Helper function to read TOML from fixture file
    function _getPath(string memory configFile) internal pure returns (string memory) {
        return string.concat(FIXTURES_PATH, configFile);
    }

    function _deployRegistry(string memory configFile) internal virtual returns (address) {
        return address(new SimpleAddressRegistry(_getPath(configFile)));
    }

    function test_initialize_succeeds_withValidToml() public {
        SimpleAddressRegistry registry = SimpleAddressRegistry(_deployRegistry("valid_addresses.toml"));
        assertEq(registry.get("Alice"), alice, "10");
        assertEq(registry.get("Bob"), bob, "20");
    }

    function test_initialize_succeeds_withEmptyToml() public {
        // Nothing to assert, just ensure it doesn't revert.
        SimpleAddressRegistry(_deployRegistry("empty_addresses.toml"));
    }

    function test_initialize_succeeds_withMissingAddressesSection() public {
        SimpleAddressRegistry(_deployRegistry("missing_addresses_section.toml"));
    }

    function test_initialize_succeeds_withMixedCaseNames() public {
        SimpleAddressRegistry registry = SimpleAddressRegistry(_deployRegistry("mixed_case_names.toml"));
        assertEq(registry.get("MixedCase"), alice);
        assertEq(registry.get("mixedCase"), bob);
    }

    function test_initialize_reverts_withInvalidAddressFormat() public {
        vm.expectRevert(); // Error message is from forge, so we don't check it.
        SimpleAddressRegistry(_deployRegistry("invalid_address_format.toml"));
    }

    function test_initialize_reverts_withDuplicateNames() public {
        // This is not valid TOML so most parsers will fail, so this is just a sanity check.
        vm.expectRevert(); // Error message is from forge, so we don't check it.
        SimpleAddressRegistry(_deployRegistry("duplicate_names.toml"));
    }

    function test_initialize_reverts_withZeroAddress() public {
        vm.expectRevert(bytes(string.concat(registryName, ": zero address for Alice")));
        SimpleAddressRegistry(_deployRegistry("zero_address.toml"));
    }

    function test_get_reverts_withNonExistentName() public {
        SimpleAddressRegistry registry = SimpleAddressRegistry(_deployRegistry("valid_addresses.toml"));

        // For simplicity, due to differences in the SimpleAddressRegistry and SuperchainAddressRegistry
        // error messages, we just check that it reverts.
        vm.expectRevert();
        registry.get("NonExistent");
    }

    function test_get_reverts_withNonExistentAddress() public {
        SimpleAddressRegistry registry = SimpleAddressRegistry(_deployRegistry("valid_addresses.toml"));

        string memory err =
            string.concat(registryName, ": ", idReturnKind, " not found for 0x0000000000000000000000000000000000000000");
        vm.expectRevert(bytes(err));
        registry.get(address(0));

        err =
            string.concat(registryName, ": ", idReturnKind, " not found for 0x0000000000000000000000000000000000000005");
        vm.expectRevert(bytes(err));
        registry.get(address(5));
    }
}
