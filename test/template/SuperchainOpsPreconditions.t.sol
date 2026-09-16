// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";

import {AddGameTypeTemplate} from "src/template/AddGameTypeTemplate.sol";
import {SetRespectedGameTypeTemplate} from "src/template/SetRespectedGameTypeTemplate.sol";
import {SetBatcherAndOrSigner} from "src/template/SetBatcherAndOrSigner.sol";
import {SystemConfigGasLimit} from "src/template/SystemConfigGasLimit.sol";
import {OPCMUpgradeV700} from "src/template/OPCMUpgradeV700.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";

contract MockSystemConfigForSequencerUpdate {
    bytes32 public batcherHash;
    address public unsafeBlockSigner;
    address public owner;

    constructor(address batcher, address signer, address owner_) {
        batcherHash = bytes32(uint256(uint160(batcher)));
        unsafeBlockSigner = signer;
        owner = owner_;
    }
}

contract MockOptimismPortalForV700 {
    address public superchainConfig;

    constructor(address superchainConfig_) {
        superchainConfig = superchainConfig_;
    }
}

contract MockSystemConfigForV700 {
    address public optimismPortal;
    address public disputeGameFactory;

    constructor(address optimismPortal_, address disputeGameFactory_) {
        optimismPortal = optimismPortal_;
        disputeGameFactory = disputeGameFactory_;
    }
}

contract MockProxyAdminForV700 {
    address public owner;
    mapping(address => address) internal admins;

    constructor(address owner_) {
        owner = owner_;
    }

    function setProxyAdmin(address proxy, address admin) external {
        admins[proxy] = admin;
    }

    function getProxyAdmin(address payable proxy) external view returns (address) {
        return admins[proxy];
    }
}

contract MockDisputeGameFactoryForV700 {
    address public owner;

    constructor(address owner_) {
        owner = owner_;
    }
}

contract AddGameTypeTemplateHarness is AddGameTypeTemplate {
    function requireGameTypeUnregistered(address implementation) external pure {
        _requireGameTypeUnregistered(implementation);
    }

    function requireMatchingDisputeGameFactory(address actual, address expected) external pure {
        _requireMatchingDisputeGameFactory(actual, expected);
    }
}

contract SetRespectedGameTypeTemplateHarness is SetRespectedGameTypeTemplate {
    function requireGameTypeRegistered(address implementation) external pure {
        _requireGameTypeRegistered(implementation);
    }

    function requireMatchingDisputeGameFactory(address actual, address expected) external pure {
        _requireMatchingDisputeGameFactory(actual, expected);
    }

    function requireRootSafe(address rootSafe, address guardian) external pure {
        _requireRootSafe(rootSafe, guardian);
    }
}

contract SystemConfigGasLimitHarness is SystemConfigGasLimit {
    function requireValidGasLimit(uint64 gasLimit, uint64 minimum, uint64 maximum) external pure {
        _requireValidGasLimit(gasLimit, minimum, maximum);
    }

    function toUint64GasLimit(uint256 gasLimit) external pure returns (uint64) {
        return _toUint64GasLimit(gasLimit);
    }

    function requireRootSafe(address rootSafe, address owner) external pure {
        _requireRootSafe(rootSafe, owner);
    }
}

contract SetBatcherAndOrSignerHarness is SetBatcherAndOrSigner {
    function resolveTarget(address requested, bool updateRequested, address current) external pure returns (address) {
        return _resolveTarget(requested, updateRequested, current);
    }

    function requireRequestedUpdate(bool updateBatcher, bool updateUnsafeBlockSigner) external pure {
        _requireRequestedUpdate(updateBatcher, updateUnsafeBlockSigner);
    }

    function requireRootSafe(address rootSafe, address owner) external pure {
        _requireRootSafe(rootSafe, owner);
    }

    function templateSetup(string memory configPath, address rootSafe) external {
        superchainAddrRegistry = new SuperchainAddressRegistry(configPath);
        _templateSetup(configPath, rootSafe);
    }
}

contract OPCMUpgradeV700Harness is OPCMUpgradeV700 {
    function validateContractRelationships(
        address systemConfig,
        address superchainConfig,
        address proxyAdmin,
        address proxyAdminOwner,
        address disputeGameFactory,
        address rootSafe
    ) external view {
        _validateContractRelationships(
            systemConfig, superchainConfig, proxyAdmin, proxyAdminOwner, disputeGameFactory, rootSafe
        );
    }

    function expectedValidationErrors(
        bool l1PAOOverride,
        bool challengerOverride,
        bool superchainConfigMismatch,
        uint32 targetGameType
    ) external pure returns (string memory) {
        return _expectedValidationErrors(l1PAOOverride, challengerOverride, superchainConfigMismatch, targetGameType);
    }

    function parseUpgrade(string memory toml)
        external
        view
        returns (uint256 chainId, uint32 startingRespectedGameType)
    {
        OPCMUpgrade[] memory parsed = _parseUpgrades(toml);
        return (parsed[0].chainId, parsed[0].startingRespectedGameType);
    }
}

contract SuperchainOpsPreconditionsTest is Test {
    AddGameTypeTemplateHarness internal addGameType = new AddGameTypeTemplateHarness();
    SetRespectedGameTypeTemplateHarness internal setRespectedGameType = new SetRespectedGameTypeTemplateHarness();
    SystemConfigGasLimitHarness internal systemConfigGasLimit = new SystemConfigGasLimitHarness();
    SetBatcherAndOrSignerHarness internal setBatcherAndOrSigner = new SetBatcherAndOrSignerHarness();
    OPCMUpgradeV700Harness internal opcmUpgradeV700 = new OPCMUpgradeV700Harness();

    function testAddGameTypeRejectsRegisteredGameType() public {
        vm.expectRevert("AddGameType: Game type already registered");
        addGameType.requireGameTypeUnregistered(address(1));
    }

    function testAddGameTypeRejectsMismatchedDisputeGameFactory() public {
        vm.expectRevert("AddGameType: DisputeGameFactory mismatch");
        addGameType.requireMatchingDisputeGameFactory(address(1), address(2));
    }

    function testSetRespectedGameTypeRejectsUnregisteredGameType() public {
        vm.expectRevert("SetRespectedGameType: Game implementation is zero address");
        setRespectedGameType.requireGameTypeRegistered(address(0));
    }

    function testSetRespectedGameTypeRejectsMismatchedDisputeGameFactory() public {
        vm.expectRevert("SetRespectedGameType: DisputeGameFactory mismatch");
        setRespectedGameType.requireMatchingDisputeGameFactory(address(1), address(2));
    }

    function testSetRespectedGameTypeRejectsWrongRootSafe() public {
        vm.expectRevert("SetRespectedGameType: root safe is not Guardian");
        setRespectedGameType.requireRootSafe(address(1), address(2));
    }

    function testSystemConfigGasLimitRejectsGasLimitBelowMinimum() public {
        vm.expectRevert("SystemConfigGasLimit: gas limit below minimum");
        systemConfigGasLimit.requireValidGasLimit(29_999_999, 30_000_000, 60_000_000);
    }

    function testSystemConfigGasLimitRejectsGasLimitAboveMaximum() public {
        vm.expectRevert("SystemConfigGasLimit: gas limit above maximum");
        systemConfigGasLimit.requireValidGasLimit(60_000_001, 30_000_000, 60_000_000);
    }

    function testSystemConfigGasLimitAcceptsInclusiveBounds() public view {
        systemConfigGasLimit.requireValidGasLimit(30_000_000, 30_000_000, 60_000_000);
        systemConfigGasLimit.requireValidGasLimit(60_000_000, 30_000_000, 60_000_000);
    }

    function testSystemConfigGasLimitRejectsUint64Overflow() public {
        vm.expectRevert("SystemConfigGasLimit: gas limit exceeds uint64");
        systemConfigGasLimit.toUint64GasLimit(uint256(type(uint64).max) + 1);
    }

    function testSystemConfigGasLimitRejectsWrongRootSafe() public {
        vm.expectRevert("SystemConfigGasLimit: root safe is not SystemConfig owner");
        systemConfigGasLimit.requireRootSafe(address(1), address(2));
    }

    function testSetBatcherAndOrSignerResolvesOmittedTargetFromLiveState() public view {
        assertEq(setBatcherAndOrSigner.resolveTarget(address(0), false, address(3)), address(3));
    }

    function testSetBatcherAndOrSignerUsesRequestedTarget() public view {
        assertEq(setBatcherAndOrSigner.resolveTarget(address(2), true, address(3)), address(2));
    }

    function testSetBatcherAndOrSignerRejectsRequestedZeroTarget() public {
        vm.expectRevert("SetBatcherAndOrSigner: requested target is zero address");
        setBatcherAndOrSigner.resolveTarget(address(0), true, address(3));
    }

    function testSetBatcherAndOrSignerRejectsNoRequestedUpdates() public {
        vm.expectRevert("SetBatcherAndOrSigner: no update requested");
        setBatcherAndOrSigner.requireRequestedUpdate(false, false);
    }

    function testSetBatcherAndOrSignerRejectsWrongRootSafe() public {
        vm.expectRevert("SetBatcherAndOrSigner: root safe is not SystemConfig owner");
        setBatcherAndOrSigner.requireRootSafe(address(1), address(2));
    }

    function testSetBatcherAndOrSignerParsesRequestedFieldsAndFillsOmittedTarget() public {
        address owner = address(0x1111);
        address currentBatcher = address(0x2222);
        address currentSigner = address(0x3333);
        address requestedSigner = address(0x4444);
        MockSystemConfigForSequencerUpdate systemConfig =
            new MockSystemConfigForSequencerUpdate(currentBatcher, currentSigner, owner);

        string memory dir = "test/.superchain-ops-preconditions-explicit-flags";
        vm.createDir(dir, true);
        string memory addressesPath = string.concat(dir, "/addresses.json");
        string memory configPath = string.concat(dir, "/config.toml");
        vm.writeFile(
            addressesPath,
            string.concat(
                '{"4201234":{"SystemConfigProxy":"',
                vm.toString(address(systemConfig)),
                '","SystemConfigOwner":"',
                vm.toString(owner),
                '"}}'
            )
        );
        vm.writeFile(
            configPath,
            string.concat(
                'fallbackAddressesJsonPath = "',
                addressesPath,
                '"\nl2chains = [{name = "test", chainId = 4201234}]\n',
                "[sequencerConfig]\n",
                'batcherAddress = "0x0000000000000000000000000000000000000000"\n',
                'unsafeBlockSigner = "',
                vm.toString(requestedSigner),
                '"\nupdateBatcher = false\nupdateUnsafeBlockSigner = true\n'
            )
        );

        vm.chainId(11_155_111);
        setBatcherAndOrSigner.templateSetup(configPath, owner);
        (bytes32 batcherHash, address signer, bool updateBatcher, bool updateUnsafeBlockSigner) =
            setBatcherAndOrSigner.cfg(4_201_234);
        assertEq(batcherHash, bytes32(uint256(uint160(currentBatcher))));
        assertEq(signer, requestedSigner);
        assertFalse(updateBatcher);
        assertTrue(updateUnsafeBlockSigner);
        vm.removeDir(dir, true);
    }

    function testSetBatcherAndOrSignerLegacyConfigUpdatesOnlyChangedField() public {
        address owner = address(0x1111);
        address currentBatcher = address(0x2222);
        address currentSigner = address(0x3333);
        address requestedSigner = address(0x4444);
        MockSystemConfigForSequencerUpdate systemConfig =
            new MockSystemConfigForSequencerUpdate(currentBatcher, currentSigner, owner);

        string memory dir = "test/.superchain-ops-preconditions-legacy-flags";
        vm.createDir(dir, true);
        string memory addressesPath = string.concat(dir, "/addresses.json");
        string memory configPath = string.concat(dir, "/config.toml");
        vm.writeFile(
            addressesPath,
            string.concat(
                '{"4201234":{"SystemConfigProxy":"',
                vm.toString(address(systemConfig)),
                '","SystemConfigOwner":"',
                vm.toString(owner),
                '"}}'
            )
        );
        vm.writeFile(
            configPath,
            string.concat(
                'fallbackAddressesJsonPath = "',
                addressesPath,
                '"\nl2chains = [{name = "test", chainId = 4201234}]\n',
                "[sequencerConfig]\n",
                'batcherAddress = "',
                vm.toString(currentBatcher),
                '"\nunsafeBlockSigner = "',
                vm.toString(requestedSigner),
                '"\n'
            )
        );

        vm.chainId(11_155_111);
        setBatcherAndOrSigner.templateSetup(configPath, owner);
        (bytes32 batcherHash, address signer, bool updateBatcher, bool updateUnsafeBlockSigner) =
            setBatcherAndOrSigner.cfg(4_201_234);
        assertEq(batcherHash, bytes32(uint256(uint160(currentBatcher))));
        assertEq(signer, requestedSigner);
        assertFalse(updateBatcher);
        assertTrue(updateUnsafeBlockSigner);
        vm.removeDir(dir, true);
    }

    function testOPCMUpgradeV700ValidatesRealContractRelationships() public {
        address rootSafe = address(0x1111);
        address superchainConfig = address(0x2222);
        MockOptimismPortalForV700 portal = new MockOptimismPortalForV700(superchainConfig);
        MockDisputeGameFactoryForV700 factory = new MockDisputeGameFactoryForV700(rootSafe);
        MockSystemConfigForV700 systemConfig = new MockSystemConfigForV700(address(portal), address(factory));
        MockProxyAdminForV700 proxyAdmin = new MockProxyAdminForV700(rootSafe);
        proxyAdmin.setProxyAdmin(address(systemConfig), address(proxyAdmin));

        opcmUpgradeV700.validateContractRelationships(
            address(systemConfig), superchainConfig, address(proxyAdmin), rootSafe, address(factory), rootSafe
        );
    }

    function testOPCMUpgradeV700RejectsWrongPortalSuperchainConfig() public {
        address rootSafe = address(0x1111);
        MockOptimismPortalForV700 portal = new MockOptimismPortalForV700(address(0x2222));
        MockDisputeGameFactoryForV700 factory = new MockDisputeGameFactoryForV700(rootSafe);
        MockSystemConfigForV700 systemConfig = new MockSystemConfigForV700(address(portal), address(factory));
        MockProxyAdminForV700 proxyAdmin = new MockProxyAdminForV700(rootSafe);
        proxyAdmin.setProxyAdmin(address(systemConfig), address(proxyAdmin));

        vm.expectRevert("OPCMUpgradeV700: OptimismPortal SuperchainConfig mismatch");
        opcmUpgradeV700.validateContractRelationships(
            address(systemConfig), address(0x3333), address(proxyAdmin), rootSafe, address(factory), rootSafe
        );
    }

    function testOPCMUpgradeV700ComputesExpectedValidationErrorsInOrder() public view {
        assertEq(
            opcmUpgradeV700.expectedValidationErrors(true, true, true, 1),
            "OVERRIDES-L1PAOMULTISIG,OVERRIDES-CHALLENGER,SYSCON-130,CKDG-NOSHAPE,PLDG-10,CKDG-10"
        );
        assertEq(opcmUpgradeV700.expectedValidationErrors(false, false, false, 8), "PLDG-10");
    }

    function testOPCMUpgradeV700ParsesConfigWithoutExpectedValidationErrors() public view {
        string memory toml = "[[opcmUpgrades]]\n"
            "cannonKonaPrestate = \"0x0000000000000000000000000000000000000000000000000000000000000000\"\n"
            "cannonPrestate = \"0x1111111111111111111111111111111111111111111111111111111111111111\"\n"
            "chainId = 4201234\n" "initBond = 0\n" "startingRespectedGameType = 1\n";
        (uint256 chainId, uint32 gameType) = opcmUpgradeV700.parseUpgrade(toml);
        assertEq(chainId, 4_201_234);
        assertEq(gameType, 1);
    }

    function testOPCMUpgradeV700IgnoresLegacyExpectedValidationErrorsField() public view {
        string memory toml = "[[opcmUpgrades]]\n"
            "cannonKonaPrestate = \"0x0000000000000000000000000000000000000000000000000000000000000000\"\n"
            "cannonPrestate = \"0x1111111111111111111111111111111111111111111111111111111111111111\"\n"
            "chainId = 4201234\n" "expectedValidationErrors = \"legacy-value\"\n" "initBond = 0\n"
            "startingRespectedGameType = 1\n";
        (uint256 chainId, uint32 gameType) = opcmUpgradeV700.parseUpgrade(toml);
        assertEq(chainId, 4_201_234);
        assertEq(gameType, 1);
    }
}
