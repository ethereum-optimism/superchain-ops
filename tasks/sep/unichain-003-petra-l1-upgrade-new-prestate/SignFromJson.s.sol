// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";
import {LibString} from "solady/utils/LibString.sol";
import {Types} from "@eth-optimism-bedrock/scripts/libraries/Types.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {DisputeGameFactory} from "@eth-optimism-bedrock/src/dispute/DisputeGameFactory.sol";
import {FaultDisputeGame} from "@eth-optimism-bedrock/src/dispute/FaultDisputeGame.sol";
import {PermissionedDisputeGame} from "@eth-optimism-bedrock/src/dispute/PermissionedDisputeGame.sol";
import {SystemConfig} from "@eth-optimism-bedrock/src/L1/SystemConfig.sol";
import {SuperchainRegistry} from "script/verification/Verification.s.sol";
import {BytecodeComparison} from "src/libraries/BytecodeComparison.sol";
import {MIPS} from "@eth-optimism-bedrock/src/cannon/MIPS.sol";
import {ISemver} from "@eth-optimism-bedrock/interfaces/universal/ISemver.sol";
import {IDelayedWETH} from "@eth-optimism-bedrock/interfaces/dispute/IDelayedWETH.sol";
import {IPermissionedDisputeGame} from "@eth-optimism-bedrock/interfaces/dispute/IPermissionedDisputeGame.sol";
import {IFaultDisputeGame} from "@eth-optimism-bedrock/interfaces/dispute/IFaultDisputeGame.sol";

contract SignFromJson is OriginalSignFromJson, SuperchainRegistry {
    using LibString for string;

    /// @notice Expected address for the PermissionedDisputeGame implementation.
    IPermissionedDisputeGame expectedPermissionedDisputeGameImpl =
        IPermissionedDisputeGame(
            vm.envAddress("EXPECTED_PERMISSIONED_DISPUTE_GAME_IMPL")
        );

    /// @notice OP Sepolia address for the PermissionedDisputeGame implementation for comparison.
    IPermissionedDisputeGame comparisonPermissionedDisputeGameImpl =
        IPermissionedDisputeGame(
            vm.envAddress("COMPARISON_PERMISSIONED_DISPUTE_GAME_IMPL")
        );

    /// @notice Expected address for the FaultDisputeGame implementation.
    IFaultDisputeGame expectedFaultDisputeGameImpl =
        IFaultDisputeGame(vm.envAddress("EXPECTED_FAULT_DISPUTE_GAME_IMPL"));

    /// @notice OP Sepolia address for the FaultDisputeGame implementation for comparison.
    IFaultDisputeGame comparisonFaultDisputeGameImpl =
        IFaultDisputeGame(vm.envAddress("COMPARISON_FAULT_DISPUTE_GAME_IMPL"));

    /// @notice Expected address for the Permissioned DelayedWETH proxy.
    IDelayedWETH expectedPermissionedDelayedWETHProxy =
        IDelayedWETH(
            payable(vm.envAddress("EXPECTED_PERMISSIONED_DELAYED_WETH_PROXY"))
        );

    /// @notice Expected address for the DelayedWETH proxy.
    IDelayedWETH expectedDelayedWETHProxy =
        IDelayedWETH(payable(vm.envAddress("EXPECTED_DELAYED_WETH_PROXY")));

    // Safe contract for this task.
    GnosisSafe ownerSafe = GnosisSafe(payable(vm.envAddress("OWNER_SAFE")));
    SystemConfig systemConfig = SystemConfig(vm.envAddress("SYSTEM_CONFIG"));

    // The slot used to store the livenessGuard address in GnosisSafe.
    // See https://github.com/safe-global/safe-smart-account/blob/186a21a74b327f17fc41217a927dea7064f74604/contracts/base/GuardManager.sol#L30
    bytes32 constant absolutePrestate =
        0x0354eee87a1775d96afee8977ef6d5d6bd3612b256170952a01bf1051610ee01;
    bytes32 livenessGuardSlot =
        0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;
    string constant gameVersion = "1.3.1";

    // DisputeGameFactoryProxy address.
    DisputeGameFactory dgfProxy;
    FaultDisputeGame faultDisputeGame;
    PermissionedDisputeGame permissionedDisputeGame;
    address newMips;
    address oracle;
    uint256 chainId;

    address[] extraStorageAccessAddresses;

    constructor() SuperchainRegistry("sepolia", "unichain", "v1.8.0-rc.4") {}

    function setUp() public {
        dgfProxy = DisputeGameFactory(proxies.DisputeGameFactory);
        newMips = standardVersions.MIPS.Address;
        oracle = standardVersions.PreimageOracle.Address;
        chainId = chainConfig.chainId;

        string memory inputJson;
        string
            memory path = "/tasks/sep/unichain-003-petra-l1-upgrade-new-prestate/input.json";
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (
            string memory data
        ) {
            inputJson = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        faultDisputeGame = FaultDisputeGame(
            stdJson.readAddress(
                inputJson,
                "$.transactions[0].contractInputsValues._impl"
            )
        );
        permissionedDisputeGame = PermissionedDisputeGame(
            stdJson.readAddress(
                inputJson,
                "$.transactions[1].contractInputsValues._impl"
            )
        );

        _precheckDisputeGameImplementation(
            GameType.wrap(0),
            address(faultDisputeGame)
        );
        _precheckDisputeGameImplementation(
            GameType.wrap(1),
            address(permissionedDisputeGame)
        );
        // INSERT NEW PRE CHECKS HERE
    }

    function getCodeExceptions()
        internal
        view
        override
        returns (address[] memory)
    {
        return new address[](0);
    }

    // _precheckDisputeGameImplementation checks that the new game being set has the same configuration as the existing
    // implementation with the exception of the absolutePrestate. This is the most common scenario where the game
    // implementation is upgraded to provide an updated fault proof program that supports an upcoming hard fork.
    function _precheckDisputeGameImplementation(
        GameType _targetGameType,
        address _newImpl
    ) internal view {
        console.log(
            "pre-check new game implementations",
            _targetGameType.raw()
        );

        FaultDisputeGame currentImpl = FaultDisputeGame(
            address(dgfProxy.gameImpls(GameType(_targetGameType)))
        );
        // No checks are performed if there is no prior implementation.
        // When deploying the first implementation, it is recommended to implement custom checks.

        FaultDisputeGame faultDisputeGame = FaultDisputeGame(_newImpl);
        // these are both using the latest version of the MIPs contracts
        require(
            faultDisputeGame.gameType().raw() == _targetGameType.raw(),
            "10"
        );
        // require(
        //     address(currentImpl.weth()) != address(faultDisputeGame.weth()),
        //     "20"
        // );
        require(
            address(currentImpl.anchorStateRegistry()) ==
                address(faultDisputeGame.anchorStateRegistry()),
            "30"
        );
        require(currentImpl.l2ChainId() == faultDisputeGame.l2ChainId(), "40");
        require(
            currentImpl.splitDepth() == faultDisputeGame.splitDepth(),
            "50"
        );
        require(
            currentImpl.maxGameDepth() == faultDisputeGame.maxGameDepth(),
            "60"
        );
        require(
            uint64(Duration.unwrap(currentImpl.maxClockDuration())) ==
                uint64(Duration.unwrap(faultDisputeGame.maxClockDuration())),
            "70"
        );
        require(
            uint64(Duration.unwrap(currentImpl.clockExtension())) ==
                uint64(Duration.unwrap(faultDisputeGame.clockExtension())),
            "80"
        );

        if (_targetGameType.raw() == GameTypes.PERMISSIONED_CANNON.raw()) {
            PermissionedDisputeGame currentPDG = PermissionedDisputeGame(
                address(currentImpl)
            );
            PermissionedDisputeGame permissionedDisputeGame = PermissionedDisputeGame(
                    address(faultDisputeGame)
                );
            require(
                address(currentPDG.proposer()) ==
                    address(permissionedDisputeGame.proposer()),
                "90"
            );
            // this check does NOT pass bc Unichain's current PDG challenger differs
            // from the Standard Version's. We are changing the PDG challenger to
            // match the Standard Version's here.
            console.log(
                "currentPDG.challenger()",
                address(currentPDG.challenger())
            );
            console.log(
                "permissionedDisputeGame.challenger()",
                address(permissionedDisputeGame.challenger())
            );
            require(
                address(currentPDG.challenger()) ==
                    address(permissionedDisputeGame.challenger()),
                "100"
            );
        }
    }

    function getAllowedStorageAccess()
        internal
        view
        override
        returns (address[] memory allowed)
    {
        allowed = new address[](2 + extraStorageAccessAddresses.length);
        allowed[0] = address(dgfProxy);
        allowed[1] = address(ownerSafe);

        for (uint256 i = 0; i < extraStorageAccessAddresses.length; i++) {
            allowed[2 + i] = extraStorageAccessAddresses[i];
        }
        return allowed;
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(
        Vm.AccountAccess[] memory accesses,
        Simulation.Payload memory
    ) internal view override {
        console.log("Running post-deploy assertions");

        checkStateDiff(accesses);
        _postcheckAnchorStateCopy(
            GameType.wrap(0),
            bytes32(
                0x3dd61be7c3e870294e842a0e3a7150fb5b73539260a9ec55d59151ba5f2201e9
            ),
            6801092
        );
        _postcheckHasAnchorState(GameType.wrap(1));
        checkDGFProxyAndGames();
        checkPermissionedDisputeGame();
        checkFaultDisputeGame();
        checkMips();
        console.log("All assertions passed!");
    }

    function _checkDisputeGameImplementation(
        GameType _targetGameType,
        address _newImpl
    ) internal view {
        console.log(
            "check dispute game implementations",
            _targetGameType.raw()
        );

        require(
            _newImpl == address(dgfProxy.gameImpls(_targetGameType)),
            "check-100"
        );
    }

    function _postcheckAnchorStateCopy(
        GameType _gameType,
        bytes32 _root,
        uint256 _l2BlockNumber
    ) internal view {
        console.log("check anchor state value", _gameType.raw());
    }

    // @notice Checks the anchor state for the source game type still exists after re-initialization.
    // The actual anchor state may have been updated since the task was defined so just assert it exists, not that
    // it has a specific value.
    function _postcheckHasAnchorState(GameType _gameType) internal view {
        console.log("check anchor state exists", _gameType.raw());

        FaultDisputeGame impl = FaultDisputeGame(
            address(dgfProxy.gameImpls(GameType(_gameType)))
        );
        (Hash root, uint256 rootBlockNumber) = FaultDisputeGame(address(impl))
            .anchorStateRegistry()
            .anchors(_gameType);

        require(root.raw() != bytes32(0), "check-300");
        require(rootBlockNumber != 0, "check-310");
    }

    function checkDGFProxyAndGames() internal view {
        console.log("check dispute game implementations");
        require(
            address(faultDisputeGame) ==
                address(dgfProxy.gameImpls(GameTypes.CANNON)),
            "dgf-100"
        );
        require(
            address(permissionedDisputeGame) ==
                address(dgfProxy.gameImpls(GameTypes.PERMISSIONED_CANNON)),
            "dgf-200"
        );

        require(faultDisputeGame.version().eq(gameVersion), "game-100");
        require(permissionedDisputeGame.version().eq(gameVersion), "game-200");

        require(
            faultDisputeGame.absolutePrestate().raw() == absolutePrestate,
            "game-300"
        );
        require(
            permissionedDisputeGame.absolutePrestate().raw() ==
                absolutePrestate,
            "game-400"
        );

        require(address(faultDisputeGame.vm()) == newMips, "game-500");
        require(address(permissionedDisputeGame.vm()) == newMips, "game-600");

        require(faultDisputeGame.l2ChainId() == chainId, "game-700");
        require(permissionedDisputeGame.l2ChainId() == chainId, "game-800");
    }
    /// @notice Checks that the FaultDisputeGame was handled correctly.
    function checkFaultDisputeGame() internal view {
        // Check that the FaultDisputeGame version is correct.
        require(
            LibString.eq(expectedFaultDisputeGameImpl.version(), gameVersion),
            "checkFaultDisputeGame-21"
        );

        // Check that only bytecode diffs vs comparison contract are expected.
        BytecodeComparison.Diff[] memory diffs = new BytecodeComparison.Diff[](
            12
        );
        diffs[0] = BytecodeComparison.Diff({
            start: 1319,
            content: abi.encode(expectedDelayedWETHProxy)
        });
        diffs[1] = BytecodeComparison.Diff({
            start: 1555,
            content: abi.encode(proxies.AnchorStateRegistry)
        });
        diffs[2] = BytecodeComparison.Diff({
            start: 1926,
            content: abi.encode(absolutePrestate)
        });
        diffs[3] = BytecodeComparison.Diff({
            start: 2590,
            content: abi.encode(chainConfig.chainId)
        });
        diffs[4] = BytecodeComparison.Diff({
            start: 6026,
            content: abi.encode(proxies.AnchorStateRegistry)
        });
        diffs[5] = BytecodeComparison.Diff({
            start: 6476,
            content: abi.encode(expectedDelayedWETHProxy)
        });
        diffs[6] = BytecodeComparison.Diff({
            start: 9344,
            content: abi.encode(expectedDelayedWETHProxy)
        });
        diffs[7] = BytecodeComparison.Diff({
            start: 9704,
            content: abi.encode(proxies.AnchorStateRegistry)
        });
        diffs[8] = BytecodeComparison.Diff({
            start: 10730,
            content: abi.encode(expectedDelayedWETHProxy)
        });
        diffs[9] = BytecodeComparison.Diff({
            start: 12628,
            content: abi.encode(absolutePrestate)
        });
        diffs[10] = BytecodeComparison.Diff({
            start: 14649,
            content: abi.encode(chainConfig.chainId)
        });
        diffs[11] = BytecodeComparison.Diff({
            start: 15892,
            content: abi.encode(expectedDelayedWETHProxy)
        });

        require(
            BytecodeComparison.compare(
                address(comparisonFaultDisputeGameImpl),
                address(expectedFaultDisputeGameImpl),
                diffs
            ),
            "checkFaultDisputeGame-101"
        );
    }

    /// @notice Checks that the PermissionedDisputeGame was handled correctly.
    function checkPermissionedDisputeGame() internal view {
        // Check that the PermissionedDisputeGame version is correct.
        require(
            LibString.eq(
                expectedPermissionedDisputeGameImpl.version(),
                "1.3.1"
            ),
            "checkPermissionedDisputeGame-20"
        );

        // Check that only bytecode diffs vs comparison contract are expected.
        BytecodeComparison.Diff[] memory diffs = new BytecodeComparison.Diff[](
            19
        );

        diffs[0] = BytecodeComparison.Diff({
            start: 1341,
            content: abi.encode(expectedPermissionedDelayedWETHProxy)
        });
        diffs[1] = BytecodeComparison.Diff({
            start: 1411,
            content: abi.encode(chainConfig.challenger)
        });
        diffs[2] = BytecodeComparison.Diff({
            start: 1628,
            content: abi.encode(proxies.AnchorStateRegistry)
        });
        diffs[3] = BytecodeComparison.Diff({
            start: 1999,
            content: abi.encode(absolutePrestate)
        });
        diffs[4] = BytecodeComparison.Diff({
            start: 2254,
            content: abi.encode(chainConfig.proposer)
        });
        diffs[5] = BytecodeComparison.Diff({
            start: 2714,
            content: abi.encode(chainConfig.chainId)
        });
        diffs[6] = BytecodeComparison.Diff({
            start: 6150,
            content: abi.encode(proxies.AnchorStateRegistry)
        });
        diffs[7] = BytecodeComparison.Diff({
            start: 6600,
            content: abi.encode(expectedPermissionedDelayedWETHProxy)
        });
        diffs[8] = BytecodeComparison.Diff({
            start: 6870,
            content: abi.encode(chainConfig.proposer)
        });
        diffs[9] = BytecodeComparison.Diff({
            start: 6933,
            content: abi.encode(chainConfig.challenger)
        });
        diffs[10] = BytecodeComparison.Diff({
            start: 7076,
            content: abi.encode(chainConfig.proposer)
        });
        diffs[11] = BytecodeComparison.Diff({
            start: 8310,
            content: abi.encode(chainConfig.proposer)
        });
        diffs[12] = BytecodeComparison.Diff({
            start: 8373,
            content: abi.encode(chainConfig.challenger)
        });
        diffs[13] = BytecodeComparison.Diff({
            start: 9555,
            content: abi.encode(chainConfig.chainId)
        });
        diffs[14] = BytecodeComparison.Diff({
            start: 10798,
            content: abi.encode(expectedPermissionedDelayedWETHProxy)
        });
        diffs[15] = BytecodeComparison.Diff({
            start: 13599,
            content: abi.encode(expectedPermissionedDelayedWETHProxy)
        });
        diffs[16] = BytecodeComparison.Diff({
            start: 13946,
            content: abi.encode(proxies.AnchorStateRegistry)
        });
        diffs[17] = BytecodeComparison.Diff({
            start: 14972,
            content: abi.encode(expectedPermissionedDelayedWETHProxy)
        });
        diffs[18] = BytecodeComparison.Diff({
            start: 17022,
            content: abi.encode(absolutePrestate)
        });

        require(
            BytecodeComparison.compare(
                address(comparisonPermissionedDisputeGameImpl),
                address(expectedPermissionedDisputeGameImpl),
                diffs
            ),
            "checkPermissionedDisputeGame-100"
        );
    }

    function checkMips() internal view {
        console.log("check MIPS");
        require(newMips.code.length != 0, "MIPS-100");
        vm.assertEq(ISemver(newMips).version(), "1.2.1");
        require(address(MIPS(newMips).oracle()) == oracle, "MIPS-200");
    }
}
