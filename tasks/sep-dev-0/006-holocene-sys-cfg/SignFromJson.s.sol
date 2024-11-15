// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {Types} from "@eth-optimism-bedrock/scripts/Types.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {LibString} from "solady/utils/LibString.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {DisputeGameFactory} from "@eth-optimism-bedrock/src/dispute/DisputeGameFactory.sol";
import {FaultDisputeGame} from "@eth-optimism-bedrock/src/dispute/FaultDisputeGame.sol";
import {PermissionedDisputeGame} from "@eth-optimism-bedrock/src/dispute/PermissionedDisputeGame.sol";
import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import {Proxy} from "@eth-optimism-bedrock/src/universal/Proxy.sol";

contract NestedSignFromJson is OriginalSignFromJson {
    using LibString for string;

    // Safe contract for this task.
    address immutable proxyAdminOwnerSafe = vm.envAddress("OWNER_SAFE");
    address immutable livenessGuard = 0x24424336F04440b1c28685a38303aC33C9D14a25;

    address proxyAdmin;
    SystemConfig systemConfig;
    address systemConfigImpl;

    address l1XDMProxy;
    address l1ERC721BridgeProxy;
    address l1StandardBridgeProxy;
    address optimismPortalProxy;
    address optimismMintableERC20FactoryProxy;
    address batchInbox;
    uint256 startBlock;
    address dgfProxy;

    /// @notice Sets up the dgfProxy
    function setUp() public {
        string memory inputJson;
        string memory path = "/tasks/sep-dev-0/006-holocene-sys-cfg/input.json";
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            inputJson = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        proxyAdmin = stdJson.readAddress(inputJson, "$.transactions[9].to");
        systemConfigImpl = stdJson.readAddress(inputJson, "$.transactions[9].contractInputsValues._implementation");
        systemConfig = SystemConfig(stdJson.readAddress(inputJson, "$.transactions[9].contractInputsValues._proxy"));

        l1XDMProxy = stdJson.readAddress(inputJson, "$.transactions[1].contractInputsValues._addr");
        l1ERC721BridgeProxy = stdJson.readAddress(inputJson, "$.transactions[2].contractInputsValues._addr");
        l1StandardBridgeProxy = stdJson.readAddress(inputJson, "$.transactions[3].contractInputsValues._addr");
        optimismPortalProxy = stdJson.readAddress(inputJson, "$.transactions[4].contractInputsValues._addr");
        optimismMintableERC20FactoryProxy = stdJson.readAddress(inputJson, "$.transactions[5].contractInputsValues._addr");
        batchInbox = stdJson.readAddress(inputJson, "$.transactions[6].contractInputsValues._addr");
        startBlock = stdJson.readUint(inputJson, "$.transactions[7].contractInputsValues._block");
        dgfProxy = stdJson.readAddress(inputJson, "$.transactions[8].contractInputsValues._addr");
    }

    function getCodeExceptions() internal view override returns (address[] memory exceptions) {
        exceptions = new address[](1);
        exceptions[0] = batchInbox;
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory allowed) {
        allowed = new address[](3);
        allowed[0] = address(systemConfig);
        allowed[1] = proxyAdminOwnerSafe;
        allowed[2] = livenessGuard;
    }

    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory) internal override {
        console.log("Running post-deploy assertions");
        checkStateDiff(accesses);
        checkSystemConfigProxy();
        console.log("All assertions passed!");
    }

    function checkSystemConfigProxy() internal {
        console.log("check system config proxy");

        vm.prank(proxyAdmin);
        address impl = Proxy(payable(address(systemConfig))).implementation();
        require(impl == systemConfigImpl, "sc-100");

        require(address(uint160(uint256(vm.load(address(systemConfig), systemConfig.L1_CROSS_DOMAIN_MESSENGER_SLOT())))) == l1XDMProxy, "sc-200");
        require(address(uint160(uint256(vm.load(address(systemConfig), systemConfig.L1_ERC_721_BRIDGE_SLOT())))) == l1ERC721BridgeProxy, "sc-300");
        require(address(uint160(uint256(vm.load(address(systemConfig), systemConfig.L1_STANDARD_BRIDGE_SLOT())))) == l1StandardBridgeProxy, "sc-400");
        require(address(uint160(uint256(vm.load(address(systemConfig), systemConfig.OPTIMISM_PORTAL_SLOT())))) == optimismPortalProxy, "sc-500");
        require(address(uint160(uint256(vm.load(address(systemConfig), systemConfig.OPTIMISM_MINTABLE_ERC20_FACTORY_SLOT())))) == optimismMintableERC20FactoryProxy, "sc-600");
        require(address(uint160(uint256(vm.load(address(systemConfig), systemConfig.BATCH_INBOX_SLOT())))) == batchInbox, "sc-700");
        require(uint256(vm.load(address(systemConfig), systemConfig.START_BLOCK_SLOT())) == startBlock, "sc-800");
        require(address(uint160(uint256(vm.load(address(systemConfig), systemConfig.DISPUTE_GAME_FACTORY_SLOT())))) == dgfProxy, "sc-900");
    }
}
