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

    /// @notice Sets up the dgfProxy
    function setUp() public {
        string memory inputJson;
        string memory path = "/tasks/sep-dev-0/006-holocene-sys-cfg/input.json";
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            inputJson = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        proxyAdmin = stdJson.readAddress(inputJson, "$.transactions[0].to");
        systemConfigImpl = stdJson.readAddress(inputJson, "$.transactions[0].contractInputsValues._implementation");
        systemConfig = SystemConfig(stdJson.readAddress(inputJson, "$.transactions[0].contractInputsValues._proxy"));
    }

    function getCodeExceptions() internal pure override returns (address[] memory) {
        // No code exceptions expected
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
    }
}
