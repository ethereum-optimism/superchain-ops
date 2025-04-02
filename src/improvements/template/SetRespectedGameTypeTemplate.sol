// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";

import {L2TaskBase} from "src/improvements/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";

import {IOptimismPortal2} from "lib/optimism/packages/contracts-bedrock/interfaces/L1/IOptimismPortal2.sol";
import {GameType} from "lib/optimism/packages/contracts-bedrock/src/dispute/lib/Types.sol";

/// @notice This template is used to set the respected game type in the OptimismPortal2 contract
/// for a given chain or set of chains.
/// This works for Optimism monorepo tag: op-contracts/v1.8.0, op-contracts/v2.0.0, op-contracts/v3.0.0-rc.2
/// but not later versions due to changes in the DeputyGuardianModule interface.
contract SetRespectedGameTypeTemplate is L2TaskBase {
    using stdToml for string;

    /// @notice Struct representing configuration for the task.
    struct SetRespectedGameTypeTaskConfig {
        uint256 chainId;
        GameType gameType;
    }

    /// @notice Mapping of chain ID to configuration for the task.
    mapping(uint256 => SetRespectedGameTypeTaskConfig) public cfg;

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

    /// @notice Sets up the template with implementation configurations from a TOML file.
    function _templateSetup(string memory taskConfigFilePath) internal override {
        super._templateSetup(taskConfigFilePath);
        string memory tomlContent = vm.readFile(taskConfigFilePath);
        SetRespectedGameTypeTaskConfig[] memory configs =
            abi.decode(tomlContent.parseRaw(".gameTypes.configs"), (SetRespectedGameTypeTaskConfig[]));
        for (uint256 i = 0; i < configs.length; i++) {
            cfg[configs[i].chainId] = configs[i];
        }
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
            dgm.setRespectedGameType(IOptimismPortal2(payable(portalAddress)), cfg[chainId].gameType);
        }
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        // Iterate over the chains and validate the respected game type.
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            address portalAddress = superchainAddrRegistry.getAddress("OptimismPortalProxy", chainId);
            IOptimismPortal2 portal = IOptimismPortal2(payable(portalAddress));
            assertEq(portal.respectedGameType().raw(), cfg[chainId].gameType.raw());
        }
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function getCodeExceptions() internal pure override returns (address[] memory) {
        address[] memory codeExceptions = new address[](0);
        return codeExceptions;
    }
}

// This is the interface for the DeputyGuardianModule contract at optimism monorepo commit: a10fd5259a3af9a465955b035e16f516327d51d5
interface IDeputyGuardianModule {
    function setRespectedGameType(IOptimismPortal2 portal, GameType gameType) external;
}
