// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";
import {LibString} from "solady/utils/LibString.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {DisputeGameFactory} from "@eth-optimism-bedrock/src/dispute/DisputeGameFactory.sol";
import {FaultDisputeGame} from "@eth-optimism-bedrock/src/dispute/FaultDisputeGame.sol";
import {PermissionedDisputeGame} from "@eth-optimism-bedrock/src/dispute/PermissionedDisputeGame.sol";
import {MIPS} from "@eth-optimism-bedrock/src/cannon/MIPS.sol";
import {ISemver} from "@eth-optimism-bedrock/src/universal/ISemver.sol";

contract SignFromJson is OriginalSignFromJson {
    using LibString for string;

    // Safe contract for this task.
    GnosisSafe ownerSafe = GnosisSafe(payable(vm.envAddress("OWNER_SAFE")));

    // Current dispute game implementations
    FaultDisputeGame currentFDG;
    PermissionedDisputeGame currentPDG;

    // New dispute game implementations
    FaultDisputeGame newFDG;
    PermissionedDisputeGame newPDG;

    // https://github.com/ethereum-optimism/superchain-registry/blob/main/superchain/configs/sepolia/base.toml#L56
    DisputeGameFactory constant dgfProxy = DisputeGameFactory(0xd6E6dBf4F7EA0ac412fD8b65ED297e64BB7a06E1);

    // Other expected values
    bytes32 constant absolutePrestate = 0x03925193e3e89f87835bbdf3a813f60b2aa818a36bbe71cd5d8fd7e79f5e8afe;
    address constant newMips = 0x69470D6970Cd2A006b84B1d4d70179c892cFCE01;
    // https://docs.base.org/docs/base-contracts/#ethereum-testnet-sepolia
    address constant oracle = 0x92240135b46fc1142dA181f550aE8f595B858854;
    string constant gameVersion = "1.3.1";
    uint256 constant chainId = 84532;

    function setUp() public {
        // Get the current dispute game implementations
        currentFDG = FaultDisputeGame(
            address(dgfProxy.gameImpls(GameTypes.CANNON))
        );
        currentPDG = PermissionedDisputeGame(
            address(dgfProxy.gameImpls(GameTypes.PERMISSIONED_CANNON))
        );

        // Get the new dispute game implementations, parsed from the input.json
        string memory inputJson;
        string memory path = "/tasks/sep/base-005-fp-holocene-upgrade/input.json";
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            inputJson = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        newPDG = PermissionedDisputeGame(stdJson.readAddress(inputJson, "$.transactions[0].contractInputsValues._impl"));
        newFDG = FaultDisputeGame(stdJson.readAddress(inputJson, "$.transactions[1].contractInputsValues._impl"));

        // Check the correctness of the new dispute games with the current ones
        _precheckDisputeGameImplementation();
    }

    function _precheckDisputeGameImplementation() internal view {
        console.log("pre-check new game implementations");

        // check the current and new fault dispute game implementations
        require(address(currentFDG.anchorStateRegistry()) == address(newFDG.anchorStateRegistry()), "precheck-100");
        require(currentFDG.l2ChainId() == newFDG.l2ChainId(), "precheck-101");
        require(currentFDG.splitDepth() == newFDG.splitDepth(), "precheck-102");
        require(currentFDG.maxGameDepth() == newFDG.maxGameDepth(), "precheck-103");
        require(
            uint64(Duration.unwrap(currentFDG.maxClockDuration())) ==
                uint64(Duration.unwrap(newFDG.maxClockDuration())),
            "precheck-104"
        );
        require(
            uint64(Duration.unwrap(currentFDG.clockExtension())) ==
                uint64(Duration.unwrap(newFDG.clockExtension())),
            "precheck-105"
        );

        // check the current and new permissioned dispute game implementations
        require(address(currentPDG.anchorStateRegistry()) == address(newPDG.anchorStateRegistry()), "precheck-200");
        require(currentPDG.l2ChainId() == newPDG.l2ChainId(), "precheck-201");
        require(currentPDG.splitDepth() == newPDG.splitDepth(), "precheck-202");
        require(currentPDG.maxGameDepth() == newPDG.maxGameDepth(), "precheck-203");
        require(
            uint64(Duration.unwrap(currentPDG.maxClockDuration())) ==
                uint64(Duration.unwrap(newPDG.maxClockDuration())),
            "precheck-204"
        );
        require(
            uint64(Duration.unwrap(currentPDG.clockExtension())) ==
                uint64(Duration.unwrap(newPDG.clockExtension())),
            "precheck-205"
        );
        require(address(currentPDG.proposer()) == address(newPDG.proposer()), "precheck-206");
        require(address(currentPDG.challenger()) == address(newPDG.challenger()), "precheck-207");
    }

    function getAllowedStorageAccess()
        internal
        view
        override
        returns (address[] memory allowed)
    {
        allowed = new address[](2);
        allowed[0] = address(dgfProxy);
        allowed[1] = address(ownerSafe);
    }

    function getCodeExceptions() internal view override returns (address[] memory exceptions) {
        // No exceptions are expected in this task, but it must be implemented.
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(
        Vm.AccountAccess[] memory accesses,
        Simulation.Payload memory /* simPayload */
    ) internal view override {
        console.log("Running post-deploy assertions");

        checkStateDiff(accesses);
        checkDGFProxyAndGames();
        checkMips();

        console.log("All assertions passed!");
    }

    function checkDGFProxyAndGames() internal view {
        console.log("check dispute game implementations");

        require(address(newFDG) == address(dgfProxy.gameImpls(GameTypes.CANNON)), "dgf-100");
        require(address(newPDG) == address(dgfProxy.gameImpls(GameTypes.PERMISSIONED_CANNON)), "dgf-200");

        require(newFDG.version().eq(gameVersion), "game-100");
        require(newPDG.version().eq(gameVersion), "game-200");

        require(newFDG.absolutePrestate().raw() == absolutePrestate, "game-300");
        require(newPDG.absolutePrestate().raw() == absolutePrestate, "game-400");

        require(address(newFDG.vm()) == newMips, "game-500");
        require(address(newPDG.vm()) == newMips, "game-600");

        require(newFDG.l2ChainId() == chainId, "game-700");
        require(newPDG.l2ChainId() == chainId, "game-800");
    }

    function checkMips() internal view{
        console.log("check MIPS");

        require(newMips.code.length != 0, "MIPS-100");
        vm.assertEq(ISemver(newMips).version(), "1.2.1");
        require(address(MIPS(newMips).oracle()) == oracle, "MIPS-200");
    }
}
