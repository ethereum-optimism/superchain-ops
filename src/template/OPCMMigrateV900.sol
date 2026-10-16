// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {LibString} from "solady/utils/LibString.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {OPCMTaskBase} from "src/tasks/types/OPCMTaskBase.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {AccountAccessParser} from "src/libraries/AccountAccessParser.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// @notice A template contract for migrating a set of chains onto shared dispute contracts with OPCM.migrate.
/// Supports: op-contracts/v9.0.0 (OPContractsManagerV2 9.0.x)
/// @dev Migration is one-way. A single delegatecall deploys a shared ETHLockbox, DisputeGameFactory and
/// AnchorStateRegistry, moves every chain's ETH into the shared lockbox, points every portal at the shared
/// dispute contracts and enables INTEROP on every chain. It invalidates all prior withdrawal proofs.
contract OPCMMigrateV900 is OPCMTaskBase {
    using stdToml for string;
    using LibString for string;
    using EnumerableSet for EnumerableSet.AddressSet;
    using AccountAccessParser for VmSafe.AccountAccess[];

    /// @notice Migrate inputs shared by every chain in the set.
    /// @dev Fields must remain in alphabetical order for TOML decoding.
    struct OPCMMigrate {
        bytes32 cannonKonaPrestate;
        string expectedValidationErrors;
        address proposer;
        uint256 startingAnchorRootL2SequenceNumber;
        bytes32 startingAnchorRootRoot;
        uint32 startingRespectedGameType;
        uint256 superCannonKonaInitBond;
    }

    OPCMMigrate public migrateConfig;

    IOPContractsManagerV900 public opcm;
    IOPContractsManagerStandardValidatorV900 public standardValidator;
    bool public skipOPCMVersionCheck;

    /// @notice Each chain's pre-migration contracts, in `l2chains` order. migrate() re-points the
    /// portal and SystemConfig getters these come from, so they are read during setup.
    IOPContractsManagerMigrationValidatorV900.LegacyChainContracts[] internal legacyChainContracts;

    uint32 internal constant SUPER_PERMISSIONED = 5;
    uint32 internal constant SUPER_CANNON_KONA = 9;

    /// @notice Names in the SuperchainAddressRegistry that are expected to be written during this task.
    /// @dev The shared proxies migrate() deploys are new contracts, which MultisigTask allows without an entry. Each
    /// chain's DelayedWETH, old DisputeGameFactory and old AnchorStateRegistry are added in `_setAllowedStorageAccesses`
    /// from the pre-migration snapshot; super-root chains have no reliable DelayedWETH key in the registry.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](2);
        storageWrites[0] = "SystemConfigProxy";
        storageWrites[1] = "OptimismPortalProxy";
        return storageWrites;
    }

    /// @notice Returns an array of strings that refer to contract names in the address registry.
    /// Contracts with these names are expected to have their balance changes during the task.
    /// @dev Empty: every portal and old lockbox sends its ETH to the new shared lockbox, which is a new contract and
    /// therefore exempt from the balance check.
    function _taskBalanceChanges() internal view virtual override returns (string[] memory) {}

    /// @notice Allowlist the per-chain contracts migrate() writes that are not covered by `_taskStorageWrites`.
    function _setAllowedStorageAccesses() internal virtual override {
        super._setAllowedStorageAccesses();
        for (uint256 i = 0; i < legacyChainContracts.length; i++) {
            _allowedStorageAccesses.add(legacyChainContracts[i].disputeGameFactory);
            _allowedStorageAccesses.add(legacyChainContracts[i].delayedWETH);
            _allowedStorageAccesses.add(legacyChainContracts[i].anchorStateRegistry);
        }
    }

    /// @notice Sets up the template with the migrate configuration from a TOML file.
    function _templateSetup(string memory taskConfigFilePath, address rootSafe) internal override {
        super._templateSetup(taskConfigFilePath, rootSafe);
        string memory tomlContent = vm.readFile(taskConfigFilePath);
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();

        require(chains.length > 0, "OPCMMigrateV900: no chains configured");

        migrateConfig = abi.decode(tomlContent.parseRaw(".opcmMigrate"), (OPCMMigrate));
        require(migrateConfig.cannonKonaPrestate != bytes32(0), "OPCMMigrateV900: cannonKonaPrestate is zero");
        require(migrateConfig.proposer != address(0), "OPCMMigrateV900: proposer is zero");
        require(migrateConfig.superCannonKonaInitBond != 0, "OPCMMigrateV900: superCannonKonaInitBond is zero");
        require(
            migrateConfig.startingRespectedGameType == SUPER_PERMISSIONED
                || migrateConfig.startingRespectedGameType == SUPER_CANNON_KONA,
            "OPCMMigrateV900: startingRespectedGameType must be a super game type (5 or 9)"
        );
        require(migrateConfig.startingAnchorRootRoot != bytes32(0), "OPCMMigrateV900: startingAnchorRootRoot is zero");
        require(
            migrateConfig.startingAnchorRootL2SequenceNumber < type(uint64).max,
            "OPCMMigrateV900: startingAnchorRootL2SequenceNumber must leave room for a uint64 successor"
        );

        address superchainConfig = superchainAddrRegistry.getAddress("SuperchainConfig", chains[0].chainId);
        uint256 prevChainId;
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            // migrate() requires strictly ascending L2 chain IDs. Requiring the same order in `l2chains` instead of
            // sorting keeps the validator's per-chain error codes (MIG-CHAIN-<i>-*) aligned with the config.
            require(chainId > prevChainId, "OPCMMigrateV900: l2chains must be in strictly ascending chainId order");
            prevChainId = chainId;
            require(
                superchainAddrRegistry.getAddress("SuperchainConfig", chainId) == superchainConfig,
                "OPCMMigrateV900: all chains must share the same SuperchainConfig"
            );

            IOptimismPortalV900 portal =
                IOptimismPortalV900(superchainAddrRegistry.getAddress("OptimismPortalProxy", chainId));
            legacyChainContracts.push(
                IOPContractsManagerMigrationValidatorV900.LegacyChainContracts({
                    disputeGameFactory: portal.disputeGameFactory(),
                    ethLockbox: portal.ethLockbox(),
                    delayedWETH: ISystemConfigV900(superchainAddrRegistry.getAddress("SystemConfigProxy", chainId))
                        .delayedWETH(),
                    anchorStateRegistry: portal.anchorStateRegistry()
                })
            );
        }

        // OPCM from TOML; must be the op-contracts/v9.0.0 release (version 9.0.x).
        opcm = IOPContractsManagerV900(tomlContent.readAddress(".addresses.OPCM"));
        require(address(opcm).code.length > 0, "OPCMMigrateV900: OPCM has no code");
        OPCM_TARGETS.push(address(opcm));
        skipOPCMVersionCheck =
            tomlContent.keyExists(".skipOPCMVersionCheck") && tomlContent.readBool(".skipOPCMVersionCheck");
        if (!skipOPCMVersionCheck) {
            require(opcm.version().startsWith("9.0."), "OPCMMigrateV900: incorrect OPCM major/minor version");
        }
        vm.label(address(opcm), "OPCM");

        // Fetch the validator directly from OPCM so it doesn't need to be configured in TOML.
        standardValidator = opcm.opcmStandardValidator();
        require(address(standardValidator) != address(0), "OPCMMigrateV900: OPCM returned zero validator");
        require(address(standardValidator).code.length > 0, "OPCMMigrateV900: validator has no code");
        vm.label(address(standardValidator), "OPCMStandardValidator");

        for (uint256 i = 0; i < chains.length; i++) {
            require(
                opcm.isPermittedMigrateSequence(
                    superchainAddrRegistry.getAddress("SystemConfigProxy", chains[i].chainId)
                ),
                "OPCMMigrateV900: chain must be upgraded with this OPCM's release before migrating"
            );
        }
    }

    /// @notice Builds the dispute game configs registered on the shared DisputeGameFactory.
    /// @dev The migration validator requires both super game types. SUPER_PERMISSIONED takes proposer-only args and
    /// no bond; SUPER_CANNON_KONA takes the prestate and a non-zero bond.
    function _buildDisputeGameConfigs() internal view returns (IOPContractsManagerV900.DisputeGameConfig[] memory) {
        IOPContractsManagerV900.DisputeGameConfig[] memory cfgs = new IOPContractsManagerV900.DisputeGameConfig[](2);
        cfgs[0] = IOPContractsManagerV900.DisputeGameConfig({
            enabled: true,
            initBond: 0,
            gameType: SUPER_PERMISSIONED,
            gameArgs: abi.encode(migrateConfig.proposer)
        });
        cfgs[1] = IOPContractsManagerV900.DisputeGameConfig({
            enabled: true,
            initBond: migrateConfig.superCannonKonaInitBond,
            gameType: SUPER_CANNON_KONA,
            gameArgs: abi.encode(migrateConfig.cannonKonaPrestate)
        });
        return cfgs;
    }

    /// @notice Builds the actions for executing the operations.
    /// @dev OPCMTaskBase uses Multicall3DelegateCall, so the call to OPCM must use delegatecall. Unlike upgrade,
    /// migrate is a single call covering every chain. Any state written in this function is discarded after build
    /// completes.
    function _build(address) internal override {
        IOPContractsManagerV900.MigrateInput memory input = IOPContractsManagerV900.MigrateInput({
            chainSystemConfigs: _chainSystemConfigs(),
            disputeGameConfigs: _buildDisputeGameConfigs(),
            startingAnchorRoot: IOPContractsManagerV900.Proposal({
                root: migrateConfig.startingAnchorRootRoot,
                l2SequenceNumber: migrateConfig.startingAnchorRootL2SequenceNumber
            }),
            startingRespectedGameType: migrateConfig.startingRespectedGameType
        });

        (bool success, bytes memory returnData) =
            address(opcm).delegatecall(abi.encodeCall(IOPContractsManagerV900.migrate, (input)));
        if (!success) {
            if (returnData.length > 0) {
                assembly {
                    revert(add(returnData, 32), mload(returnData))
                }
            }
            revert("OPCMMigrateV900: migrate delegatecall failed");
        }
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    /// @dev migrate() deploys exactly three proxies, in this order: ETHLockbox, DisputeGameFactory,
    /// AnchorStateRegistry. Their CREATE2 salt includes block.timestamp, so they cannot be configured up front. They
    /// are taken from the recorded contract creations rather than from the portals, because the validator requires
    /// the expected shared contracts to be sourced independently of the state migrate() produced.
    function _validate(VmSafe.AccountAccess[] memory accountAccesses, Action[] memory, address rootSafe)
        internal
        view
        override
    {
        address[] memory created = accountAccesses.getNewContracts();
        require(created.length == 3, "OPCMMigrateV900: expected migrate to create exactly 3 contracts");

        IOPContractsManagerMigrationValidatorV900.ExpectedInitBond[] memory expectedInitBonds =
            new IOPContractsManagerMigrationValidatorV900.ExpectedInitBond[](2);
        expectedInitBonds[0] =
            IOPContractsManagerMigrationValidatorV900.ExpectedInitBond({gameType: SUPER_PERMISSIONED, initBond: 0});
        expectedInitBonds[1] = IOPContractsManagerMigrationValidatorV900.ExpectedInitBond({
            gameType: SUPER_CANNON_KONA,
            initBond: migrateConfig.superCannonKonaInitBond
        });

        IOPContractsManagerMigrationValidatorV900.MigrationValidationInput memory input =
        IOPContractsManagerMigrationValidatorV900.MigrationValidationInput({
            dgf: created[1],
            chainSystemConfigs: _chainSystemConfigs(),
            legacyChainContracts: legacyChainContracts,
            expectedShared: IOPContractsManagerMigrationValidatorV900.ExpectedSharedContracts({
                anchorStateRegistry: created[2],
                ethLockbox: created[0],
                // migrate() reuses the first chain's DelayedWETH as the shared one.
                delayedWETH: legacyChainContracts[0].delayedWETH
            }),
            expectedInitBonds: expectedInitBonds,
            startingAnchorRoot: IOPContractsManagerV900.Proposal({
                root: migrateConfig.startingAnchorRootRoot,
                l2SequenceNumber: migrateConfig.startingAnchorRootL2SequenceNumber
            }),
            startingRespectedGameType: migrateConfig.startingRespectedGameType,
            cannonKonaPrestate: migrateConfig.cannonKonaPrestate,
            proposer: migrateConfig.proposer
        });

        // The migration path only applies the L1 PAO override: SUPER_PERMISSIONED has no challenger. The root safe
        // is the ProxyAdmin owner that executes migrate() and becomes the shared DisputeGameFactory owner.
        string memory errors;
        if (rootSafe != standardValidator.l1PAOMultisig()) {
            errors = standardValidator.validateMigratedChainWithOverrides({
                _input: input,
                _allowFailure: true,
                _overrides: IOPContractsManagerStandardValidatorV900.ValidationOverrides({
                    l1PAOMultisig: rootSafe,
                    challenger: address(0)
                })
            });
        } else {
            errors = standardValidator.validateMigratedChain({_input: input, _allowFailure: true});
        }

        string memory expErrors = migrateConfig.expectedValidationErrors;
        require(
            errors.eq(expErrors),
            string.concat("OPCMMigrateV900: unexpected validation errors: ", errors, "; expected: ", expErrors)
        );
    }

    /// @notice Returns every chain's SystemConfig in `l2chains` order, which `_templateSetup` requires to be
    /// strictly ascending by chain ID.
    function _chainSystemConfigs() internal view returns (address[] memory sysCfgs) {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        sysCfgs = new address[](chains.length);
        for (uint256 i = 0; i < chains.length; i++) {
            sysCfgs[i] = superchainAddrRegistry.getAddress("SystemConfigProxy", chains[i].chainId);
        }
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    /// @dev migrate() reinitializes every SystemConfig to point it at the shared DelayedWETH, re-writing storage
    /// slots whose values are legitimately EOAs.
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        address[] memory exceptions = new address[](chains.length * 3);
        uint256 cursor;
        for (uint256 i = 0; i < chains.length; i++) {
            ISystemConfigV900 sysCfg =
                ISystemConfigV900(superchainAddrRegistry.getAddress("SystemConfigProxy", chains[i].chainId));
            // Only include true, non-zero EOAs (no code). A zero entry makes
            // `Utils.isLikelyAddressThatShouldHaveCode` revert.
            address[3] memory candidates =
                [sysCfg.owner(), sysCfg.unsafeBlockSigner(), address(uint160(uint256(sysCfg.batcherHash())))];
            for (uint256 j = 0; j < candidates.length; j++) {
                if (candidates[j] != address(0) && candidates[j].code.length == 0) exceptions[cursor++] = candidates[j];
            }
        }
        address[] memory result = new address[](cursor);
        for (uint256 i = 0; i < cursor; i++) {
            result[i] = exceptions[i];
        }
        return result;
    }
}

/* ---------- Interfaces ---------- */
/// @notice OPCM Interface (op-contracts/v9.0.0 OPContractsManagerV2), reduced to what migrate needs.
interface IOPContractsManagerV900 {
    struct DisputeGameConfig {
        bool enabled;
        uint256 initBond;
        uint32 gameType; // GameType
        bytes gameArgs;
    }

    struct Proposal {
        bytes32 root; // Hash
        uint256 l2SequenceNumber;
    }

    /// @notice IOPContractsManagerMigrator.MigrateInput.
    struct MigrateInput {
        address[] chainSystemConfigs; // ISystemConfig[]
        DisputeGameConfig[] disputeGameConfigs;
        Proposal startingAnchorRoot;
        uint32 startingRespectedGameType; // GameType
    }

    function version() external view returns (string memory);

    function migrate(MigrateInput calldata _input) external;

    function isPermittedMigrateSequence(address _systemConfig) external view returns (bool);

    function opcmStandardValidator() external view returns (IOPContractsManagerStandardValidatorV900);
}

/// @notice Migration validator types (op-contracts/v9.0.0 IOPContractsManagerMigrationValidator).
interface IOPContractsManagerMigrationValidatorV900 {
    struct LegacyChainContracts {
        address disputeGameFactory;
        address ethLockbox;
        address delayedWETH;
        address anchorStateRegistry;
    }

    struct ExpectedSharedContracts {
        address anchorStateRegistry;
        address ethLockbox;
        address delayedWETH;
    }

    struct ExpectedInitBond {
        uint32 gameType; // GameType
        uint256 initBond;
    }

    struct MigrationValidationInput {
        address dgf;
        address[] chainSystemConfigs; // ISystemConfig[]
        LegacyChainContracts[] legacyChainContracts;
        ExpectedSharedContracts expectedShared;
        ExpectedInitBond[] expectedInitBonds;
        IOPContractsManagerV900.Proposal startingAnchorRoot;
        uint32 startingRespectedGameType; // GameType
        bytes32 cannonKonaPrestate;
        address proposer;
    }
}

/// @notice Standard validator interface for the migration entry points (op-contracts/v9.0.0).
interface IOPContractsManagerStandardValidatorV900 {
    struct ValidationOverrides {
        address l1PAOMultisig;
        address challenger;
    }

    function l1PAOMultisig() external view returns (address);

    function validateMigratedChain(
        IOPContractsManagerMigrationValidatorV900.MigrationValidationInput memory _input,
        bool _allowFailure
    ) external view returns (string memory);

    function validateMigratedChainWithOverrides(
        IOPContractsManagerMigrationValidatorV900.MigrationValidationInput memory _input,
        bool _allowFailure,
        ValidationOverrides memory _overrides
    ) external view returns (string memory);
}

interface IOptimismPortalV900 {
    function anchorStateRegistry() external view returns (address);
    function disputeGameFactory() external view returns (address);
    function ethLockbox() external view returns (address);
}

interface ISystemConfigV900 {
    function owner() external view returns (address);
    function unsafeBlockSigner() external view returns (address);
    function batcherHash() external view returns (bytes32);
    function delayedWETH() external view returns (address);
}
