// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {OptimismPortal2, IDisputeGame} from "@eth-optimism-bedrock/src/L1/OptimismPortal2.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {LibString} from "solady/utils/LibString.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";

interface ASR {
    function getAnchorRoot() external view returns (bytes32, uint256);
    function disputeGameFactory() external view returns (address);
    function systemConfig() external view returns (address);
    function respectedGameType() external view returns (uint32);
}

contract SignFromJson is OriginalSignFromJson {
    using LibString for string;

    address constant SENTINEL_MODULE = address(0x1);

    GnosisSafe safe;
    ASR asr;

    address systemConfig;
    address disputeGameFactory;
    uint32 respectedGameType;

    function setUp() public {
        asr = ASR(vm.envAddress("ANCHOR_STATE_REGISTRY_PROXY"));
        safe = GnosisSafe(payable(vm.envAddress("OWNER_SAFE")));
        disputeGameFactory = asr.disputeGameFactory();
        respectedGameType = asr.respectedGameType();
        systemConfig = asr.systemConfig();
    }

    function getCodeExceptions() internal view override returns (address[] memory) {
        address[] memory safeOwners = safe.getOwners();
        address[] memory shouldHaveCodeExceptions = new address[](safeOwners.length);

        for (uint256 i = 0; i < safeOwners.length; i++) {
            shouldHaveCodeExceptions[i] = safeOwners[i];
        }
        return shouldHaveCodeExceptions;
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory allowed) {
        allowed = new address[](4);
        allowed[0] = vm.envAddress("OWNER_SAFE");
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory /* simPayload */ )
        internal
        view
        override
    {
        console.log("Running post-deploy assertions");

        (bytes32 root, uint256 num) = asr.getAnchorRoot();
        console.log("root");
        console.logBytes32(root);
        require(root == bytes32(0x044a43699e6242f6906d2d1abb633c11fb2bc41a6c9d69adf9b4a8dfbc3f97bc), "invalid root");
        require(num == 7587, "invalid num");
        require(asr.systemConfig() == systemConfig, "system config changed");
        require(asr.disputeGameFactory() == disputeGameFactory, "system config changed");
        require(asr.respectedGameType() == respectedGameType, "respected game type changed");
    }
}
