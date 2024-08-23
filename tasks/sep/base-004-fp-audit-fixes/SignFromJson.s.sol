// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";
import {EIP1967Helper} from "@eth-optimism-bedrock/test/mocks/EIP1967Helper.sol";
import {ISemver} from "@eth-optimism-bedrock/src/universal/ISemver.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {DisputeGameFactory} from "@eth-optimism-bedrock/src/dispute/DisputeGameFactory.sol";
import {FaultDisputeGame} from "@eth-optimism-bedrock/src/dispute/FaultDisputeGame.sol";
import {PermissionedDisputeGame} from "@eth-optimism-bedrock/src/dispute/PermissionedDisputeGame.sol";
import {DelayedWETH} from "@eth-optimism-bedrock/src/dispute/weth/DelayedWETH.sol";
import {MIPS} from "@eth-optimism-bedrock/src/cannon/MIPS.sol";

interface IASR {
    function disputeGameFactory() external view returns (address disputeGameFactory);
    function superchainConfig() external view returns (address superchainConfig_);
    function version() external view returns (string memory version);
}

contract SignFromJson is OriginalSignFromJson {
    // Safe contract for this task.
    GnosisSafe ownerSafe = GnosisSafe(payable(vm.envAddress("OWNER_SAFE")));
    address superchainConfig = vm.envAddress("SUPERCHAIN_CONFIG_ADDR");

    // Current fault proof contracts
    // Contract addresses taken from https://docs.base.org/docs/base-contracts/
    DisputeGameFactory constant dgfProxy = DisputeGameFactory(0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1);
    IASR constant asrProxy = IASR(0x4C8BA32A5DAC2A720bb35CeDB51D6B067D104205);
    FaultDisputeGame constant currentFDG = FaultDisputeGame(0x48F9F3190b7B5231cBf2aD1A1315AF7f6A554020);
    PermissionedDisputeGame constant currentPDG = PermissionedDisputeGame(0x54966d5A42a812D0dAaDe1FA2321FF8b102d1ee1);

    // New fault proof contracts
    FaultDisputeGame constant newFDG = FaultDisputeGame(0x5062792ED6A85cF72a1424a1b7f39eD0f7972a4B);
    PermissionedDisputeGame constant newPDG = PermissionedDisputeGame(0xCCEfe451048Eaa7df8D0d709bE3AA30d565694D2);
    DelayedWETH constant newFDGWethProxy= DelayedWETH(payable(0x489c2E5ebe0037bDb2DC039C5770757b8E54eA1F));
    DelayedWETH constant newPDGWethProxy = DelayedWETH(payable(0x27A6128F707de3d99F89Bf09c35a4e0753E1B808));

    address constant newDelayedWETHImpl = 0x07F69b19532476c6Cd03056D6BC3F1b110Ab7538;
    address constant newAsrImpl = 0x95907b5069e5a2EF1029093599337a6C9dac8923;
    address constant newMips = 0x47B0E34C1054009e696BaBAAd56165e1e994144d;
    address constant newOracle = 0x92240135b46fc1142dA181f550aE8f595B858854;

    function setUp() public view {
        _precheckDisputeGameImplementation();
    }

    function _precheckDisputeGameImplementation() internal view {
        console.log("pre-check new game implementations");

        // The dispute game parameters are the same as the current ones except for the following addresses:
        // MIPS VM (new implementation) and DelayedWETHProxy - one for each dispute game type
        require(address(currentFDG.anchorStateRegistry()) == address(newFDG.anchorStateRegistry()), "FDG-100");
        require(currentFDG.l2ChainId() == newFDG.l2ChainId(), "FDG-200");
        require(currentFDG.splitDepth() == newFDG.splitDepth(), "FDG-300");
        require(currentFDG.maxGameDepth() == newFDG.maxGameDepth(), "FDG-400");
        require(
            uint64(Duration.unwrap(currentFDG.maxClockDuration())) == uint64(Duration.unwrap(newFDG.maxClockDuration())),
            "FDG-500"
        );
        require(
            uint64(Duration.unwrap(currentFDG.clockExtension())) == uint64(Duration.unwrap(newFDG.clockExtension())),
            "FDG-600"
        );
        require(currentFDG.absolutePrestate().raw() == newFDG.absolutePrestate().raw(), "FDG-700");

        require(address(currentPDG.anchorStateRegistry()) == address(newPDG.anchorStateRegistry()), "PDG-100");
        require(currentPDG.l2ChainId() == newPDG.l2ChainId(), "PDG-200");
        require(currentPDG.splitDepth() == newPDG.splitDepth(), "PDG-300");
        require(currentPDG.maxGameDepth() == newPDG.maxGameDepth(), "PDG-400");
        require(
            uint64(Duration.unwrap(currentPDG.maxClockDuration())) == uint64(Duration.unwrap(newPDG.maxClockDuration())),
            "PDG-500"
        );
        require(
            uint64(Duration.unwrap(currentPDG.clockExtension())) == uint64(Duration.unwrap(newPDG.clockExtension())),
            "PDG-600"
        );
        require(address(currentPDG.proposer()) == address(newPDG.proposer()), "PDG-700");
        require(address(currentPDG.challenger()) == address(newPDG.challenger()), "PDG-800");
        require(currentPDG.absolutePrestate().raw() == newPDG.absolutePrestate().raw(), "PDG-900");
    }

    function getAllowedStorageAccess()
        internal
        view
        override
        returns (address[] memory allowed)
    {
        allowed = new address[](3);
        allowed[0] = address(ownerSafe);
        allowed[1] = address(dgfProxy);
        allowed[2] = address(asrProxy);
    }

    function getCodeExceptions() internal pure override returns (address[] memory codeExceptions) {
        codeExceptions = new address[](0);
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(
        Vm.AccountAccess[] memory accesses,
        SimulationPayload memory /* simPayload */
    ) internal view override {
        console.log("Running post-deploy assertions");

        checkStateDiff(accesses);
        _checkDisputeGameImplementations();
        _checkDelayedWETHProxies();
        _checkMipsAndPreimageOracle();
        _checkAnchorStateRegistry();

        console.log("All assertions passed!");
    }

    function _checkDisputeGameImplementations() internal view {
        console.log("check dispute game implementations");

        require(address(newFDG) == address(dgfProxy.gameImpls(GameTypes.CANNON)), "FDG-800");
        vm.assertEq(newFDG.version(), "1.3.0");

        require(address(newPDG) == address(dgfProxy.gameImpls(GameTypes.PERMISSIONED_CANNON)), "PDG-1000");
        vm.assertEq(newPDG.version(), "1.3.0");
    }

    function _checkDelayedWETHProxies() internal view {
        console.log("check DelayedWETH proxies");

        require(newDelayedWETHImpl.code.length != 0, "WETH-100");

        require(address(newFDG.weth()) == address(newFDGWethProxy), "WETH-FDG-100");
        require(EIP1967Helper.getImplementation(address(newFDG.weth())) == newDelayedWETHImpl, "WETH-FDG-200");
        require(address(newFDG.weth()).code.length != 0, "WETH-FDG-300");
        require(address(newFDGWethProxy.config()) == superchainConfig, "WETH-FDG-400");
        vm.assertEq(newFDGWethProxy.version(), "1.1.0");

        require(address(newPDG.weth()) == address(newPDGWethProxy), "WETH-PDG-100");
        require(EIP1967Helper.getImplementation(address(newPDG.weth())) == newDelayedWETHImpl, "WETH-PDG-200");
        require(address(newPDG.weth()).code.length != 0, "WETH-PDG-300");
        require(address(newPDGWethProxy.config()) == superchainConfig, "WETH-PDG-400");
        vm.assertEq(newPDGWethProxy.version(), "1.1.0");
    }

    function _checkMipsAndPreimageOracle() internal view{
        console.log("check MIPS and PreimageOracle");

        require(newMips.code.length != 0, "MIPS-100");
        vm.assertEq(ISemver(newMips).version(), "1.1.0");
        require(address(MIPS(newMips).oracle()) == newOracle, "MIPS-300");

        require(newOracle.code.length != 0, "Oracle-100");
        vm.assertEq(ISemver(newOracle).version(), "1.1.2");
    }

    function _checkAnchorStateRegistry() internal view {
        console.log("check AnchorStateRegistry");

        require(newAsrImpl.code.length != 0, "ASR-100");
        require(address(asrProxy).code.length != 0, "ASR-200");
        require(EIP1967Helper.getImplementation(address(asrProxy)) == newAsrImpl, "ASR-300");
        require(address(asrProxy.disputeGameFactory()) == address(dgfProxy), "ASR-400");
        require(address(asrProxy.superchainConfig()) == superchainConfig, "ASR-500");
        vm.assertEq(asrProxy.version(), "2.0.0");
    }
}
