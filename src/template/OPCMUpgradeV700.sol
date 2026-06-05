// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Claim, GameType} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {LibString} from "solady/utils/LibString.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {OPCMTaskBase} from "src/tasks/types/OPCMTaskBase.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// @notice Upgrade 19 OPCM template — targets op-contracts/v7.1.17 (OPCMv2).
///
/// U19 does:
///   - Rotates the **respected game type** to `CANNON_KONA` (8). The Rust-based
///     `kona-client` becomes the primary fault-proof program.
///   - Installs the `CANNON_KONA` (8) game in the `DisputeGameFactory` with the new
///     Kona prestate.
///   - **Disables `CANNON` (0) in the `DisputeGameFactory`** — sets `gameImpls[CANNON]`
///     to `address(0)` so no new `CANNON` (op-program) games can be created post-upgrade.
///     Existing `CANNON` instances are unaffected (their impl is bytecode-bound at game
///     creation) and can still resolve to completion.
///   - Rewires `PERMISSIONED_CANNON` (1) to its v7.1.17 impl on every chain — installed
///     fresh if the slot wasn't live, rewired if it was. Permissioned games created
///     pre-upgrade are unaffected; new permissioned games will be created against the
///     new impl. This guarantees every U19 chain has a permissioned fallback game
///     available for emergency rollback.
///   - Does NOT touch super-root or super game types — the deployed v7.1.17 OPCM ships
///     `address(0)` for `superFaultDisputeGameImpl`, `superPermissionedDisputeGameImpl`,
///     and `zkDisputeGameImpl`. Those slots stay disabled in this upgrade.
///
/// Mechanics: the v7.1.17 OPCM (a.k.a. "OPCMv2") splits its API in two:
///   1. `upgradeSuperchain(SuperchainUpgradeInput)` — once per task, re-initialises the
///      shared SuperchainConfig.
///   2. `upgrade(UpgradeInput)` — once per L2, re-initialises the chain stack
///      (SystemConfig, OptimismPortal, ETHLockbox, L1{CDM,SB,ERC721Bridge}, OptimismMint
///      ableERC20Factory, DisputeGameFactory, DelayedWETH, AnchorStateRegistry) and
///      rewires the dispute games via `setImplementation` + `setInitBond`.
/// Both calls go through Multicall3DelegateCall via `OPCMTaskBase`.
///
/// Inputs to `OPCM.upgrade(UpgradeInput)` are:
///   - `disputeGameConfigs` MUST contain exactly 7 entries in this fixed insertion order
///       [CANNON, PERMISSIONED_CANNON, CANNON_KONA, SUPER_CANNON, SUPER_PERMISSIONED_CANNON,
///        SUPER_CANNON_KONA, ZK_DISPUTE_GAME]
///     anything else reverts with `OPContractsManagerV2_InvalidGameConfigs()`.
///   - For each entry: `enabled=true` rewires `gameImpls[gameType]` to the impl held in
///     the OPCM's container (with the supplied prestate); `enabled=false` clears it.
///   - `extraInstructions` carries the `startingRespectedGameType` override the OPCM
///     uses to pin `AnchorStateRegistry.respectedGameType` (must point at one of the
///     enabled slots).
/// Source: https://github.com/ethereum-optimism/optimism/blob/feat/cannon-kona-make-default/packages/contracts-bedrock/src/L1/opcm/OPContractsManagerV2.sol
///
/// Chain-agnostic: the example task at `test/tasks/example/sep/037-opcm-upgrade-v700`
/// runs against the permissioned-only u19-beta-0 betanet, but the template itself
/// works on any chain — currently-registered pre-superroot game types are kept
/// enabled (so we don't reset live impls to zero on permissionless chains).
///
/// Designed to work with chains that are NOT in the public superchain-registry. Such
/// chains supply addresses via `fallbackAddressesJsonPath` in the task TOML.
contract OPCMUpgradeV700 is OPCMTaskBase {
    using stdToml for string;
    using LibString for string;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Per-chain inputs.
    /// @dev Field order MUST be alphabetical (forge-std TOML decoder constraint).
    /// @dev `startingRespectedGameType` is the **post-upgrade** value to write into
    ///      `AnchorStateRegistry.respectedGameType`. The "starting" prefix is a name
    ///      leak from the OPCM's `FullConfig` deploy struct — on the upgrade path it
    ///      is not a "start from zero" value, it is a SET. Whatever the chain's current
    ///      respected game type is (could be 0, 1, anything), the OPCM uses this value
    ///      via the `overrides.cfg.startingRespectedGameType` extraInstruction and
    ///      writes it directly into the registry. Must be one of:
    ///        - `PERMISSIONED_CANNON` (1) — for chains that stay permissioned through U19
    ///          (no `CANNON_KONA` impl is installed; the slot is zeroed instead). Their
    ///          `cannonKonaPrestate` is unused and MUST be the zero address (not a `0xdead`
    ///          placeholder) — enforced in `_templateSetup`.
    ///        - `CANNON_KONA` (8) — for chains that move to a kona-client permissionless
    ///          FPVM post-upgrade. `PERMISSIONED_CANNON` (1) remains wired as a fallback;
    ///          its `cannonPrestate` can be a `0xdead...` placeholder.
    ///      Must correspond to an `enabled=true` slot in `disputeGameConfigs` (asserted
    ///      below in `_extraInstructions`) or the OPCM reverts with
    ///      `OPContractsManagerV2_InvalidGameConfigs`.
    struct OPCMUpgrade {
        Claim cannonKonaPrestate;
        Claim cannonPrestate;
        uint256 chainId;
        string expectedValidationErrors;
        uint256 initBond;
        uint32 startingRespectedGameType;
    }

    /// @notice Whether the chain stays permissioned through this upgrade.
    /// @dev Derived from `startingRespectedGameType`: a chain that keeps
    ///      `PERMISSIONED_CANNON` as its respected game type IS permissioned and must
    ///      NOT receive a `CANNON_KONA` implementation (per U19 spec). A chain
    ///      rotating to `CANNON_KONA` is permissionless and gets
    ///      the standard wiring (CANNON_KONA installed, PERMISSIONED_CANNON kept as
    ///      Guardian fallback). Inferred (rather than configured as a separate TOML
    ///      field) so the two values cannot drift apart.
    function _isPermissionedChain(uint256 chainId) internal view returns (bool) {
        return upgrades[chainId].startingRespectedGameType == PERMISSIONED_CANNON;
    }

    /// @notice chainId => parsed config.
    mapping(uint256 => OPCMUpgrade) public upgrades;

    /// @notice The OPCM we delegatecall into. Loaded from `[addresses].OPCM`.
    /// Must satisfy `version() == "7.1.17"`.
    IOPContractsManagerV700 public OPCM;

    /// @notice Standard validator returned by the OPCM. Used post-upgrade to assert each
    /// chain's state matches the v7.1.x standard, with role overrides for non-standard
    /// L1ProxyAdminOwner / Challenger (typical on betanets).
    IOPContractsManagerStandardValidator public STANDARD_VALIDATOR;

    /* ---------- GameType IDs (op-contracts/v7.0.0 GameTypes.sol) ---------- */
    uint32 internal constant CANNON = 0;
    uint32 internal constant PERMISSIONED_CANNON = 1;
    uint32 internal constant SUPER_CANNON = 4;
    uint32 internal constant SUPER_PERMISSIONED_CANNON = 5;
    uint32 internal constant CANNON_KONA = 8;
    uint32 internal constant SUPER_CANNON_KONA = 9;
    uint32 internal constant ZK_DISPUTE_GAME = 10;

    /// @notice Registry identifiers expected to receive storage writes during the task.
    /// Used by L2TaskBase for state-diff assertions.
    /// @dev `PermissionlessWETH` is included so the template stays safe on permissionless
    /// chains too. Permissioned-only chains that don't register that identifier just
    /// emit a `[WARN]` from `_tryAddAddress` and continue (the parent's lookup is
    /// `try`/`catch`); cost is one log line at simulation start.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory writes = new string[](15);
        writes[0] = "SuperchainConfig";
        writes[1] = "ProtocolVersions";
        writes[2] = "DisputeGameFactoryProxy";
        writes[3] = "SystemConfigProxy";
        writes[4] = "OptimismPortalProxy";
        writes[5] = "OptimismMintableERC20FactoryProxy";
        writes[6] = "AddressManager";
        writes[7] = "L1StandardBridgeProxy";
        writes[8] = "L1ERC721BridgeProxy";
        writes[9] = "L1CrossDomainMessengerProxy";
        writes[10] = "ProxyAdminOwner";
        writes[11] = "AnchorStateRegistryProxy";
        writes[12] = "PermissionedWETH";
        writes[13] = "PermissionlessWETH";
        writes[14] = "EthLockboxProxy";
        return writes;
    }

    /// @notice No balance changes expected.
    function _taskBalanceChanges() internal view virtual override returns (string[] memory) {}

    /// @notice Allowlist storage writes for the upgrade.
    /// @dev L2TaskBase's default `_setAllowedStorageAccesses` calls `addrRegistry.get(key)`
    /// before falling back to per-chain `getAddress(key, chainId)`. For shared identifiers
    /// like `SuperchainConfig` and `ProtocolVersions`, `get(key)` resolves against the
    /// sentinel-chain entries hardcoded in `src/addresses.toml` (the OP Sepolia / mainnet
    /// values), so betanet-specific addresses never make it into the allowlist. We re-add
    /// them explicitly per chain so betanet upgrades pass the post-execution check.
    /// For standard chains, `ProtocolVersions` is only registered on the sentinel chain
    /// (via addresses.toml), so we fall back to `get()` when per-chain lookup fails.
    function _setAllowedStorageAccesses() internal virtual override {
        super._setAllowedStorageAccesses();
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        for (uint256 i = 0; i < chains.length; i++) {
            _allowedStorageAccesses.add(superchainAddrRegistry.getAddress("SuperchainConfig", chains[i].chainId));
            // ProtocolVersions is registered per-chain for betanets (via fallback addresses.json)
            // but only on the sentinel chain for standard superchain-registry chains. Try per-chain
            // first (betanet case), fall back to sentinel chain (standard chain case).

            try superchainAddrRegistry.getAddress("ProtocolVersions", chains[i].chainId) returns (address pv) {
                _allowedStorageAccesses.add(pv);
            } catch {
                console.log(
                    "OPCMUpgradeV700: per-chain ProtocolVersions lookup failed for chainId %d, falling back to global ProtocolVersions",
                    chains[i].chainId
                );
                _allowedStorageAccesses.add(superchainAddrRegistry.get("ProtocolVersions"));
            }
        }
    }

    /// @notice Parse TOML, validate, and resolve OPCM + validator.
    function _templateSetup(string memory taskConfigFilePath, address rootSafe) internal override {
        super._templateSetup(taskConfigFilePath, rootSafe);

        string memory toml = vm.readFile(taskConfigFilePath);
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        require(chains.length > 0, "OPCMUpgradeV700: no chains configured");

        // Decode `[[opcmUpgrades]]` rows.
        OPCMUpgrade[] memory parsed = abi.decode(toml.parseRaw(".opcmUpgrades"), (OPCMUpgrade[]));
        require(parsed.length == chains.length, "OPCMUpgradeV700: opcmUpgrades length mismatch");
        for (uint256 i = 0; i < parsed.length; i++) {
            require(parsed[i].chainId != 0, "OPCMUpgradeV700: chainId zero");
            require(upgrades[parsed[i].chainId].chainId == 0, "OPCMUpgradeV700: duplicate chain config");
            require(Claim.unwrap(parsed[i].cannonPrestate) != bytes32(0), "OPCMUpgradeV700: cannonPrestate zero");
            // CANNON_KONA (game type 8) is only wired on permissionless chains. Permissioned chains
            // (startingRespectedGameType == PERMISSIONED_CANNON) skip game type 8 entirely, so their
            // kona prestate is unused and MUST be left at the zero address — not a 0xdead placeholder.
            // Permissionless chains MUST supply a real (non-zero) kona prestate.
            if (parsed[i].startingRespectedGameType == PERMISSIONED_CANNON) {
                require(
                    Claim.unwrap(parsed[i].cannonKonaPrestate) == bytes32(0),
                    "OPCMUpgradeV700: cannonKonaPrestate must be zero for permissioned chains"
                );
            } else {
                require(
                    Claim.unwrap(parsed[i].cannonKonaPrestate) != bytes32(0), "OPCMUpgradeV700: cannonKonaPrestate zero"
                );
            }
            upgrades[parsed[i].chainId] = parsed[i];
        }

        // upgradeSuperchain() runs once and rewrites the shared SuperchainConfig — every
        // L2 in this task must therefore point at the same SuperchainConfig instance.
        address sharedSC = superchainAddrRegistry.getAddress("SuperchainConfig", chains[0].chainId);
        require(sharedSC != address(0), "OPCMUpgradeV700: SuperchainConfig not registered");
        require(sharedSC.code.length > 0, "OPCMUpgradeV700: SuperchainConfig has no code");
        for (uint256 i = 1; i < chains.length; i++) {
            require(
                superchainAddrRegistry.getAddress("SuperchainConfig", chains[i].chainId) == sharedSC,
                "OPCMUpgradeV700: chains do not share SuperchainConfig"
            );
        }

        // Resolve OPCM and verify version. Strict on "7.1.17" — bump deliberately when
        // moving to a newer patch so reviewers see the version delta in the diff.
        OPCM = IOPContractsManagerV700(toml.readAddress(".addresses.OPCM"));
        OPCM_TARGETS.push(address(OPCM));
        require(OPCM.version().eq("7.1.17"), "OPCMUpgradeV700: OPCM is not v7.1.17");
        vm.label(address(OPCM), "OPCM");

        // Validator is exposed by the OPCM; no need to plumb it through TOML.
        STANDARD_VALIDATOR = OPCM.opcmStandardValidator();
        require(address(STANDARD_VALIDATOR) != address(0), "OPCMUpgradeV700: validator zero");
        require(address(STANDARD_VALIDATOR).code.length > 0, "OPCMUpgradeV700: validator has no code");
        vm.label(address(STANDARD_VALIDATOR), "OPCMStandardValidator");
    }

    /* ---------- DisputeGameConfig builders ---------- */

    /// @notice U19-specific enabled-flag policy for each of the 7 OPCMv2 game-type slots.
    /// @dev
    ///   - `CANNON_KONA`: enabled if the chain is **permissionless** post-upgrade. On
    ///     permissionless chains this is what U19 introduces — `kona-client` becomes the
    ///     primary FPVM and the new respected game type. On permissioned chains we must
    ///     NOT wire a `CANNON_KONA` implementation (per U19 spec):
    ///     `enabled=false` makes OPCMv2 emit `setImplementation(8, 0, "")` on
    ///     the DGF, leaving `gameImpls[8] = address(0)`. For chains where the slot is
    ///     already zero on-chain (e.g. Sepolia Metal/Mode/Zora) this is a no-op write;
    ///     for any chain that did have an impl wired pre-task it gets cleared.
    ///   - `PERMISSIONED_CANNON`: always enabled. Every U19 chain wants a permissioned
    ///     game live — both as the canonical game on permissioned chains and as the
    ///     emergency Guardian fallback on permissionless chains (if Kona has issues the
    ///     Guardian can flip respected back to PERMISSIONED_CANNON). The OPCM rewires
    ///     `gameImpls[1]` to the v7.1.17 `PermissionedDisputeGame` impl with the supplied
    ///     `cannonPrestate` and `(proposer, challenger)`. Pre-upgrade game instances
    ///     continue to resolve against their old bytecode-bound impl. Requires
    ///     `Proposer` and `Challenger` to be registered for the chain (they are for
    ///     every real chain). For permissionless chains `cannonPrestate` is a fallback
    ///     value and may be a `0xdead...` placeholder.
    ///   - `CANNON`: always **disabled**. U19 retires `op-program` as a fault-proof
    ///     program; new CANNON games must not be creatable. Because OPCMv2 turns a
    ///     `disabled` slot into `setImplementation(gameType, 0, "")` on the
    ///     `DisputeGameFactory`, the on-chain `gameImpls[CANNON]` ends up at `address(0)`
    ///     post-upgrade — this is the explicit ask per the U19 spec. Existing
    ///     CANNON game instances are unaffected (their impl is bytecode-bound at game
    ///     creation time) so they can still resolve to completion; only new CANNON games
    ///     are blocked from being created.
    ///   - `SUPER_CANNON`, `SUPER_PERMISSIONED_CANNON`, `SUPER_CANNON_KONA`,
    ///     `ZK_DISPUTE_GAME`: always disabled. The v7.1.17 OPCM container ships
    ///     `address(0)` for these impls; they belong to a later release, not U19.
    function _isEnabled(uint32 gt, bool permissioned) internal pure returns (bool) {
        if (gt == CANNON_KONA) return !permissioned;
        if (gt == PERMISSIONED_CANNON) return true;
        // CANNON: explicitly disabled (per U19 spec). SUPER_*, ZK: not in U19.
        return false;
    }

    /// @notice Pack one DisputeGameConfig row.
    /// @dev `gameArgs` encoding mirrors `OPContractsManagerUtils._makeGameArgs`:
    ///   - permissionless families (CANNON, CANNON_KONA, SUPER_CANNON, SUPER_CANNON_KONA):
    ///       `abi.encode(absolutePrestate)`
    ///   - permissioned families (PERMISSIONED_CANNON, SUPER_PERMISSIONED_CANNON):
    ///       `abi.encode(absolutePrestate, proposer, challenger)`
    /// CANNON_KONA uses `cannonKonaPrestate` (Kona-built); the others use `cannonPrestate`.
    function _gameConfig(
        address proposer,
        address challenger,
        uint32 gt,
        bytes32 cannonPre,
        bytes32 cannonKonaPre,
        uint256 bond,
        bool permissioned
    ) internal pure returns (IOPContractsManagerV700.DisputeGameConfig memory) {
        bool enabled = _isEnabled(gt, permissioned);
        bytes memory args;
        if (enabled) {
            bytes32 prestate = (gt == CANNON_KONA) ? cannonKonaPre : cannonPre;
            bool isPermGameType = (gt == PERMISSIONED_CANNON);
            args = isPermGameType ? abi.encode(prestate, proposer, challenger) : abi.encode(prestate);
        }
        return IOPContractsManagerV700.DisputeGameConfig({
            enabled: enabled,
            initBond: enabled ? bond : 0,
            gameType: gt,
            gameArgs: args
        });
    }

    /// @notice Build the 7-row DisputeGameConfig array for one chain in the OPCMv2-mandated order.
    function _gameConfigs(uint256 chainId)
        internal
        view
        returns (IOPContractsManagerV700.DisputeGameConfig[] memory configs)
    {
        address proposer = superchainAddrRegistry.getAddress("Proposer", chainId);
        address challenger = superchainAddrRegistry.getAddress("Challenger", chainId);

        bytes32 cannonPre = Claim.unwrap(upgrades[chainId].cannonPrestate);
        bytes32 cannonKonaPre = Claim.unwrap(upgrades[chainId].cannonKonaPrestate);
        uint256 bond = upgrades[chainId].initBond;
        bool permissioned = _isPermissionedChain(chainId);

        // OPCMv2 requires EXACTLY this 7-element insertion order — see the validGameTypes
        // literal in OPContractsManagerV2._assertValidFullConfig. Any deviation reverts
        // with OPContractsManagerV2_InvalidGameConfigs.
        uint32[7] memory gts = [
            CANNON,
            PERMISSIONED_CANNON,
            CANNON_KONA,
            SUPER_CANNON,
            SUPER_PERMISSIONED_CANNON,
            SUPER_CANNON_KONA,
            ZK_DISPUTE_GAME
        ];
        configs = new IOPContractsManagerV700.DisputeGameConfig[](7);
        for (uint256 i = 0; i < 7; i++) {
            configs[i] = _gameConfig(proposer, challenger, gts[i], cannonPre, cannonKonaPre, bond, permissioned);
        }
    }

    /// @notice Build the per-chain ExtraInstruction array.
    /// @dev v7.1.17 recognises (among others):
    ///   - `PermittedProxyDeployment`: authorises the OPCM to deploy a fresh
    ///     `DelayedWETH` proxy if needed during the upgrade.
    ///   - `overrides.cfg.startingRespectedGameType`: `abi.encode(uint32)` value that
    ///     the OPCM writes verbatim into `AnchorStateRegistry.respectedGameType` when
    ///     it re-initialises the registry. This is a SET, not a delta — the chain's
    ///     current respected game type can be anything; this override replaces it
    ///     wholesale. Omitting this instruction would make the OPCM carry over the
    ///     live value (no rotation). For U19 this is either:
    ///       - `CANNON_KONA` (8) for chains that move to a permissionless kona FPVM, or
    ///       - `PERMISSIONED_CANNON` (1) for chains that stay permissioned through U19
    ///         (these chains keep their current game type 1; the rotation is a no-op SET
    ///         to the same value).
    /// @dev The OPCM additionally enforces that the value here corresponds to an
    ///      `enabled=true` slot in `disputeGameConfigs` (asserted in
    ///      `_assertValidFullConfig`). PERMISSIONED_CANNON is always enabled and
    ///      CANNON_KONA is enabled iff `!permissioned`, so the
    ///      `startingRespectedGameType ∈ {1, 8}` invariant we assert here lines up
    ///      with the enabled-slot constraint when `permissioned` is inferred from
    ///      `startingRespectedGameType` (`_isPermissionedChain`).
    function _extraInstructions(uint256 chainId)
        internal
        view
        returns (IOPContractsManagerV700.ExtraInstruction[] memory ix)
    {
        // Defense-in-depth: U19 retires CANNON as a respected game type, and the only
        // two values that line up with this template's enabled slots are
        // PERMISSIONED_CANNON (1) and CANNON_KONA (8). The OPCM would already revert on
        // any other value (the slot would be disabled), but rotating the respected game
        // type to anything else is an irreversible footgun on the AnchorStateRegistry —
        // refuse it at the override construction site so a config typo can never reach
        // the OPCM.
        // NB: despite the "starting" prefix (a name leak from the OPCM's deploy struct), this is the
        // ENDING respected game type — the value the OPCM writes into AnchorStateRegistry.respectedGameType
        // post-upgrade. See the struct doc above. {1 = stay permissioned, 8 = rotate to kona permissionless}.
        uint32 startingRespectedGameType = upgrades[chainId].startingRespectedGameType;
        require(
            startingRespectedGameType == PERMISSIONED_CANNON || startingRespectedGameType == CANNON_KONA,
            "OPCMUpgradeV700: startingRespectedGameType must be PERMISSIONED_CANNON or CANNON_KONA"
        );

        ix = new IOPContractsManagerV700.ExtraInstruction[](2);
        ix[0] = IOPContractsManagerV700.ExtraInstruction({key: "PermittedProxyDeployment", data: bytes("DelayedWETH")});
        ix[1] = IOPContractsManagerV700.ExtraInstruction({
            key: "overrides.cfg.startingRespectedGameType",
            data: abi.encode(startingRespectedGameType)
        });
    }

    /* ---------- Build / Validate ---------- */

    /// @notice Sequence: one upgradeSuperchain, then one upgrade per L2.
    /// @dev OPCMTaskBase routes both delegatecalls through Multicall3DelegateCall, so
    /// `address(OPCM).delegatecall(...)` runs in the rootSafe's context.
    function _build(address) internal override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        address sharedSC = superchainAddrRegistry.getAddress("SuperchainConfig", chains[0].chainId);

        // ERC-1967 implementation slot: keccak256("eip1967.proxy.implementation") - 1
        bytes32 ERC1967_IMPL_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

        // Skip upgradeSuperchain if the SuperchainConfig proxy is already pointing at the
        // v7.1.17 implementation. This happens in the stacked execution model when a prior
        // task (e.g. 086-U19-op with the shared L1PAO) already ran upgradeSuperchain.
        // Chains with non-standard L1PAOs (e.g. Unichain) cannot authorize ProxyAdmin.upgrade()
        // on the shared SuperchainConfig, so they must rely on a prior task having done it.
        address currentSCImpl = address(uint160(uint256(vm.load(sharedSC, ERC1967_IMPL_SLOT))));

        // Decode only the first return value (superchainConfigImpl) from implementations().
        (, bytes memory implData) = address(OPCM).staticcall(abi.encodeWithSignature("implementations()"));
        address targetSCImpl = abi.decode(implData, (address));

        if (currentSCImpl != targetSCImpl) {
            (bool scOk,) = address(OPCM).delegatecall(
                abi.encodeCall(
                    IOPContractsManagerV700.upgradeSuperchain,
                    IOPContractsManagerV700.SuperchainUpgradeInput({
                        superchainConfig: ISuperchainConfig(sharedSC),
                        extraInstructions: new IOPContractsManagerV700.ExtraInstruction[](0)
                    })
                )
            );
            require(scOk, "OPCMUpgradeV700: upgradeSuperchain failed");
        } else {
            console.log(
                "OPCMUpgradeV700: skipping upgradeSuperchain - SuperchainConfig proxy already points at target implementation %s",
                targetSCImpl
            );
        }

        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;
            require(upgrades[chainId].chainId != 0, "OPCMUpgradeV700: missing config for chain");

            IOPContractsManagerV700.UpgradeInput memory inp = IOPContractsManagerV700.UpgradeInput({
                systemConfig: ISystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chainId)),
                disputeGameConfigs: _gameConfigs(chainId),
                extraInstructions: _extraInstructions(chainId)
            });

            (bool ok,) =
                address(OPCM).delegatecall(abi.encodeWithSelector(IOPContractsManagerV700.upgrade.selector, inp));
            require(ok, string.concat("OPCMUpgradeV700: upgrade failed for chain ", vm.toString(chainId)));
        }
    }

    /// @notice Run the standard validator post-upgrade with optional role overrides.
    /// @dev Betanets typically run with non-standard L1ProxyAdminOwner / Challenger; we
    /// substitute their values into the validator only when they differ from the
    /// validator's hardcoded standard, which keeps the expected-error string stable
    /// across networks that do match the standard.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal view override {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        address standardL1PAO = STANDARD_VALIDATOR.l1PAOMultisig();
        address standardChallenger = STANDARD_VALIDATOR.challenger();

        for (uint256 i = 0; i < chains.length; i++) {
            uint256 chainId = chains[i].chainId;

            IOPContractsManagerStandardValidator.ValidationInputDev memory input = IOPContractsManagerStandardValidator
                .ValidationInputDev({
                sysCfg: ISystemConfig(superchainAddrRegistry.getAddress("SystemConfigProxy", chainId)),
                cannonPrestate: Claim.unwrap(upgrades[chainId].cannonPrestate),
                cannonKonaPrestate: Claim.unwrap(upgrades[chainId].cannonKonaPrestate),
                l2ChainID: chainId,
                proposer: superchainAddrRegistry.getAddress("Proposer", chainId)
            });

            address chainL1PAO = superchainAddrRegistry.getAddress("ProxyAdminOwner", chainId);
            address chainChallenger = superchainAddrRegistry.getAddress("Challenger", chainId);
            address l1PAOOverride = chainL1PAO == standardL1PAO ? address(0) : chainL1PAO;
            address challengerOverride = chainChallenger == standardChallenger ? address(0) : chainChallenger;

            string memory errors;
            if (l1PAOOverride != address(0) || challengerOverride != address(0)) {
                errors = STANDARD_VALIDATOR.validateWithOverrides({
                    _input: input,
                    _allowFailure: true,
                    _overrides: IOPContractsManagerStandardValidator.ValidationOverrides({
                        l1PAOMultisig: l1PAOOverride,
                        challenger: challengerOverride
                    })
                });
            } else {
                errors = STANDARD_VALIDATOR.validate({_input: input, _allowFailure: true});
            }

            string memory expected = upgrades[chainId].expectedValidationErrors;
            require(errors.eq(expected), string.concat("Unexpected errors: ", errors, "; expected: ", expected));
        }
    }

    /// @notice Code-length exceptions for storage values written by the upgrade.
    /// @dev v7.1.17 reinitialises SystemConfig and rewrites the slots that hold
    /// `owner`, `unsafeBlockSigner`, `batchInbox`, and the address derived from
    /// `batcherHash`. On betanets these are typically EOAs, not contracts, so the
    /// post-execution `Likely address in storage has no code` check would reject the
    /// writes. We skip the check for these specific values per chain.
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        address[] memory exceptions = new address[](chains.length * 4);
        uint256 cursor;
        for (uint256 i = 0; i < chains.length; i++) {
            ISystemConfigEOAs sc =
                ISystemConfigEOAs(superchainAddrRegistry.getAddress("SystemConfigProxy", chains[i].chainId));
            // Only include true EOAs (no code). Contract addresses (e.g. multisig owners)
            // must not be in the exceptions list — they are handled by the normal allowed
            // storage accesses check instead.
            address[4] memory candidates =
                [sc.owner(), sc.unsafeBlockSigner(), sc.batchInbox(), address(uint160(uint256(sc.batcherHash())))];
            for (uint256 j = 0; j < 4; j++) {
                if (candidates[j].code.length == 0) exceptions[cursor++] = candidates[j];
            }
        }
        address[] memory result = new address[](cursor);
        for (uint256 i = 0; i < cursor; i++) {
            result[i] = exceptions[i];
        }
        return result;
    }
}

/// @notice Read-only SystemConfig accessors used to populate `_getCodeExceptions`.
interface ISystemConfigEOAs {
    function owner() external view returns (address);
    function unsafeBlockSigner() external view returns (address);
    function batchInbox() external view returns (address);
    function batcherHash() external view returns (bytes32);
}

/* ---------- v7.1.17 ("OPCMv2") interfaces ---------- */
/// @dev Mirrors the structs in
///   https://github.com/ethereum-optimism/optimism/blob/feat/cannon-kona-make-default/packages/contracts-bedrock/src/L1/opcm/OPContractsManagerV2.sol
/// and the validator in
///   https://github.com/ethereum-optimism/optimism/blob/feat/cannon-kona-make-default/packages/contracts-bedrock/src/L1/OPContractsManagerStandardValidator.sol

interface IOPContractsManagerV700 {
    struct DisputeGameConfig {
        bool enabled;
        uint256 initBond;
        uint32 gameType;
        bytes gameArgs;
    }

    struct ExtraInstruction {
        string key;
        bytes data;
    }

    struct SuperchainUpgradeInput {
        ISuperchainConfig superchainConfig;
        ExtraInstruction[] extraInstructions;
    }

    struct UpgradeInput {
        ISystemConfig systemConfig;
        DisputeGameConfig[] disputeGameConfigs;
        ExtraInstruction[] extraInstructions;
    }

    function version() external view returns (string memory);
    function upgrade(UpgradeInput memory _inp) external;
    function upgradeSuperchain(SuperchainUpgradeInput memory _input) external;
    function opcmStandardValidator() external view returns (IOPContractsManagerStandardValidator);
}

interface IOPContractsManagerStandardValidator {
    struct ValidationInputDev {
        ISystemConfig sysCfg;
        bytes32 cannonPrestate;
        bytes32 cannonKonaPrestate;
        uint256 l2ChainID;
        address proposer;
    }

    struct ValidationOverrides {
        address l1PAOMultisig;
        address challenger;
    }

    function validate(ValidationInputDev memory _input, bool _allowFailure) external view returns (string memory);
    function validateWithOverrides(
        ValidationInputDev memory _input,
        bool _allowFailure,
        ValidationOverrides memory _overrides
    ) external view returns (string memory);
    function l1PAOMultisig() external view returns (address);
    function challenger() external view returns (address);
    function version() external view returns (string memory);
}

interface ISuperchainConfig {}

interface IDisputeGameFactory {
    function gameImpls(GameType gameType) external view returns (address);
}

interface ISystemConfig {
    struct Addresses {
        address l1CrossDomainMessenger;
        address l1ERC721Bridge;
        address l1StandardBridge;
        address optimismPortal;
        address optimismMintableERC20Factory;
        address delayedWETH;
        address opcm;
    }

    function getAddresses() external view returns (Addresses memory);
}
