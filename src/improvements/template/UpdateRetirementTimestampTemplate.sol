// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {
    IDeputyGuardianModule,
    IOptimismPortal2
} from "lib/optimism/packages/contracts-bedrock/interfaces/safe/IDeputyGuardianModule.sol";
import {GameType} from "lib/optimism/packages/contracts-bedrock/src/dispute/lib/Types.sol";

import {L2TaskBase} from "src/improvements/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// @title UpdateRetirementTimestampTemplate
/// @notice This template is used to update the retirement timestamp in the OptimismPortal2
///         contract for a given chain or set of chains.
contract UpdateRetirementTimestampTemplate is L2TaskBase {
    using stdToml for string;

    /// @notice Returns the string identifier for the safe executing this transaction.
    function safeAddressString() public pure override returns (string memory) {
        return "FoundationOperationsSafe";
    }

    /// @notice Returns string identifiers for addresses that are expected to have their storage written to.
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        string[] memory storageWrites = new string[](3);
        storageWrites[0] = "DeputyGuardianModule";
        storageWrites[1] = "Guardian";
        storageWrites[2] = "OptimismPortalProxy";
        return storageWrites;
    }

    /// @notice Write the calls that you want to execute for the task.
    function _build() internal override {
        // Load the DeputyGuardianModule contract.
        IDeputyGuardianModule dgm = IDeputyGuardianModule(superchainAddrRegistry.get("DeputyGuardianModule"));

        // Iterate over the chains and set the respected game type.
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            address portalAddress = superchainAddrRegistry.getAddress("OptimismPortalProxy", chainId);
            dgm.setRespectedGameType(IOptimismPortal2(payable(portalAddress)), GameType.wrap(type(uint32).max));
        }
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        // Iterate over the chains and validate the retirement timestamp.
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            address portalAddress = superchainAddrRegistry.getAddress("OptimismPortalProxy", chainId);
            IOptimismPortal2 portal = IOptimismPortal2(payable(portalAddress));
            assertEq(portal.respectedGameTypeUpdatedAt(), block.timestamp);
        }
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function getCodeExceptions() internal pure override returns (address[] memory) {
        address[] memory codeExceptions = new address[](0);
        return codeExceptions;
    }
}
