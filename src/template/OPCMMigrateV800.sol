// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Claim, GameType} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {Hash} from "@eth-optimism-bedrock/src/dispute/lib/LibUDT.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {LibString} from "solady/utils/LibString.sol";

import {OPCMTaskBase} from "src/tasks/types/OPCMTaskBase.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";
import {IOPContractsManagerV700, ISystemConfig} from "src/template/OPCMUpgradeV700.sol";

/// @notice A template contract for driving OPCM.migrate(...) from superchain-ops.
/// Supports: op-contracts/v7.1.16 (OPCM with OPContractsManagerMigrator wired in).
/// @dev Migration is a one-way operation that merges N pre-interop chains into a single
/// interop set by deploying a shared DisputeGameFactory, AnchorStateRegistry, and ETHLockbox.
contract OPCMMigrateV800 is OPCMTaskBase {
    using stdToml for string;
    using LibString for string;

    /// @notice Per-chain inputs parsed from TOML.
    /// @dev Fields must remain in alphabetical order for TOML decoding.
    struct OPCMMigration {
        Claim cannonKonaPrestate;
        Claim cannonPrestate;
        uint256 chainId;
    }

    /// @notice Shared migrate inputs parsed from TOML.
    /// @dev Fields must remain in alphabetical order for TOML decoding.
    struct MigrateParams {
        string expectedValidationErrors;
        uint256 initBond;
        uint256 startingAnchorRootL2SequenceNumber;
        bytes32 startingAnchorRootRoot;
        uint32 startingRespectedGameType;
        address superChallenger;
        address superProposer;
    }

    /// @notice List of L2 chain IDs being migrated.
    uint256[] public chainsToMigrate;

    /// @notice Mapping of L2 chain IDs to their respective OPCMMigration structs.
    mapping(uint256 => OPCMMigration) public migrations;

    /// @notice Shared migrate parameters (same for every chain).
    MigrateParams public migrateParams;

    /// @notice Expected OPCM version for the configured migration fixture.
    string public expectedOPCMVersion;

    IOPContractsManagerV700 public opcm;
    IOPContractsManagerStandardValidatorMigrate public standardValidator;
    IOPContractsManagerMigrationValidator public migrationValidator;

    // Game type constants (from GameTypes library in op-contracts v7.1.16).
    uint32 internal constant SUPER_CANNON = 4;
    uint32 internal constant SUPER_PERMISSIONED_CANNON = 5;
    uint32 internal constant SUPER_CANNON_KONA = 9;

    /// @notice Names in the SuperchainAddressRegistry that are expected to be written during this task.
    /// @dev TODO: Add SharedDisputeGameFactoryProxy / SharedAnchorStateRegistryProxy /
    /// SharedEthLockboxProxy once the plumbing for discovering them (via AccountAccess parsing
    /// or an OPCM getter) is in place. They are deployed fresh by migrate() and not yet in
    /// the superchain registry.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](8);
        storageWrites[0] = "SuperchainConfig";
        storageWrites[1] = "ProtocolVersions";
        storageWrites[2] = "SystemConfigProxy";
        storageWrites[3] = "OptimismPortalProxy";
        storageWrites[4] = "DisputeGameFactoryProxy";
        storageWrites[5] = "AnchorStateRegistryProxy";
        storageWrites[6] = "EthLockboxProxy";
        storageWrites[7] = "ProxyAdminOwner";
        return storageWrites;
    }

    /// @notice Returns an array of strings that refer to contract names in the address registry.
    /// Contracts with these names are expected to have their balance changes during the task.
    function _taskBalanceChanges() internal view virtual override returns (string[] memory) {}

    /// @notice Sets up the template with implementation configurations from a TOML file.
    function _templateSetup(string memory taskConfigFilePath, address rootSafe) internal override {
        super._templateSetup(taskConfigFilePath, rootSafe);
        string memory tomlContent = vm.readFile(taskConfigFilePath);
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        require(chains.length > 0, "OPCMMigrateV800: no chains configured");

        // Load per-chain migrations from TOML.
        OPCMMigration[] memory _migrations = abi.decode(tomlContent.parseRaw(".opcmMigrations"), (OPCMMigration[]));
        require(_migrations.length == chains.length, "OPCMMigrateV800: opcmMigrations length mismatch");
        for (uint256 i = 0; i < _migrations.length; i++) {
            require(_migrations[i].chainId != 0, "OPCMMigrateV800: chainId cannot be zero");
            require(migrations[_migrations[i].chainId].chainId == 0, "OPCMMigrateV800: duplicate chain config");
            require(
                Claim.unwrap(_migrations[i].cannonPrestate) != bytes32(0), "OPCMMigrateV800: cannonPrestate is zero"
            );
            require(
                Claim.unwrap(_migrations[i].cannonKonaPrestate) != bytes32(0),
                "OPCMMigrateV800: cannonKonaPrestate is zero"
            );
            migrations[_migrations[i].chainId] = _migrations[i];
        }

        // Keep the migrated chain order aligned with `l2chains`, which is also the order used
        // in the migrate() SystemConfig array and in validation.
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            require(migrations[chainId].chainId != 0, "OPCMMigrateV800: config not found for chain");
            chainsToMigrate.push(chainId);
        }

        // All chains must share the same prestates because one shared DGF is deployed for all of them.
        bytes32 cannonPre0 = Claim.unwrap(migrations[chainsToMigrate[0]].cannonPrestate);
        bytes32 cannonKonaPre0 = Claim.unwrap(migrations[chainsToMigrate[0]].cannonKonaPrestate);
        for (uint256 i = 1; i < chainsToMigrate.length; i++) {
            require(
                Claim.unwrap(migrations[chainsToMigrate[i]].cannonPrestate) == cannonPre0,
                "OPCMMigrateV800: all chains must share the same cannonPrestate"
            );
            require(
                Claim.unwrap(migrations[chainsToMigrate[i]].cannonKonaPrestate) == cannonKonaPre0,
                "OPCMMigrateV800: all chains must share the same cannonKonaPrestate"
            );
        }

        // Load shared migrate parameters.
        migrateParams = abi.decode(tomlContent.parseRaw(".migrate"), (MigrateParams));
        require(
            migrateParams.startingRespectedGameType == SUPER_PERMISSIONED_CANNON
                || migrateParams.startingRespectedGameType == SUPER_CANNON_KONA,
            "OPCMMigrateV800: startingRespectedGameType must be an enabled super game type (5 or 9)"
        );
        require(migrateParams.startingAnchorRootRoot != bytes32(0), "OPCMMigrateV800: startingAnchorRootRoot is zero");
        require(migrateParams.superProposer != address(0), "OPCMMigrateV800: superProposer is zero");
        require(migrateParams.superChallenger != address(0), "OPCMMigrateV800: superChallenger is zero");

        // All chains must share the same SuperchainConfig.
        address superchainConfig = superchainAddrRegistry.getAddress("SuperchainConfig", chains[0].chainId);
        require(superchainConfig != address(0), "OPCMMigrateV800: SuperchainConfig not found");
        require(superchainConfig.code.length > 0, "OPCMMigrateV800: SuperchainConfig has no code");
        address proxyAdminOwner = superchainAddrRegistry.getAddress("ProxyAdminOwner", chains[0].chainId);
        require(proxyAdminOwner != address(0), "OPCMMigrateV800: ProxyAdminOwner not found");
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            require(
                superchainAddrRegistry.getAddress("SuperchainConfig", chainId) == superchainConfig,
                "OPCMMigrateV800: all chains must share the same SuperchainConfig"
            );
            require(
                superchainAddrRegistry.getAddress("ProxyAdminOwner", chainId) == proxyAdminOwner,
                "OPCMMigrateV800: all chains must share the same ProxyAdminOwner"
            );
        }

        // Register EthLockboxProxy for each chain from the superchain-registry addresses.json.
        // Migration drains per-chain lockboxes, but they are not discovered by the registry's
        // onchain discovery flow, so we register them here.
        string memory addrJson = vm.readFile(superchainAddrRegistry.SUPERCHAIN_REGISTRY_ADDRESSES_PATH());
        for (uint256 i = 0; i < chains.length; i++) {
            string memory key = string.concat("$.", vm.toString(chains[i].chainId), ".EthLockboxProxy");
            if (vm.keyExistsJson(addrJson, key)) {
                address ethLockbox = vm.parseJsonAddress(addrJson, key);
                superchainAddrRegistry.saveAddress("EthLockboxProxy", chains[i], ethLockbox);
                vm.label(ethLockbox, "EthLockboxProxy");
            }
        }

        // TODO: The V700 upgrade template etches code at EOA slots that are rewritten during
        // SystemConfig reinitialization. Migrate does not reinitialize SystemConfig, so the hack
        // may not be needed. Revisit once a v7.1.16 OPCM with migrator is available and we see
        // whether migrate() writes to any storage slot that previously held an EOA.

        // OPCM from TOML; version must match the fixture's expected deployment.
        opcm = IOPContractsManagerV700(tomlContent.readAddress(".addresses.OPCM"));
        OPCM_TARGETS.push(address(opcm));
        expectedOPCMVersion = tomlContent.readString(".expectedOPCMVersion");
        require(opcm.version().eq(expectedOPCMVersion), "OPCMMigrateV800: unexpected OPCM version");
        vm.label(address(opcm), "OPCM");

        // Fetch the validator directly from OPCM so it doesn't need to be configured in TOML.
        standardValidator = IOPContractsManagerStandardValidatorMigrate(address(opcm.opcmStandardValidator()));
        require(address(standardValidator) != address(0), "OPCMMigrateV800: OPCM returned zero validator");
        require(address(standardValidator).code.length > 0, "OPCMMigrateV800: validator has no code");
        vm.label(address(standardValidator), "OPCMStandardValidator");

        migrationValidator = standardValidator.migrationValidator();
        require(address(migrationValidator) != address(0), "OPCMMigrateV800: zero migration validator");
        require(address(migrationValidator).code.length > 0, "OPCMMigrateV800: migration validator has no code");
        vm.label(address(migrationValidator), "OPCMMigrationValidator");
    }

    /// @notice Builds the shared DisputeGameConfig array for the single migrate() call.
    /// @dev Migration deploys a single shared DGF used by every migrated chain, so we only emit
    /// entries for super-game types: SUPER_PERMISSIONED_CANNON (5) and SUPER_CANNON_KONA (9).
    /// SUPER_CANNON (4) is intentionally not enabled — see TODO(#20030) in OPContractsManagerMigrator.
    function _buildSharedGameConfigs() internal view returns (IOPContractsManagerV700.DisputeGameConfig[] memory) {
        bytes32 cannonPre = Claim.unwrap(migrations[chainsToMigrate[0]].cannonPrestate);
        bytes32 cannonKonaPre = Claim.unwrap(migrations[chainsToMigrate[0]].cannonKonaPrestate);

        IOPContractsManagerV700.DisputeGameConfig[] memory cfgs = new IOPContractsManagerV700.DisputeGameConfig[](2);

        cfgs[0] = IOPContractsManagerV700.DisputeGameConfig({
            enabled: true,
            initBond: migrateParams.initBond,
            gameType: SUPER_PERMISSIONED_CANNON,
            gameArgs: abi.encode(cannonPre, migrateParams.superProposer, migrateParams.superChallenger)
        });

        cfgs[1] = IOPContractsManagerV700.DisputeGameConfig({
            enabled: true,
            initBond: migrateParams.initBond,
            gameType: SUPER_CANNON_KONA,
            gameArgs: abi.encode(cannonKonaPre)
        });

        return cfgs;
    }

    /// @notice Builds the actions for executing the operations.
    /// @dev OPCMTaskBase uses Multicall3DelegateCall, so the call to OPCM must use delegatecall.
    /// Unlike upgrade, migrate is a single delegate-call that covers every chain at once.
    function _build(address) internal override {
        ISystemConfig[] memory sysCfgs = _chainSystemConfigs();

        IOPContractsManagerMigrator.MigrateInput memory inp = IOPContractsManagerMigrator.MigrateInput({
            chainSystemConfigs: sysCfgs,
            disputeGameConfigs: _buildSharedGameConfigs(),
            startingAnchorRoot: Proposal({
                root: Hash.wrap(migrateParams.startingAnchorRootRoot),
                l2SequenceNumber: migrateParams.startingAnchorRootL2SequenceNumber
            }),
            startingRespectedGameType: GameType.wrap(migrateParams.startingRespectedGameType)
        });

        (bool ok,) =
            address(opcm).delegatecall(abi.encodeWithSelector(IOPContractsManagerMigrator.migrate.selector, inp));
        require(ok, "OPCMMigrateV800: Delegatecall failed in _build.");
    }

    /// @notice Validates the migration result via the OPContractsManagerMigrationValidator
    /// exposed by the standard validator.
    /// @dev Migration validation runs once with all chains' SystemConfigs; unlike upgrade, there
    /// is no per-chain loop.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal view override {
        ISystemConfig[] memory sysCfgs = _chainSystemConfigs();
        address sharedDGF = _sharedDisputeGameFactory();

        IOPContractsManagerMigrationValidator.MigrationValidationInput memory input =
        IOPContractsManagerMigrationValidator.MigrationValidationInput({
            dgf: sharedDGF,
            chainSystemConfigs: sysCfgs,
            cannonPrestate: Claim.unwrap(migrations[chainsToMigrate[0]].cannonPrestate),
            cannonKonaPrestate: Claim.unwrap(migrations[chainsToMigrate[0]].cannonKonaPrestate),
            proposer: migrateParams.superProposer,
            challenger: migrateParams.superChallenger
        });

        address standardL1PAO = standardValidator.l1PAOMultisig();
        address standardChallenger = standardValidator.challenger();
        address l1PAO = superchainAddrRegistry.getAddress("ProxyAdminOwner", chainsToMigrate[0]);

        address l1PAOOverride = l1PAO != standardL1PAO ? l1PAO : address(0);
        address challengerOverride =
            migrateParams.superChallenger != standardChallenger ? migrateParams.superChallenger : address(0);

        string memory errors;
        if (l1PAOOverride != address(0) || challengerOverride != address(0)) {
            errors = standardValidator.validateMigratedChainWithOverrides({
                _input: input,
                _allowFailure: true,
                _overrides: IOPContractsManagerStandardValidatorMigrate.ValidationOverrides({
                    l1PAOMultisig: l1PAOOverride,
                    challenger: challengerOverride
                })
            });
        } else {
            errors = standardValidator.validateMigratedChain({_input: input, _allowFailure: true});
        }

        string memory expErrors = migrateParams.expectedValidationErrors;
        require(errors.eq(expErrors), string.concat("Unexpected errors: ", errors, "; expected: ", expErrors));
    }

    function _chainSystemConfigs() internal view returns (ISystemConfig[] memory sysCfgs) {
        require(chainsToMigrate.length > 0, "OPCMMigrateV800: no chains configured");
        sysCfgs = new ISystemConfig[](chainsToMigrate.length);
        for (uint256 i = 0; i < chainsToMigrate.length; i++) {
            sysCfgs[i] = ISystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chainsToMigrate[i]));
        }
    }

    function _sharedDisputeGameFactory() internal view returns (address sharedDGF) {
        require(chainsToMigrate.length > 0, "OPCMMigrateV800: no chains configured");
        address firstPortal = superchainAddrRegistry.getAddress("OptimismPortalProxy", chainsToMigrate[0]);
        sharedDGF = IOptimismPortalView(firstPortal).disputeGameFactory();
        require(sharedDGF != address(0), "OPCMMigrateV800: shared DGF is zero");

        for (uint256 i = 1; i < chainsToMigrate.length; i++) {
            address portal = superchainAddrRegistry.getAddress("OptimismPortalProxy", chainsToMigrate[i]);
            require(
                IOptimismPortalView(portal).disputeGameFactory() == sharedDGF,
                "OPCMMigrateV800: portals do not share DisputeGameFactory"
            );
        }
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {}
}

/* ---------- Interfaces ---------- */

/// @notice Local view of OptimismPortal2 used to discover the shared DGF after migration.
interface IOptimismPortalView {
    function disputeGameFactory() external view returns (address);
}

/// @notice Represents an L2 output root and the L2 sequence number at which it was generated.
/// Mirrors `src/dispute/lib/Types.sol::Proposal` in the op-contracts v7.1.16 tree.
struct Proposal {
    Hash root;
    uint256 l2SequenceNumber;
}

/// @notice OPCM migrator interface. Lives on the OPCM alongside upgrade/upgradeSuperchain in v7.1.16.
interface IOPContractsManagerMigrator {
    struct MigrateInput {
        ISystemConfig[] chainSystemConfigs;
        IOPContractsManagerV700.DisputeGameConfig[] disputeGameConfigs;
        Proposal startingAnchorRoot;
        GameType startingRespectedGameType;
    }

    function migrate(MigrateInput calldata _input) external;
}

/// @notice Migration validator interface.
interface IOPContractsManagerMigrationValidator {
    struct MigrationValidationInput {
        address dgf;
        ISystemConfig[] chainSystemConfigs;
        bytes32 cannonPrestate;
        bytes32 cannonKonaPrestate;
        address proposer;
        address challenger;
    }

    function version() external view returns (string memory);
}

/// @notice Extended standard validator interface that adds migration entry points plus
/// migrationValidator() getter.
interface IOPContractsManagerStandardValidatorMigrate {
    struct ValidationOverrides {
        address l1PAOMultisig;
        address challenger;
    }

    function l1PAOMultisig() external view returns (address);
    function challenger() external view returns (address);
    function version() external view returns (string memory);
    function migrationValidator() external view returns (IOPContractsManagerMigrationValidator);

    function validateMigratedChain(
        IOPContractsManagerMigrationValidator.MigrationValidationInput memory _input,
        bool _allowFailure
    ) external view returns (string memory);

    function validateMigratedChainWithOverrides(
        IOPContractsManagerMigrationValidator.MigrationValidationInput memory _input,
        bool _allowFailure,
        ValidationOverrides memory _overrides
    ) external view returns (string memory);
}
