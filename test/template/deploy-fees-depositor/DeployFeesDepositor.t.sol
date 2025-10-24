// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Test} from "forge-std/Test.sol";
import {DeployFeesDepositor, IFeesDepositor} from "src/template/DeployFeesDepositor.sol";
import {Action} from "src/libraries/MultisigTypes.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {Proxy} from "optimism/packages/contracts-bedrock/src/universal/Proxy.sol";
import {RevShareCodeRepo} from "src/libraries/RevShareCodeRepo.sol";
import {IProxyAdmin} from "optimism/packages/contracts-bedrock/interfaces/universal/IProxyAdmin.sol";

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

    /// @notice Tests that the template reverts when the ProxyAdmin is a zero address.
    function test_deployFeesDepositor_proxyAdmin_zero_address_reverts() public {
        string memory configPath = "test/template/deploy-fees-depositor/config/proxyAdmin-zero-address-config.toml";
        vm.expectRevert("proxyAdmin must be set");
        template.simulate(configPath);
    }
}

/// @notice Test contract for successful deployment of the FeesDepositor template.
contract DeployFeesDepositorSuccessTest is Test {
    DeployFeesDepositor public template;

    // Expected configuration values from valid-config.toml
    string public constant SALT = "test-fees-depositor";
    uint96 public constant MIN_DEPOSIT_AMOUNT = 5000000000000000000;
    address public constant L2_RECIPIENT = 0x0000000000000000000000000000000000000001;
    address public constant PORTAL = 0xbEb5Fc579115071764c7423A4f12eDde41f106Ed;
    uint32 public constant GAS_LIMIT = 300000;
    address public constant PROXY_ADMIN = 0x543bA4AADBAb8f9025686Bd03993043599c6fB04;
    address public constant PROXY_ADMIN_OWNER = 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A;
    address internal constant CREATE2_DEPLOYER = address(0x13b0D85CcB8bf860b6b79AF3029fCA081AE9beF2);

    string public constant configPath = "test/template/deploy-fees-depositor/config/valid-config.toml";

    function setUp() public {
        vm.createSelectFork("mainnet", 23197819);
        template = new DeployFeesDepositor();
    }

    /// @notice Tests successful deployment and initialization of FeesDepositor
    function test_deployFeesDepositor_succeds() public {
        // Execute the simulation
        (, Action[] memory actions,, address rootSafe) = template.simulate(configPath, new address[](0));

        // Verify the root safe is correct
        assertEq(rootSafe, PROXY_ADMIN_OWNER, "Root safe should be ProxyAdminOwner");

        // Verify actions were created (should have 3: deploy impl, deploy proxy, upgradeAndCall)
        assertGt(actions.length, 0, "Should have at least one action");

        // Calculate expected deployed addresses using the same logic as the template
        bytes memory proxyInitCode = bytes.concat(type(Proxy).creationCode, abi.encode(PROXY_ADMIN));
        address proxyAddress = Create2.computeAddress(bytes32(bytes(SALT)), keccak256(proxyInitCode), CREATE2_DEPLOYER);
        address implAddress = Create2.computeAddress(
            bytes32(bytes(SALT)), keccak256(RevShareCodeRepo.feesDepositorCreationCode), CREATE2_DEPLOYER
        );

        // Verify both contracts were deployed
        assertTrue(proxyAddress.code.length > 0, "Proxy should be deployed");
        assertTrue(implAddress.code.length > 0, "Implementation should be deployed");

        // Verify proxy was initialized with correct values
        IFeesDepositor feesDepositor = IFeesDepositor(payable(proxyAddress));
        assertEq(feesDepositor.minDepositAmount(), MIN_DEPOSIT_AMOUNT, "minDepositAmount should match config");
        assertEq(feesDepositor.l2Recipient(), L2_RECIPIENT, "l2Recipient should match config");
        assertEq(feesDepositor.gasLimit(), GAS_LIMIT, "gasLimit should match config");

        // Verify the template's public variables were set correctly
        assertEq(template.salt(), SALT, "Salt should match config");
        assertEq(template.l2Recipient(), L2_RECIPIENT, "l2Recipient should match config");
        assertEq(template.minDepositAmount(), MIN_DEPOSIT_AMOUNT, "minDepositAmount should match config");
        assertEq(template.portal(), PORTAL, "portal should match config");
        assertEq(template.gasLimit(), GAS_LIMIT, "gasLimit should match config");
        assertEq(template.proxyAdmin(), PROXY_ADMIN, "proxyAdmin should match config");
    }
}
