// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Test} from "forge-std/Test.sol";
import {DeployFeesDepositor} from "src/template/DeployFeesDepositor.sol";

/// @notice Test contract for the DeployFeesDepositor that expect reverts on misconfiguration of required fields.
contract DeployFeesDepositorRequiredFieldsTest is Test {
    DeployFeesDepositor public template;

    function setUp() public {
        vm.createSelectFork("mainnet", 23197819);
        template = new DeployFeesDepositor();
    }

    /// @notice Tests that the template reverts when the salt is an empty string.
    function test_deployFeesDepositor_salt_empty_string_reverts() public {
        string memory configPath = "test/template/deploy-fees-depositor/config/salt-empty-string-config.toml";
        vm.expectRevert("salt must be set");
        template.simulate(configPath);
    }

    /// @notice Tests that the template reverts when the l2Recipient is a zero address.
    function test_deployFeesDepositor_l2Recipient_zero_address_reverts() public {
        string memory configPath = "test/template/deploy-fees-depositor/config/l2Recipient-zero-address-config.toml";
        vm.expectRevert("l2Recipient must be set");
        template.simulate(configPath);
    }

    /// @notice Tests that the template reverts when the portal is a zero address.
    function test_deployFeesDepositor_portal_zero_address_reverts() public {
        string memory configPath = "test/template/deploy-fees-depositor/config/portal-zero-address-config.toml";
        vm.expectRevert("portal must be set");
        template.simulate(configPath);
    }

    /// @notice Tests that the template reverts when the gasLimit is zero.
    function test_deployFeesDepositor_gasLimit_zero_reverts() public {
        string memory configPath = "test/template/deploy-fees-depositor/config/gasLimit-zero-config.toml";
        vm.expectRevert("gasLimit must be set");
        template.simulate(configPath);
    }

    /// @notice Tests that the template reverts when the gasLimit is too high.
    function test_deployFeesDepositor_gasLimit_too_high_reverts() public {
        string memory configPath = "test/template/deploy-fees-depositor/config/gasLimit-too-high-config.toml";
        vm.expectRevert("gasLimit must be less than uint32.max");
        template.simulate(configPath);
    }

    /// @notice Tests that the template reverts when the proxyAdminOwner is a zero address.
    function test_deployFeesDepositor_proxyAdminOwner_zero_address_reverts() public {
        string memory configPath = "test/template/deploy-fees-depositor/config/proxyAdminOwner-zero-address-config.toml";
        vm.expectRevert("SimpleAddressRegistry: zero address for ProxyAdminOwner");
        template.simulate(configPath);
    }
}
