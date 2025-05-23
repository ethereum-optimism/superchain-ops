// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {OptimismPortal2, IDisputeGame} from "@eth-optimism-bedrock/src/L1/OptimismPortal2.sol";
import {Types} from "@eth-optimism-bedrock/scripts/Types.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {LibString} from "solady/utils/LibString.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";

contract SignFromJson is OriginalSignFromJson {
    using LibString for string;

    // Chains for this task.
    string constant l1ChainName = "sepolia";
    string l2ChainName = vm.envString("L2_CHAIN_NAME");

    // Safe contract for this task.
    GnosisSafe securityCouncilSafe = GnosisSafe(payable(0xf64bc17485f0B4Ea5F06A96514182FC4cB561977));
    GnosisSafe foundationSafe = GnosisSafe(payable(0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B));

    // Known EOAs to exclude from safety checks.
    address l2OutputOracleProposer; // cast call $L2OO "PROPOSER()(address)"
    address l2OutputOracleChallenger; // In registry addresses.
    address systemConfigOwner; // In registry addresses.
    address batchSenderAddress; // In registry genesis-system-configs
    address p2pSequencerAddress; // cast call $SystemConfig "unsafeBlockSigner()(address)"
    address batchInboxAddress; // In registry yaml.

    Types.ContractSet proxies;

    /// @notice Sets up the contract
    function setUp() public {
        proxies = _getContractSet();
    }

    function checkRespectedGameType() internal view {
        OptimismPortal2 portal = OptimismPortal2(payable(proxies.OptimismPortal));
        require(portal.respectedGameType().raw() != type(uint32).max);
    }

    function getCodeExceptions() internal view override returns (address[] memory) {
        // Safe owners will appear in storage in the LivenessGuard when added
        address[] memory securityCouncilSafeOwners = securityCouncilSafe.getOwners();
        address[] memory shouldHaveCodeExceptions = new address[](6 + securityCouncilSafeOwners.length);

        shouldHaveCodeExceptions[0] = l2OutputOracleProposer;
        shouldHaveCodeExceptions[1] = l2OutputOracleChallenger;
        shouldHaveCodeExceptions[2] = systemConfigOwner;
        shouldHaveCodeExceptions[3] = batchSenderAddress;
        shouldHaveCodeExceptions[4] = p2pSequencerAddress;
        shouldHaveCodeExceptions[5] = batchInboxAddress;

        for (uint256 i = 0; i < securityCouncilSafeOwners.length; i++) {
            shouldHaveCodeExceptions[6 + i] = securityCouncilSafeOwners[i];
        }

        return shouldHaveCodeExceptions;
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory allowed) {
        allowed = new address[](2);
        allowed[0] = proxies.OptimismPortal;
        allowed[1] = vm.envAddress("OWNER_SAFE");
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory /* simPayload */ )
        internal
        view
        override
    {
        console.log("Running post-deploy assertions");

        checkStateDiff(accesses);
        checkRespectedGameType();

        console.log("All assertions passed!");
    }

    /// @notice Reads the contract addresses from lib/superchain-registry/superchain/configs/${l1ChainName}/${l2ChainName}.toml
    function _getContractSet() internal returns (Types.ContractSet memory _proxies) {
        string memory chainConfig;

        // Read chain-specific config toml file
        string memory path = string.concat(
            "/lib/superchain-registry/superchain/configs/", l1ChainName, "/", l2ChainName, ".toml"
        );
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            chainConfig = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        // Read the known EOAs out of the config toml file
        l2OutputOracleProposer = stdToml.readAddress(chainConfig, "$.addresses.Proposer");
        l2OutputOracleChallenger = stdToml.readAddress(chainConfig, "$.addresses.Challenger");
        systemConfigOwner = stdToml.readAddress(chainConfig, "$.addresses.SystemConfigOwner");
        batchSenderAddress = stdToml.readAddress(chainConfig, "$.addresses.BatchSubmitter");
        p2pSequencerAddress = stdToml.readAddress(chainConfig, "$.addresses.UnsafeBlockSigner");
        batchInboxAddress = stdToml.readAddress(chainConfig, "$.batch_inbox_addr");

        // Read the chain-specific OptimismPortalProxy address
        _proxies.OptimismPortal = stdToml.readAddress(chainConfig, "$.addresses.OptimismPortalProxy");
    }
}
