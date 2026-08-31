// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";

import {OPCMUpgradeV800} from "src/template/OPCMUpgradeV800.sol";

contract MockV800SystemConfig {
    address internal immutable _disputeGameFactory;

    constructor(address disputeGameFactory_) {
        _disputeGameFactory = disputeGameFactory_;
    }

    function disputeGameFactory() external view returns (address) {
        return _disputeGameFactory;
    }
}

contract MockV800SuperchainConfig {
    address internal immutable _guardian;

    constructor(address guardian_) {
        _guardian = guardian_;
    }

    function guardian() external view returns (address) {
        return _guardian;
    }
}

contract MockV800Portal {
    address internal immutable _superchainConfig;
    address internal immutable _systemConfig;

    constructor(address superchainConfig_, address systemConfig_) {
        _superchainConfig = superchainConfig_;
        _systemConfig = systemConfig_;
    }

    function superchainConfig() external view returns (address) {
        return _superchainConfig;
    }

    function systemConfig() external view returns (address) {
        return _systemConfig;
    }
}

contract MockV800Owned {
    address internal immutable _owner;

    constructor(address owner_) {
        _owner = owner_;
    }

    function owner() external view returns (address) {
        return _owner;
    }
}

contract MockV800ProxyAdmin {
    address internal immutable _owner;
    mapping(address => address) internal _admins;

    constructor(address owner_) {
        _owner = owner_;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function setProxyAdmin(address proxy, address admin) external {
        _admins[proxy] = admin;
    }

    function getProxyAdmin(address payable proxy) external view returns (address) {
        return _admins[proxy];
    }
}

contract MockV800Safe {
    function getOwners() external pure returns (address[] memory owners) {
        owners = new address[](1);
        owners[0] = address(0x1234);
    }
}

contract OPCMUpgradeV800PreconditionsHarness is OPCMUpgradeV800 {
    function parseUpgrade(string memory toml)
        external
        view
        returns (uint256 chainId, uint32 startingRespectedGameType)
    {
        OPCMUpgrade[] memory parsed = _parseUpgrades(toml);
        return (parsed[0].chainId, parsed[0].startingRespectedGameType);
    }

    function validateRelationships(
        address systemConfig,
        address optimismPortal,
        address superchainConfig,
        address proxyAdmin,
        address proxyAdminOwner,
        address disputeGameFactory,
        address rootSafe
    ) external view {
        _validateContractRelationships(
            systemConfig, optimismPortal, superchainConfig, proxyAdmin, proxyAdminOwner, disputeGameFactory, rootSafe
        );
    }

    function expectedValidationErrors(
        address proxyAdminOwner,
        address challenger,
        address superchainConfig,
        address standardL1PAO,
        address standardChallenger,
        address standardSuperchainConfig,
        bool konaWasRegistered,
        uint32 startingRespectedGameType
    ) external pure returns (string memory) {
        return _expectedValidationErrors(
            ValidationErrorInputs({
                challenger: challenger,
                konaWasRegistered: konaWasRegistered,
                proxyAdminOwner: proxyAdminOwner,
                startingRespectedGameType: startingRespectedGameType,
                standardChallenger: standardChallenger,
                standardL1PAO: standardL1PAO,
                standardSuperchainConfig: standardSuperchainConfig,
                superchainConfig: superchainConfig
            })
        );
    }
}

contract OPCMUpgradeV800PreconditionsTest is Test {
    address internal constant GUARDIAN = address(0x3333);
    address internal constant CHALLENGER = address(0x4444);

    OPCMUpgradeV800PreconditionsHarness internal harness;
    MockV800Safe internal rootSafe;
    MockV800ProxyAdmin internal proxyAdmin;
    MockV800Owned internal disputeGameFactory;
    MockV800SuperchainConfig internal superchainConfig;
    MockV800SystemConfig internal systemConfig;
    MockV800Portal internal optimismPortal;

    function setUp() public {
        harness = new OPCMUpgradeV800PreconditionsHarness();
        rootSafe = new MockV800Safe();
        proxyAdmin = new MockV800ProxyAdmin(address(rootSafe));
        disputeGameFactory = new MockV800Owned(address(rootSafe));
        superchainConfig = new MockV800SuperchainConfig(GUARDIAN);
        systemConfig = new MockV800SystemConfig(address(disputeGameFactory));
        proxyAdmin.setProxyAdmin(address(systemConfig), address(proxyAdmin));
        optimismPortal = new MockV800Portal(address(superchainConfig), address(systemConfig));
    }

    function _validate(address sysCfg, address portal, address sc, address pa, address pao, address dgf, address root)
        internal
        view
    {
        harness.validateRelationships(sysCfg, portal, sc, pa, pao, dgf, root);
    }

    function test_validateContractRelationships_acceptsAuthorizedRootSafe() public view {
        _validate(
            address(systemConfig),
            address(optimismPortal),
            address(superchainConfig),
            address(proxyAdmin),
            address(rootSafe),
            address(disputeGameFactory),
            address(rootSafe)
        );
    }

    function test_validateContractRelationships_rejectsWrongPortalSuperchainConfig() public {
        MockV800Portal wrong = new MockV800Portal(address(0xdead), address(systemConfig));
        vm.expectRevert("OPCMUpgradeV800: OptimismPortal SuperchainConfig mismatch");
        _validate(
            address(systemConfig),
            address(wrong),
            address(superchainConfig),
            address(proxyAdmin),
            address(rootSafe),
            address(disputeGameFactory),
            address(rootSafe)
        );
    }

    function test_validateContractRelationships_rejectsWrongSystemConfigDisputeGameFactory() public {
        MockV800SystemConfig wrong = new MockV800SystemConfig(address(0xdead));
        MockV800Portal matchingPortal = new MockV800Portal(address(superchainConfig), address(wrong));
        vm.expectRevert("OPCMUpgradeV800: SystemConfig DisputeGameFactory mismatch");
        _validate(
            address(wrong),
            address(matchingPortal),
            address(superchainConfig),
            address(proxyAdmin),
            address(rootSafe),
            address(disputeGameFactory),
            address(rootSafe)
        );
    }

    function test_validateContractRelationships_rejectsUnauthorizedRootSafe() public {
        vm.expectRevert("OPCMUpgradeV800: rootSafe is not ProxyAdminOwner");
        _validate(
            address(systemConfig),
            address(optimismPortal),
            address(superchainConfig),
            address(proxyAdmin),
            address(rootSafe),
            address(disputeGameFactory),
            address(0xbeef)
        );
    }

    function test_validateContractRelationships_rejectsWrongProxyAdminOwner() public {
        MockV800ProxyAdmin wrongProxyAdmin = new MockV800ProxyAdmin(address(0xdead));
        wrongProxyAdmin.setProxyAdmin(address(systemConfig), address(wrongProxyAdmin));
        vm.expectRevert("OPCMUpgradeV800: ProxyAdmin owner mismatch");
        _validate(
            address(systemConfig),
            address(optimismPortal),
            address(superchainConfig),
            address(wrongProxyAdmin),
            address(rootSafe),
            address(disputeGameFactory),
            address(rootSafe)
        );
    }

    function test_validateContractRelationships_rejectsWrongSystemConfigProxyAdmin() public {
        MockV800ProxyAdmin wrongProxyAdmin = new MockV800ProxyAdmin(address(rootSafe));
        wrongProxyAdmin.setProxyAdmin(address(systemConfig), address(0xdead));
        vm.expectRevert("OPCMUpgradeV800: SystemConfig ProxyAdmin mismatch");
        _validate(
            address(systemConfig),
            address(optimismPortal),
            address(superchainConfig),
            address(wrongProxyAdmin),
            address(rootSafe),
            address(disputeGameFactory),
            address(rootSafe)
        );
    }

    function test_validateContractRelationships_rejectsWrongDisputeGameFactoryOwner() public {
        MockV800Owned wrongFactory = new MockV800Owned(address(0xdead));
        MockV800SystemConfig matchingSystemConfig = new MockV800SystemConfig(address(wrongFactory));
        MockV800Portal matchingPortal = new MockV800Portal(address(superchainConfig), address(matchingSystemConfig));
        proxyAdmin.setProxyAdmin(address(matchingSystemConfig), address(proxyAdmin));
        vm.expectRevert("OPCMUpgradeV800: DisputeGameFactory owner mismatch");
        _validate(
            address(matchingSystemConfig),
            address(matchingPortal),
            address(superchainConfig),
            address(proxyAdmin),
            address(rootSafe),
            address(wrongFactory),
            address(rootSafe)
        );
    }

    function test_validateContractRelationships_rejectsZeroGuardian() public {
        MockV800SuperchainConfig wrongSuperchainConfig = new MockV800SuperchainConfig(address(0));
        MockV800Portal matchingPortal = new MockV800Portal(address(wrongSuperchainConfig), address(systemConfig));
        vm.expectRevert("OPCMUpgradeV800: guardian is zero address");
        _validate(
            address(systemConfig),
            address(matchingPortal),
            address(wrongSuperchainConfig),
            address(proxyAdmin),
            address(rootSafe),
            address(disputeGameFactory),
            address(rootSafe)
        );
    }

    function test_expectedValidationErrors_preservesInspectorOrderingAndPermissionedKonaErrors() public view {
        string memory errors = harness.expectedValidationErrors(
            address(rootSafe),
            CHALLENGER,
            address(superchainConfig),
            address(0xaaaa),
            address(0xbbbb),
            address(0xcccc),
            false,
            5
        );
        assertEq(errors, "OVERRIDES-L1PAOMULTISIG,OVERRIDES-CHALLENGER,SYSCON-130,SCKDG-SHAPE,SCKDG-10");
    }

    function test_expectedValidationErrors_omitsKonaErrorsWhenKonaWasRegistered() public view {
        string memory errors = harness.expectedValidationErrors(
            address(rootSafe),
            CHALLENGER,
            address(superchainConfig),
            address(rootSafe),
            CHALLENGER,
            address(superchainConfig),
            true,
            5
        );
        assertEq(errors, "");
    }

    function test_expectedValidationErrors_omitsKonaErrorsForSuperCannonKonaTarget() public view {
        string memory errors = harness.expectedValidationErrors(
            address(rootSafe),
            CHALLENGER,
            address(superchainConfig),
            address(rootSafe),
            CHALLENGER,
            address(superchainConfig),
            false,
            9
        );
        assertEq(errors, "");
    }

    function test_parseUpgrades_ignoresLegacyValidationAndVersionSkipFields() public view {
        string memory toml = "skipOPCMVersionCheck = true\n" "[[opcmUpgrades]]\n"
            "cannonKonaPrestate = \"0x2222222222222222222222222222222222222222222222222222222222222222\"\n"
            "cannonPrestate = \"0x1111111111111111111111111111111111111111111111111111111111111111\"\n"
            "chainId = 4201234\n" "expectedValidationErrors = \"legacy-value\"\n" "initBond = 0\n"
            "startingAnchorRootL2SequenceNumber = 1\n"
            "startingAnchorRootRoot = \"0x3333333333333333333333333333333333333333333333333333333333333333\"\n"
            "startingRespectedGameType = 5\n";
        (uint256 chainId, uint32 gameType) = harness.parseUpgrade(toml);
        assertEq(chainId, 4_201_234);
        assertEq(gameType, 5);
    }
}
