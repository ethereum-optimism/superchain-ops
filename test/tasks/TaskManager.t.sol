// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {TaskManager} from "src/tasks/TaskManager.sol";
import {AccountAccessParser} from "src/libraries/AccountAccessParser.sol";
import {StateOverrideManager} from "src/tasks/StateOverrideManager.sol";
import {TaskConfig, L2Chain} from "src/libraries/MultisigTypes.sol";
import {Vm} from "forge-std/Vm.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {SystemConfigGasParams} from "src/template/SystemConfigGasParams.sol";
import {RevShareUpgradeAndSetup} from "src/template/RevShareUpgradeAndSetup.sol";

contract TaskManagerUnitTest is StateOverrideManager, Test {
    using LibString for string;

    address public constant OP_MAINNET_L1PAO = 0x5a0Aae59D09fccBdDb6C6CcEB07B7279367C3d2A;
    address public constant BASE_L1PAO = 0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c;
    address public constant BASE_NESTED_SAFE = 0x9855054731540A48b28990B63DcF4f33d8AE46A1;
    address public constant FOUNDATION_OPERATIONS_SAFE = 0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A;
    address public constant FOUNDATION_UPGRADE_SAFE = 0x847B5c174615B1B7fDF770882256e2D3E95b9D92;
    address public constant UNICHAIN_L1PAO = 0x6d5B183F538ABB8572F5cD17109c617b994D5833;

    function setUp() public {}

    function testSetTenderlyGasEnv() public {
        TaskManager tm = new TaskManager();

        tm.setEnv("./src/tasks/sep/000-opcm-upgrade-v200/");
        assertEq(vm.envString("TENDERLY_GAS"), "30000000");

        tm.setEnv("./src/tasks/sep/001-opcm-upgrade-v200/");
        assertEq(vm.envString("TENDERLY_GAS"), "16000000");

        tm.setEnv("./src/tasks/sep/002-unichain-superchain-config-fix/");
        assertEq(vm.envString("TENDERLY_GAS"), "");

        tm.setEnv("./src/tasks/sep/003-opcm-upgrade-v200/");
        assertEq(vm.envString("TENDERLY_GAS"), "16000000");

        tm.setEnv("./src/tasks/eth/000-opcm-upgrade-v200/");
        assertEq(vm.envString("TENDERLY_GAS"), "30000000");

        tm.setEnv("./src/tasks/eth/002-opcm-upgrade-v200/");
        assertEq(vm.envString("TENDERLY_GAS"), "16000000");

        // Test loading multiple environment variables including FORK_BLOCK_NUMBER
        tm.setEnv("./src/tasks/eth/032-U17-main-op-sony-ink/");
        assertEq(vm.envString("TENDERLY_GAS"), "30000000");
    }

    function createStateDiff(address who, bytes32 slot, bytes32 oldValue, bytes32 newValue)
        public
        pure
        returns (AccountAccessParser.DecodedStateDiff memory)
    {
        return AccountAccessParser.DecodedStateDiff({
            who: who,
            l2ChainId: 10,
            contractName: "N/A",
            raw: AccountAccessParser.StateDiff({slot: slot, oldValue: oldValue, newValue: newValue}),
            decoded: AccountAccessParser.DecodedSlot({
                kind: "uint256",
                oldValue: "N/A",
                newValue: "N/A",
                summary: "N/A",
                detail: "N/A"
            })
        });
    }

    function testRequireSignerOnSafe_FailsIfSignerIsNotOwner() public {
        vm.createSelectFork("mainnet", 22433511); // Pinning to a block.
        TaskManager tm = new TaskManager();
        address safe = FOUNDATION_OPERATIONS_SAFE;
        address signer = 0xEbE2cdF322646D8Aa36CED4A3072FCAe7F0a9B0b;
        string memory errorMessage = string.concat(
            "TaskManager: signer ", vm.toString(signer), " is not an owner on the safe: ", vm.toString(safe)
        );
        vm.expectRevert(bytes(errorMessage));
        tm.requireSignerOnSafe(signer, "src/tasks/eth/011-deputy-pause-module-activation");
        vm.expectRevert(bytes(errorMessage));
        tm.requireSignerOnSafe(signer, safe);
    }

    function testRequireSignerOnSafe_PassesIfSignerIsOwner() public {
        vm.createSelectFork("mainnet", 22433511); // Pinning to a block.
        TaskManager tm = new TaskManager();
        address signer = 0xBF93D4d727F7Ba1F753E1124C3e532dCb04Ea2c8;
        address safe = FOUNDATION_OPERATIONS_SAFE;
        tm.requireSignerOnSafe(signer, "src/tasks/eth/011-deputy-pause-module-activation");
        tm.requireSignerOnSafe(signer, safe);
    }

    function testDataToSignCheck_Passes() public {
        vm.createSelectFork("mainnet"); // Pinning to a block.
        TaskManager tm = new TaskManager();
        TaskConfig memory config = TaskConfig({
            optionalL2Chains: new L2Chain[](0),
            basePath: "test/tasks/example/eth/004-fp-set-respected-game-type",
            configPath: "",
            templateName: "",
            rootSafe: FOUNDATION_UPGRADE_SAFE,
            isNested: true,
            task: address(0)
        });
        bytes memory dataToSign =
            hex"1901a4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b732672f654f4cec87ea0aee5f1632a35fe9184a0ab53cd9a6c3d86fdcd0fdb446abf76";

        // Doesn't have a VALIDATION markdown file.
        assertTrue(tm.checkDataToSign(dataToSign, config));

        // Does have a VALIDATION markdown file and domain and message hash matches.
        config.basePath = "src/tasks/eth/013-gas-params-op";
        assertTrue(tm.checkDataToSign(dataToSign, config));
    }

    function testDataToSignCheck_Fails() public {
        TaskManager tm = new TaskManager();
        TaskConfig memory config = TaskConfig({
            optionalL2Chains: new L2Chain[](0),
            basePath: "src/tasks/eth/013-gas-params-op",
            configPath: "",
            templateName: "",
            rootSafe: FOUNDATION_UPGRADE_SAFE,
            isNested: true,
            task: address(0)
        });
        bytes memory fakeDataToSign =
            hex"190111111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000";
        // Does have a VALIDATION markdown file and data to sign does not match.
        assertFalse(tm.checkDataToSign(fakeDataToSign, config));
    }

    function testSetupDefaultChildSafes_RootSafeHasMultiLevelNesting() public {
        vm.createSelectFork("mainnet", 23025164);
        TaskManagerHarness tmHarness = new TaskManagerHarness();
        address rootSafe = BASE_L1PAO;
        address[] memory rootSafeOwners = IGnosisSafe(rootSafe).getOwners();
        address[] memory emptyChildSafes = new address[](0);
        address[] memory resultChildSafes = tmHarness.exposed_setupDefaultChildSafes(emptyChildSafes, rootSafe);
        // Should return 2-element array for nested-nested execution
        assertEq(resultChildSafes.length, 2, "Should have 2 child safes for nested-nested execution");
        address[] memory firstOwnerOwners = IGnosisSafe(rootSafeOwners[0]).getOwners();
        address leafChildSafe = firstOwnerOwners[0];
        assertEq(resultChildSafes[0], leafChildSafe, "First element should be leaf child safe");
        assertEq(resultChildSafes[1], rootSafeOwners[0], "Second element should be first root safe owner");
        assertTrue(resultChildSafes.length == 2, "Should have 2 child safes for nested-nested execution");
    }

    function testSetupDefaultChildSafes_RootSafeHasOneLevelOfNesting() public {
        vm.createSelectFork("mainnet", 23025164);
        TaskManagerHarness tmHarness = new TaskManagerHarness();
        address rootSafe = OP_MAINNET_L1PAO;
        address[] memory rootSafeOwners = IGnosisSafe(rootSafe).getOwners();
        address[] memory emptyChildSafes = new address[](0);
        address[] memory resultChildSafes = tmHarness.exposed_setupDefaultChildSafes(emptyChildSafes, rootSafe);
        bool isFirstOwnerNested = tmHarness.exposed_isNestedSafe(rootSafeOwners[0]);
        // Should return 1-element array for single-level nested execution
        assertEq(resultChildSafes.length, 1, "Should have 1 child safe for single-level nested execution");
        assertFalse(isFirstOwnerNested, "First owner should not be nested for single-level nesting");
        assertTrue(resultChildSafes.length == 1, "Should have 1 child safe for single-level nested execution");
    }

    /// Note: This test is intentionally not pinned to a block. If it fails, it means Base has updated their safe architecture.
    function testIsNestedNestedSafe() public {
        vm.createSelectFork("mainnet", 23336141);
        TaskManagerHarness tmHarness = new TaskManagerHarness();

        // Test the nested-nested safe (should return true)
        address nestedNestedSafe = BASE_L1PAO;
        (bool isNestedNested, address depth1ChildSafe) = tmHarness.exposed_isNestedNestedSafe(nestedNestedSafe);
        assertTrue(isNestedNested, string.concat(vm.toString(nestedNestedSafe), " should be nested-nested"));
        assertEq(depth1ChildSafe, BASE_NESTED_SAFE, "Depth 1 child safe should be BASE_NESTED_SAFE");

        // Test the single-level nested safe (should return false)
        address singleNestedSafe = OP_MAINNET_L1PAO;
        (bool isNestedNestedOP, address depth1ChildSafeOP) = tmHarness.exposed_isNestedNestedSafe(singleNestedSafe);
        assertFalse(isNestedNestedOP, string.concat(vm.toString(singleNestedSafe), " should not be nested-nested"));
        assertEq(depth1ChildSafeOP, address(0), "Depth 1 child safe should be zero address");
    }

    /// @notice Test that the root safe is correctly retrieved for a given task.
    function testGetRootSafe() public {
        vm.createSelectFork("mainnet", 23025164); // Pinning to a block for consistency
        TaskManager tm = new TaskManager();
        string memory taskConfigPath = "src/tasks/eth/000-opcm-upgrade-v200/config.toml";
        address rootSafe = tm.getRootSafe(taskConfigPath);

        assertTrue(rootSafe != address(0), "Root safe should not be zero address");
        address[] memory owners = IGnosisSafe(rootSafe).getOwners();
        assertTrue(owners.length > 0, "Root safe should have owners");
        assertEq(rootSafe, OP_MAINNET_L1PAO);

        string memory anotherTaskConfigPath = "src/tasks/eth/002-opcm-upgrade-v200/config.toml";
        address anotherRootSafe = tm.getRootSafe(anotherTaskConfigPath);
        assertTrue(anotherRootSafe != address(0), "Another root safe should not be zero address");
        address[] memory owners2 = IGnosisSafe(anotherRootSafe).getOwners();
        assertTrue(owners2.length > 0, "Another root safe should have owners");
        assertEq(anotherRootSafe, UNICHAIN_L1PAO);
    }

    function testValidateTaskFails() public {
        TaskManager tm = new TaskManager();
        vm.expectRevert("TaskManager: config.toml file does not exist: test");
        tm.validateTask("test");
    }

    function testExecuteViaTaskManager() public {
        vm.createSelectFork("mainnet", 22283936);
        SystemConfigGasParams gasTemplate = new SystemConfigGasParams();
        TaskManager tm = new TaskManager();
        L2Chain[] memory l2Chains = new L2Chain[](1);
        l2Chains[0] = L2Chain({chainId: 10, name: "OP Mainnet"});
        (, bytes[] memory dataToSign) = tm.executeTask(
            TaskConfig({
                optionalL2Chains: l2Chains,
                basePath: "test/tasks/example/eth/006-system-config-gas-params",
                configPath: "test/tasks/example/eth/006-system-config-gas-params/config.toml",
                templateName: "SystemConfigGasParams",
                rootSafe: FOUNDATION_UPGRADE_SAFE,
                isNested: false,
                task: address(gasTemplate)
            }),
            new address[](0)
        );
        bytes memory expectedDataToSign =
            hex"1901a4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b73267249771935e440b6212f2f0a8302967dcac81b52ea7573563fd25b9b7ee33d8b3e";
        assertEq(keccak256(dataToSign[0]), keccak256(expectedDataToSign));
    }

    function testExecuteViaTaskManager_NestedSafe() public {
        vm.createSelectFork("mainnet", 24047420);

        RevShareUpgradeAndSetup revShareTemplate = new RevShareUpgradeAndSetup();
        TaskManager tm = new TaskManager();

        L2Chain[] memory l2Chains = new L2Chain[](2);
        l2Chains[0] = L2Chain({chainId: 57073, name: "Ink"});
        l2Chains[1] = L2Chain({chainId: 1868, name: "Soneium"});

        (, bytes[] memory dataToSign) = tm.executeTask(
            TaskConfig({
                optionalL2Chains: l2Chains,
                basePath: "src/tasks/eth/037-rev-share-ink-soneium",
                configPath: "src/tasks/eth/037-rev-share-ink-soneium/config.toml",
                templateName: "RevShareUpgradeAndSetup",
                rootSafe: OP_MAINNET_L1PAO,
                isNested: true,
                task: address(revShareTemplate)
            }),
            new address[](0)
        );

        // For nested safe tasks, dataToSign should have 2 entries (Foundation + Council)
        bytes memory expectedDataToSignFoundation =
            hex"1901a4a9c312badf3fcaa05eafe5dc9bee8bd9316c78ee8b0bebe3115bb21b73267254ce340c4739a7b821abc9a4d1fc553ef3eab9af2a4f6d6cd8b029e254050c0f";
        bytes memory expectedDataToSignCouncil =
            hex"1901df53d510b56e539b90b369ef08fce3631020fbf921e3136ea5f8747c20bce967ddd5bfdade4e3e69c2a1055039c1f159b6fc48e52a21206cbaf0828ec7f06008";
        assertEq(keccak256(dataToSign[0]), keccak256(expectedDataToSignFoundation));
        assertEq(keccak256(dataToSign[1]), keccak256(expectedDataToSignCouncil));
    }
}

// Test harness to expose internal functions
contract TaskManagerHarness is TaskManager {
    function exposed_setupDefaultChildSafes(address[] memory _childSafes, address _rootSafe)
        public
        view
        returns (address[] memory)
    {
        return setupDefaultChildSafes(_childSafes, _rootSafe);
    }

    function exposed_isNestedSafe(address safe) public view returns (bool) {
        return isNestedSafe(safe);
    }

    function exposed_isNestedNestedSafe(address safe) public view returns (bool, address) {
        return isNestedNestedSafe(safe);
    }
}
