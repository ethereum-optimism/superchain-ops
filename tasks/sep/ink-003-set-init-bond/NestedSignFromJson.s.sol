// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {NestedSignFromJson as OriginalNestedSignFromJson} from "script/NestedSignFromJson.s.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {console2 as console} from "forge-std/console2.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";
import {LibString} from "solady/utils/LibString.sol";
import {DisputeGameFactory} from "@eth-optimism-bedrock/src/dispute/DisputeGameFactory.sol";
import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {SuperchainRegistry} from "script/verification/Verification.s.sol";

contract NestedSignFromJson is OriginalNestedSignFromJson, SuperchainRegistry {
    using LibString for string;

    // Safe contract for this task.
    GnosisSafe ownerSafe = GnosisSafe(payable(vm.envAddress("OWNER_SAFE")));
    GnosisSafe councilSafe = GnosisSafe(payable(vm.envAddress("COUNCIL_SAFE")));
    GnosisSafe foundationSafe = GnosisSafe(payable(vm.envAddress("FOUNDATION_SAFE")));

    // The slot used to store the livenessGuard address in GnosisSafe.
    // See https://github.com/safe-global/safe-smart-account/blob/186a21a74b327f17fc41217a927dea7064f74604/contracts/base/GuardManager.sol#L30
    bytes32 livenessGuardSlot = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;

    SystemConfig systemConfig;
    DisputeGameFactory dgfProxy;

    uint256 initBond = 0.08 ether;

    address[] extraStorageAccessAddresses;

    constructor() SuperchainRegistry("sepolia", vm.envString("L2_CHAIN_NAME"), "v1.8.0-rc.4") {}

    function setUp() public {
        systemConfig = SystemConfig(proxies.SystemConfig); 
        dgfProxy = DisputeGameFactory(systemConfig.disputeGameFactory());
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory allowed) {
        allowed = new address[](5 + extraStorageAccessAddresses.length);
        allowed[0] = address(dgfProxy);
        allowed[1] = address(ownerSafe);
        allowed[2] = address(councilSafe);
        allowed[3] = address(foundationSafe);
        address livenessGuard = address(uint160(uint256(vm.load(address(councilSafe), livenessGuardSlot))));
        allowed[4] = livenessGuard;

        for (uint256 i = 0; i < extraStorageAccessAddresses.length; i++) {
            allowed[5 + i] = extraStorageAccessAddresses[i];
        }
        return allowed;
    }

    function getCodeExceptions() internal view override returns (address[] memory) {
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory) internal view override {
        console.log("Running post-deploy assertions");

        checkStateDiff(accesses);
        _checkInitBonds();

        console.log("All assertions passed!");
    }

    function _checkInitBonds() internal view {
        console.log("check the initial bonds");

        require(dgfProxy.initBonds(GameType.wrap(0)) == initBond, "check-bond-100");
        require(dgfProxy.initBonds(GameType.wrap(1)) == initBond, "check-bond-200");
    }
}
