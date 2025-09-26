// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {Predeploys} from "@eth-optimism-bedrock/src/libraries/Predeploys.sol";

import {L2TaskBase} from "src/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// @notice Template contract to transfer ownership of the L2 ProxyAdmin to an EOA address.
/// This template is used when the L2 ProxyAdmin is currently held by a multisig (e.g., 2/2 safe)
/// and needs to be transferred to an EOA. The transfer is executed via L1 using the OptimismPortal
/// deposit transaction mechanism.
/// See: https://docs.optimism.io/stack/transactions/deposit-flow
///
/// ATTENTION: Use caution when using this template — transferring ownership is high risk.
/// To gain additional assurance that the corresponding L2 deposit transaction works as expected,
/// you must follow the steps outlined in the documentation: ../doc/simulate-l2-ownership-transfer.md
/// Add the results of the simulation to the VALIDATION.md file for the task.
///
/// Manual Post-Execution checks to follow when executing this task:
/// 1. Find the L2 deposit transaction sent from the L1 caller.
/// 2. The transaction should be interacting with the L2 ProxyAdmin at 0x4200000000000000000000000000000000000018.
/// 3. Verify that the OwnershipTransferred event was emitted with the correct new EOA owner.
contract TransferL2PAOFromL1ToEOA is L2TaskBase {
    using stdToml for string;

    /// @notice The new owner EOA address.
    address public newOwnerEOA;

    /// @notice Returns the safe address string identifier
    function safeAddressString() public pure override returns (string memory) {
        return "ProxyAdminOwner";
    }

    /// @notice Returns the storage write permissions required for this task.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "OptimismPortalProxy";
        return storageWrites;
    }

    /// @notice Sets up the template with the new EOA owner from a TOML file.
    function _templateSetup(string memory taskConfigFilePath, address rootSafe) internal override {
        super._templateSetup(taskConfigFilePath, rootSafe);
        string memory toml = vm.readFile(taskConfigFilePath);

        // New owner EOA address.
        newOwnerEOA = abi.decode(vm.parseToml(toml, ".newOwnerEOA"), (address));
        require(newOwnerEOA != address(0), "newOwnerEOA must be non-zero address");
        SuperchainAddressRegistry.ChainInfo[] memory _chains = superchainAddrRegistry.getChains();
        require(_chains.length == 1, "Must specify exactly one chain id to transfer ownership for");
    }

    /// @notice Builds the actions for transferring ownership of the proxy admin on the L2 to an EOA.
    /// It does this by calling the L1 OptimismPortal's depositTransaction function.
    function _build(address) internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        // See this Tenderly simulation for an example of this gas limit working: https://www.tdly.co/shared/simulation/d5028138-469c-4bb2-97fd-50f5f4bb8515
        uint64 gasLimit = 200000;
        OptimismPortal optimismPortal =
            OptimismPortal(superchainAddrRegistry.getAddress("OptimismPortalProxy", chains[0].chainId));
        optimismPortal.depositTransaction(
            address(Predeploys.PROXY_ADMIN),
            0,
            gasLimit,
            false,
            abi.encodeCall(ProxyAdmin.transferOwnership, (newOwnerEOA))
        );
    }

    /// @notice Validates that the owner was transferred correctly.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory actions, address) internal view override {
        // Validate that the depositTransaction action was created correctly
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        address expectedPortal = superchainAddrRegistry.getAddress("OptimismPortalProxy", chains[0].chainId);

        // Expected calldata for depositTransaction
        uint64 gasLimit = 200000;
        bytes memory expectedCalldata = abi.encodeCall(
            OptimismPortal.depositTransaction,
            (
                address(Predeploys.PROXY_ADMIN), // _to
                0, // _value
                gasLimit, // _gasLimit
                false, // _isCreation
                abi.encodeCall(ProxyAdmin.transferOwnership, (newOwnerEOA)) // _data
            )
        );

        // Check that we have exactly one action to the OptimismPortal with the expected calldata
        bool found = false;
        uint256 matches = 0;
        for (uint256 i = 0; i < actions.length; i++) {
            if (actions[i].target == expectedPortal) {
                if (keccak256(actions[i].arguments) == keccak256(expectedCalldata)) {
                    found = true;
                    matches++;
                }
                assertEq(actions[i].value, 0, "Should not send ETH with depositTransaction");
            }
        }

        assertTrue(found, "depositTransaction action not found");
        assertEq(matches, 1, "Should have exactly one depositTransaction action");

        // Note: We can't validate the L2 state change since it only happens after L1 execution
        // Manual verification steps are documented in the contract comments above
    }

    /// @notice No code exceptions for this template.
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {}
}

interface OptimismPortal {
    function depositTransaction(address _to, uint256 _value, uint64 _gasLimit, bool _isCreation, bytes memory _data)
        external
        payable;
}

interface ProxyAdmin {
    function owner() external view returns (address);
    function transferOwnership(address newOwner) external;
}
