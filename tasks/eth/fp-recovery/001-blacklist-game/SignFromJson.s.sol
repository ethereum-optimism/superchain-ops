// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {OptimismPortal2, IDisputeGame} from "@eth-optimism-bedrock/src/L1/OptimismPortal2.sol";
import {Types} from "@eth-optimism-bedrock/scripts/Types.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {LibString} from "solady/utils/LibString.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";

contract SignFromJson is OriginalSignFromJson {
    using LibString for string;

    // Chains for this task.
    string constant l1ChainName = "mainnet";
    string l2ChainName = vm.envString("L2_CHAIN_NAME");

    Types.ContractSet proxies;

    /// @notice Sets up the contract
    function setUp() public {
        proxies = _getContractSet();
    }

    function checkBlacklisted() internal view {
        // Read the OptimismPortalProxy and dispute game that is to be blacklisted from the input JSON.
        string memory inputJson;
        string memory path = "/tasks/eth/fp-recovery/001-blacklist-game/input.json";
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            inputJson = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        OptimismPortal2 portal = OptimismPortal2(payable(stdJson.readAddress(inputJson, "$.transactions[0].contractInputsValues._portal")));
        address blacklistedGame = stdJson.readAddress(inputJson, "$.transactions[0].contractInputsValues._game");
        require(portal.disputeGameBlacklist(IDisputeGame(blacklistedGame)), "Dispute game is not blacklisted");
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory allowed) {
        allowed = new address[](2);
        allowed[0] = proxies.OptimismPortal;
        allowed[1] = vm.envAddress("OWNER_SAFE");
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory accesses, SimulationPayload memory /* simPayload */ )
        internal
        view
        override
    {
        console.log("Running post-deploy assertions");

        checkStateDiff(accesses);
        checkBlacklisted();

        console.log("All assertions passed!");
    }

    /// @notice Reads the contract addresses from lib/superchain-registry/superchain/configs/${l1ChainName}/${l2ChainName}.toml
    function _getContractSet() internal view returns (Types.ContractSet memory _proxies) {
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

        // Read the chain-specific OptimismPortalProxy address
        _proxies.OptimismPortal = stdToml.readAddress(chainConfig, "$.addresses.OptimismPortalProxy");
    }
}
