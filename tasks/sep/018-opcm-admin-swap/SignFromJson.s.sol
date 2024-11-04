// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {Types} from "@eth-optimism-bedrock/scripts/Types.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {LibString} from "solady/utils/LibString.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {ISemver} from "@eth-optimism-bedrock/src/universal/ISemver.sol";

interface IProxy {
    function admin() external view returns (address);
}

contract SignFromJson is OriginalSignFromJson {
    using LibString for string;

    // Chains for this task.
    string constant l1ChainName = "sepolia";
    string constant l2ChainName = "op";

    // Safe contract for this task.
    GnosisSafe fndSafe = GnosisSafe(payable(vm.envAddress("OWNER_SAFE")));

    IProxy constant opcmProxy = IProxy(0xF564eEA7960EA244bfEbCBbB17858748606147bf);
    address constant proxyAdmin = 0x189aBAAaa82DfC015A588A7dbaD6F13b1D3485Bc;

    Types.ContractSet proxies;

    /// @notice Sets up the contract
    function setUp() public {
        proxies = _getContractSet();
    }

    function getCodeExceptions() internal pure override returns (address[] memory) {
        address[] memory shouldHaveCodeExceptions = new address[](0);
        return shouldHaveCodeExceptions;
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory allowed) {
        allowed = new address[](2);
        allowed[0] = address(opcmProxy);
        allowed[1] = address(fndSafe);
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory accesses, SimulationPayload memory /* simPayload */ )
        internal
        override
    {
        console.log("Running post-deploy assertions");

        checkStateDiff(accesses);
        _checkOPContractsManager();

        console.log("All assertions passed!");
    }

    /// @notice Reads the contract addresses from lib/superchain-registry/superchain/configs/${l1ChainName}/${l2ChainName}.toml
    function _getContractSet() internal view returns (Types.ContractSet memory _proxies) {
        string memory chainConfig;
        string memory path = string.concat("/lib/superchain-registry/superchain/configs/", l1ChainName, "/superchain.toml");
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            chainConfig = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }
        _proxies.SuperchainConfig = stdToml.readAddress(chainConfig, "$.superchain_config_addr");
    }

    function _checkOPContractsManager() internal {
        console.log("check OPContractsManager");

        vm.prank(proxyAdmin);
        require(opcmProxy.admin() == proxyAdmin, "opcm-100");
        require(ISemver(address(opcmProxy)).version().eq("1.0.0-beta.20"), "opcm-200");
    }
}
