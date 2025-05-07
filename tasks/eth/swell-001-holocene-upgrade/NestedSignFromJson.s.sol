// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {NestedSignFromJson as OriginalNestedSignFromJson} from "script/NestedSignFromJson.s.sol";
import {SuperchainRegistry} from "script/verification/Verification.s.sol";
import {BytecodeComparison} from "src/libraries/BytecodeComparison.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {Types} from "@eth-optimism-bedrock/scripts/libraries/Types.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {LibString} from "solady/utils/LibString.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {DisputeGameFactory} from "@eth-optimism-bedrock/src/dispute/DisputeGameFactory.sol";
import {FaultDisputeGame} from "@eth-optimism-bedrock/src/dispute/FaultDisputeGame.sol";
import {PermissionedDisputeGame} from "@eth-optimism-bedrock/src/dispute/PermissionedDisputeGame.sol";
import {MIPS} from "@eth-optimism-bedrock/src/cannon/MIPS.sol";
import {ISemver} from "@eth-optimism-bedrock/interfaces/universal/ISemver.sol";
import {IDelayedWETH} from "@eth-optimism-bedrock/interfaces/dispute/IDelayedWETH.sol";
import {IPermissionedDisputeGame} from "@eth-optimism-bedrock/interfaces/dispute/IPermissionedDisputeGame.sol";
import {IFaultDisputeGame} from "@eth-optimism-bedrock/interfaces/dispute/IFaultDisputeGame.sol";

contract NestedSignFromJson is OriginalNestedSignFromJson, SuperchainRegistry {
    using LibString for string;

    /// @notice Expected address for the PermissionedDisputeGame implementation.
    IPermissionedDisputeGame expectedPermissionedDisputeGameImpl =
        IPermissionedDisputeGame(vm.envAddress("EXPECTED_PERMISSIONED_DISPUTE_GAME_IMPL"));

    /// @notice OP Main net address for the PermissionedDisputeGame implementation for comparison.
    IPermissionedDisputeGame comparisonPermissionedDisputeGameImpl =
        IPermissionedDisputeGame(vm.envAddress("COMPARISON_PERMISSIONED_DISPUTE_GAME_IMPL"));

    /// @notice Expected address for the FaultDisputeGame implementation.
    IFaultDisputeGame expectedFaultDisputeGameImpl =
        IFaultDisputeGame(vm.envAddress("EXPECTED_FAULT_DISPUTE_GAME_IMPL"));

    /// @notice OP Main net address for the FaultDisputeGame implementation for comparison.
    IFaultDisputeGame comparisonFaultDisputeGameImpl =
        IFaultDisputeGame(vm.envAddress("COMPARISON_FAULT_DISPUTE_GAME_IMPL"));

     /// @notice Expected address for the Permissioned DelayedWETH proxy.
    IDelayedWETH expectedPermissionedDelayedWETHProxy =
        IDelayedWETH(payable(vm.envAddress("EXPECTED_PERMISSIONED_DELAYED_WETH_PROXY")));

     /// @notice Expected address for the DelayedWETH proxy.
    IDelayedWETH expectedDelayedWETHProxy =
        IDelayedWETH(payable(vm.envAddress("EXPECTED_DELAYED_WETH_PROXY")));

    /// Dynamically assigned to these addresses in setUp
    DisputeGameFactory dgfProxy;
    address newMips;
    address oracle;
    uint256 chainId;

    bytes32 constant absolutePrestate = 0x03526dfe02ab00a178e0ab77f7539561aaf5b5e3b46cd3be358f1e501b06d8a9;

    address constant livenessGuard = 0x24424336F04440b1c28685a38303aC33C9D14a25;
    string constant gameVersion = "1.3.1";

    // Safe contract for this task.
    GnosisSafe securityCouncilSafe = GnosisSafe(payable(vm.envAddress("COUNCIL_SAFE")));
    GnosisSafe fndSafe = GnosisSafe(payable(vm.envAddress("FOUNDATION_SAFE")));
    GnosisSafe ownerSafe = GnosisSafe(payable(vm.envAddress("OWNER_SAFE")));

    address newProposerAddress = vm.envAddress("NEW_PROPOSER_ADDRESS");

    FaultDisputeGame faultDisputeGame;
    PermissionedDisputeGame permissionedDisputeGame;

    constructor() SuperchainRegistry("mainnet", "swell", "v1.8.0-rc.4") {}

    function setUp() public {
        
        dgfProxy = DisputeGameFactory(proxies.DisputeGameFactory);
        newMips = standardVersions.MIPS.Address;
        oracle = standardVersions.PreimageOracle.Address;
        chainId = chainConfig.chainId;

        string memory inputJson;
        string memory path = "/tasks/eth/swell-001-holocene-upgrade/input.json";
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            inputJson = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        permissionedDisputeGame = PermissionedDisputeGame(stdJson.readAddress(inputJson, "$.transactions[1].contractInputsValues._impl"));
        faultDisputeGame = FaultDisputeGame(stdJson.readAddress(inputJson, "$.transactions[0].contractInputsValues._impl"));
    }

    function getCodeExceptions() internal view override returns (address[] memory) {
        // Safe owners will appear in storage in the LivenessGuard when added, and they are allowed
        // to have code AND to have no code.
        address[] memory securityCouncilSafeOwners = securityCouncilSafe.getOwners();

        // To make sure we probably handle all signers whether or not they have code, first we count
        // the number of signers that have no code.
        uint256 numberOfSafeSignersWithNoCode;
        for (uint256 i = 0; i < securityCouncilSafeOwners.length; i++) {
            if (securityCouncilSafeOwners[i].code.length == 0) {
                numberOfSafeSignersWithNoCode++;
            }
        }

        // Then we extract those EOA addresses into a dedicated array.
        uint256 trackedSignersWithNoCode;
        address[] memory safeSignersWithNoCode = new address[](numberOfSafeSignersWithNoCode);
        for (uint256 i = 0; i < securityCouncilSafeOwners.length; i++) {
            if (securityCouncilSafeOwners[i].code.length == 0) {
                safeSignersWithNoCode[trackedSignersWithNoCode] = securityCouncilSafeOwners[i];
                trackedSignersWithNoCode++;
            }
        }

        // Here we add the standard (non Safe signer) exceptions.
        address[] memory shouldHaveCodeExceptions = new address[](0 + numberOfSafeSignersWithNoCode);


        // And finally, we append the Safe signer exceptions.
        for (uint256 i = 0; i < safeSignersWithNoCode.length; i++) {
            shouldHaveCodeExceptions[0 + i] = safeSignersWithNoCode[i];
        }

        return shouldHaveCodeExceptions;
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory allowed) {
        allowed = new address[](5);
        allowed[0] = address(dgfProxy);
        allowed[1] = address(ownerSafe);
        allowed[2] = address(securityCouncilSafe);
        allowed[3] = address(fndSafe);
        allowed[4] = livenessGuard;
    }

    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory) internal view override {
        console.log("Running post-deploy assertions");
        checkStateDiff(accesses);
        checkDGFProxyAndGames();
        checkMips();
        checkPermissionedDisputeGame();
        checkFaultDisputeGame();
        console.log("All assertions passed!");
    }

    function checkDGFProxyAndGames() internal view {
        require(address(faultDisputeGame) == address(dgfProxy.gameImpls(GameTypes.CANNON)), "dgf-100");
        require(address(permissionedDisputeGame) == address(dgfProxy.gameImpls(GameTypes.PERMISSIONED_CANNON)), "dgf-200");

        require(faultDisputeGame.version().eq(gameVersion), "game-100");
        require(permissionedDisputeGame.version().eq(gameVersion), "game-200");

        require(faultDisputeGame.absolutePrestate().raw() == absolutePrestate, "game-300");
        require(permissionedDisputeGame.absolutePrestate().raw() == absolutePrestate, "game-400");

        require(address(faultDisputeGame.vm()) == newMips, "game-500");
        require(address(permissionedDisputeGame.vm()) == newMips, "game-600");

        require(faultDisputeGame.l2ChainId() == chainId, "game-700");
        require(permissionedDisputeGame.l2ChainId() == chainId, "game-800");
    }

    /// @notice Checks that the FaultDisputeGame was handled correctly.
    function checkFaultDisputeGame() internal view {
        // Check that the FaultDisputeGame version is correct.
        require(LibString.eq(expectedFaultDisputeGameImpl.version(), standardVersions.FaultDisputeGame.version), "checkFaultDisputeGame-21");
        require(LibString.eq(expectedPermissionedDelayedWETHProxy.version(), standardVersions.DelayedWETH.version), "checkPermissionedDelayedWETH-22");
        require(LibString.eq(expectedDelayedWETHProxy.version(), standardVersions.DelayedWETH.version), "checkDelayedWETH-23");

        // Check that only bytecode diffs vs comparison contract are expected.
        BytecodeComparison.Diff[] memory diffs = new BytecodeComparison.Diff[](12);
        diffs[0] = BytecodeComparison.Diff({start: 1319, content: abi.encode(expectedDelayedWETHProxy)});
        diffs[1] = BytecodeComparison.Diff({start: 1555, content: abi.encode(proxies.AnchorStateRegistry)});
        diffs[2] = BytecodeComparison.Diff({start: 1926, content: abi.encode(absolutePrestate)});
        diffs[3] = BytecodeComparison.Diff({start: 2590, content: abi.encode(chainConfig.chainId)});
        diffs[4] = BytecodeComparison.Diff({start: 6026, content: abi.encode(proxies.AnchorStateRegistry)});
        diffs[5] = BytecodeComparison.Diff({start: 6476, content: abi.encode(expectedDelayedWETHProxy)});
        diffs[6] = BytecodeComparison.Diff({start: 9344, content: abi.encode(expectedDelayedWETHProxy)});
        diffs[7] = BytecodeComparison.Diff({start: 9704, content: abi.encode(proxies.AnchorStateRegistry)});
        diffs[8] = BytecodeComparison.Diff({start: 10730, content: abi.encode(expectedDelayedWETHProxy)});
        diffs[9] = BytecodeComparison.Diff({start: 12628, content: abi.encode(absolutePrestate)});
        diffs[10] = BytecodeComparison.Diff({start: 14649, content: abi.encode(chainConfig.chainId)});
        diffs[11] = BytecodeComparison.Diff({start: 15892, content: abi.encode(expectedDelayedWETHProxy)});

        require(
            BytecodeComparison.compare(
                address(comparisonFaultDisputeGameImpl), address(expectedFaultDisputeGameImpl), diffs
            ),
            "checkFaultDisputeGame-101"
        );
    }

    /// @notice Checks that the PermissionedDisputeGame was handled correctly.
    function checkPermissionedDisputeGame() internal view {
        // Check that the PermissionedDisputeGame version is correct.
        require(LibString.eq(expectedPermissionedDisputeGameImpl.version(), "1.3.1"), "checkPermissionedDisputeGame-20");

        // Check that the proposer address matches the new one
        require(PermissionedDisputeGame(address(expectedPermissionedDisputeGameImpl)).proposer() == newProposerAddress, "checkPermissionedDisputeGame-30");
        
        // Check that only bytecode diffs vs comparison contract are expected.
        BytecodeComparison.Diff[] memory diffs = new BytecodeComparison.Diff[](16);
 
        diffs[0] = BytecodeComparison.Diff({start: 1341, content: abi.encode(expectedPermissionedDelayedWETHProxy)});
        diffs[1] = BytecodeComparison.Diff({start: 1628, content: abi.encode(proxies.AnchorStateRegistry)});
        diffs[2] = BytecodeComparison.Diff({start: 1999, content: abi.encode(absolutePrestate)});
        // Check new proposer address is used, instead of chainconfig.proposer
        diffs[3] = BytecodeComparison.Diff({start: 2254, content: abi.encode(newProposerAddress)});
        diffs[4] = BytecodeComparison.Diff({start: 2714, content: abi.encode(chainConfig.chainId)});
        diffs[5] = BytecodeComparison.Diff({start: 6150, content: abi.encode(proxies.AnchorStateRegistry)});
        diffs[6] = BytecodeComparison.Diff({start: 6600, content: abi.encode(expectedPermissionedDelayedWETHProxy)});
        diffs[7] = BytecodeComparison.Diff({start: 6870, content: abi.encode(newProposerAddress)});
        diffs[8] = BytecodeComparison.Diff({start: 7076, content: abi.encode(newProposerAddress)});
        diffs[9] = BytecodeComparison.Diff({start: 8310, content: abi.encode(newProposerAddress)});
        diffs[10] = BytecodeComparison.Diff({start: 9555, content: abi.encode(chainConfig.chainId)});
        diffs[11] = BytecodeComparison.Diff({start: 10798, content: abi.encode(expectedPermissionedDelayedWETHProxy)});
        diffs[12] = BytecodeComparison.Diff({start: 13599, content: abi.encode(expectedPermissionedDelayedWETHProxy)});
        diffs[13] = BytecodeComparison.Diff({start: 13946, content: abi.encode(proxies.AnchorStateRegistry)});
        diffs[14] = BytecodeComparison.Diff({start: 14972, content: abi.encode(expectedPermissionedDelayedWETHProxy)});
        diffs[15] = BytecodeComparison.Diff({start: 17022, content: abi.encode(absolutePrestate)});
        
        require(
            BytecodeComparison.compare(
                address(comparisonPermissionedDisputeGameImpl), address(expectedPermissionedDisputeGameImpl), diffs
            ),
            "checkPermissionedDisputeGame-100"
        );
    }

    function checkMips() internal view{
        require(newMips.code.length != 0, "MIPS-100");
        vm.assertEq(ISemver(newMips).version(), "1.2.1");
        require(address(MIPS(newMips).oracle()) == oracle, "MIPS-200");
    }

}