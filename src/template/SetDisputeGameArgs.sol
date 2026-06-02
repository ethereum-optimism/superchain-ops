// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {LibString} from "solady/utils/LibString.sol";

import {L2TaskBase} from "src/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// @title SetDisputeGameArgs
/// @notice Sets the implementation, init bond, and full `gameArgs` for an EXPLICIT dispute game
///         type in the DisputeGameFactory, via a direct
///         `DisputeGameFactory.setImplementation(gameType, impl, gameArgs)` from the ProxyAdminOwner.
///         Generic: the game type is a config field, so it covers slots `SetDisputeGameImpl` cannot
///         (e.g. CANNON_KONA = 8), and accepts one or more rows.
///
///         FIELD-LEVEL DIFFING: only `chainId` and `gameType` are required per row. Any other field
///         left out of the TOML is read from the chain's current `gameArgs(gameType)` (and current
///         impl/bond) and kept unchanged — so a prestate bump is just `prestate = 0x…`. A field that
///         IS present overrides that part (zero is a valid override, e.g. to clear a role); an
///         `impl` of address(0) disables the game type entirely (empty gameArgs).
///
///         gameArgs packing (mirrors OPContractsManagerUtils._makeGameArgs) — big-endian, tightly
///         packed, addresses are 20 bytes, prestate/chainId are 32 bytes:
///
///           permissioned = false  → 124 bytes (CANNON=0, CANNON_KONA=8, SUPER_CANNON=4, SUPER_CANNON_KONA=9):
///               prestate(32) | vm(20) | anchorStateRegistry(20) | delayedWETH(20) | chainId(32)
///
///           permissioned = true   → 164 bytes (PERMISSIONED_CANNON=1, SUPER_PERMISSIONED_CANNON=5):
///               prestate(32) | vm(20) | anchorStateRegistry(20) | delayedWETH(20) | chainId(32)
///                                                              ... | proposer(20) | challenger(20)
///
///         `permissioned`, when omitted, is inferred from the current on-chain args length
///         (164 ⇒ true, 124 ⇒ false).
contract SetDisputeGameArgs is L2TaskBase {
    using stdToml for string;
    using LibString for uint256;

    /// @notice Fully-resolved per-(chain, game-type) action: what will actually be written on-chain
    ///         after merging the config overrides onto the current on-chain values.
    struct ResolvedGame {
        uint256 chainId;
        uint32 gameType;
        address impl;
        bytes gameArgs;
        uint256 bond;
        bool setBond; // true if the config specified a bond (so _build should call setInitBond)
    }

    /// @notice Resolved actions, in declaration order.
    ResolvedGame[] public resolvedGames;

    /// @notice Returns the string identifier for the safe executing this transaction.
    function safeAddressString() public pure override returns (string memory) {
        return "ProxyAdminOwner";
    }

    /// @notice Returns string identifiers for addresses that are expected to have their storage written to.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "DisputeGameFactoryProxy";
        return storageWrites;
    }

    /// @notice Parse `[[gameConfig]]` rows, merge each onto current on-chain state, and run checks.
    function _templateSetup(string memory _taskConfigFilePath, address _rootSafe) internal override {
        super._templateSetup(_taskConfigFilePath, _rootSafe);
        string memory toml = vm.readFile(_taskConfigFilePath);

        uint256 count = _rowCount(toml);
        require(count > 0, "SetDisputeGameArgs: no gameConfig rows");
        for (uint256 i = 0; i < count; i++) {
            _resolveRow(toml, string.concat(".gameConfig[", i.toString(), "]"));
        }
    }

    /// @notice Read one `[[gameConfig]]` row, merge its overrides onto the current on-chain values,
    ///         validate, and push the resolved action. Kept as its own frame to bound stack depth.
    function _resolveRow(string memory toml, string memory base) internal {
        // chainId + gameType are the only required fields — they identify the slot.
        require(toml.keyExists(string.concat(base, ".chainId")), "SetDisputeGameArgs: row missing chainId");
        require(toml.keyExists(string.concat(base, ".gameType")), "SetDisputeGameArgs: row missing gameType");
        uint256 chainId = toml.readUint(string.concat(base, ".chainId"));
        uint256 gtRaw = toml.readUint(string.concat(base, ".gameType"));
        require(chainId != 0, "SetDisputeGameArgs: chainId zero");
        require(gtRaw <= type(uint32).max, "SetDisputeGameArgs: gameType out of range");
        uint32 gameType = uint32(gtRaw);

        // No two rows may target the same (chainId, gameType): the later one would silently win.
        for (uint256 j = 0; j < resolvedGames.length; j++) {
            require(
                !(resolvedGames[j].chainId == chainId && resolvedGames[j].gameType == gameType),
                "SetDisputeGameArgs: duplicate (chainId, gameType) row"
            );
        }

        IDisputeGameFactory factory =
            IDisputeGameFactory(superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", chainId));
        require(address(factory).code.length > 0, "SetDisputeGameArgs: DisputeGameFactory has no code");

        // Start from the live gameArgs, then override only the fields present in the TOML.
        GameArgsFields memory m = _decodeArgs(factory.gameArgs(gameType));
        address impl = _optAddress(toml, base, "impl", factory.gameImpls(gameType));
        if (toml.keyExists(string.concat(base, ".permissioned"))) {
            m.permissioned = toml.readBool(string.concat(base, ".permissioned"));
        }
        if (toml.keyExists(string.concat(base, ".prestate"))) {
            m.prestate = toml.readBytes32(string.concat(base, ".prestate"));
        }
        m.vm = _optAddress(toml, base, "vm", m.vm);
        m.anchorStateRegistry = _optAddress(toml, base, "anchorStateRegistry", m.anchorStateRegistry);
        m.delayedWETH = _optAddress(toml, base, "delayedWETH", m.delayedWETH);
        m.proposer = _optAddress(toml, base, "proposer", m.proposer);
        m.challenger = _optAddress(toml, base, "challenger", m.challenger);

        bool setBond = toml.keyExists(string.concat(base, ".bond"));
        uint256 bond = setBond ? toml.readUint(string.concat(base, ".bond")) : factory.initBonds(gameType);

        _checkRow(impl, gameType, chainId, m);

        resolvedGames.push(
            ResolvedGame({
                chainId: chainId,
                gameType: gameType,
                impl: impl,
                gameArgs: _encodeGameArgs(impl, m, chainId),
                bond: bond,
                setBond: setBond
            })
        );
    }

    /// @notice Config-time safety checks for a resolved row (skipped when disabling, impl == 0).
    function _checkRow(address impl, uint32 gameType, uint256 chainId, GameArgsFields memory m) internal view {
        if (impl == address(0)) return;
        require(impl.code.length > 0, "SetDisputeGameArgs: impl has no code");
        // The impl must be a dispute game whose declared game type and chain are consistent with this
        // slot (blueprint impls return 0 for both — the binding lives in gameArgs).
        _validateImpl(impl, gameType, chainId);
        // Permissionless game types carry no proposer/challenger; a non-zero value almost certainly
        // means the operator meant `permissioned = true`.
        if (!m.permissioned) {
            require(
                m.proposer == address(0) && m.challenger == address(0),
                "SetDisputeGameArgs: proposer/challenger set on permissionless game"
            );
        }
        // A non-zero ASR must match the chain's registered AnchorStateRegistryProxy — a wrong ASR
        // silently anchors the game to the wrong output root. A zero ASR (reset) is left to the operator.
        if (m.anchorStateRegistry != address(0)) {
            try superchainAddrRegistry.getAddress("AnchorStateRegistryProxy", chainId) returns (address registeredAsr) {
                require(m.anchorStateRegistry == registeredAsr, "SetDisputeGameArgs: anchorStateRegistry mismatch");
            } catch {
                // Chain does not register an AnchorStateRegistryProxy; cannot cross-check.
            }
        }
    }

    /// @notice Issue one `setImplementation` (and optional `setInitBond`) per resolved row.
    function _build(address) internal override {
        for (uint256 i = 0; i < resolvedGames.length; i++) {
            ResolvedGame storage r = resolvedGames[i];
            IDisputeGameFactory factory =
                IDisputeGameFactory(superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", r.chainId));

            // Idempotent: skip a slot that already holds exactly this impl + gameArgs.
            if (factory.gameImpls(r.gameType) == r.impl && keccak256(factory.gameArgs(r.gameType)) == keccak256(r.gameArgs))
            {
                continue;
            }
            factory.setImplementation(r.gameType, r.impl, r.gameArgs);

            // Bond is only meaningful for a live game and only written when the config specified it.
            if (r.impl != address(0) && r.setBond && factory.initBonds(r.gameType) != r.bond) {
                factory.setInitBond(r.gameType, r.bond);
            }
        }
    }

    /// @notice Assert each slot ended up with the resolved impl, packed gameArgs, and bond.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal view override {
        for (uint256 i = 0; i < resolvedGames.length; i++) {
            ResolvedGame storage r = resolvedGames[i];
            IDisputeGameFactory factory =
                IDisputeGameFactory(superchainAddrRegistry.getAddress("DisputeGameFactoryProxy", r.chainId));

            require(factory.gameImpls(r.gameType) == r.impl, "SetDisputeGameArgs: impl mismatch");
            require(
                keccak256(factory.gameArgs(r.gameType)) == keccak256(r.gameArgs), "SetDisputeGameArgs: gameArgs mismatch"
            );

            if (r.impl != address(0)) {
                // A live game must carry a non-zero init bond, otherwise games are free to create and
                // the dispute economics break.
                require(factory.initBonds(r.gameType) != 0, "SetDisputeGameArgs: zero init bond on live game");
                if (r.setBond) {
                    require(factory.initBonds(r.gameType) == r.bond, "SetDisputeGameArgs: bond mismatch");
                }
            }
        }
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function _getCodeExceptions() internal pure override returns (address[] memory) {}

    // ----------------------------------------------------------------------------------------------
    // Internal helpers
    // ----------------------------------------------------------------------------------------------

    /// @notice Decoded view of an on-chain gameArgs blob. `permissioned` is inferred from the length;
    ///         an empty blob (new/disabled slot) decodes to all-zero / permissioned=false.
    struct GameArgsFields {
        bool permissioned;
        bytes32 prestate;
        address vm;
        address anchorStateRegistry;
        address delayedWETH;
        address proposer;
        address challenger;
    }

    /// @notice Count `[[gameConfig]]` rows by probing successive indices for a `.chainId` key.
    function _rowCount(string memory toml) internal view returns (uint256 count) {
        while (toml.keyExists(string.concat(".gameConfig[", count.toString(), "].chainId"))) {
            count++;
        }
    }

    /// @notice Read an optional address field; fall back to `dflt` when the key is absent.
    function _optAddress(string memory toml, string memory base, string memory field, address dflt)
        internal
        view
        returns (address)
    {
        string memory key = string.concat(base, ".", field);
        return toml.keyExists(key) ? toml.readAddress(key) : dflt;
    }

    /// @notice Decode an on-chain gameArgs blob into its fields. Reverts on an unexpected length.
    function _decodeArgs(bytes memory args) internal pure returns (GameArgsFields memory f) {
        if (args.length == 0) return f; // new or disabled slot — nothing to keep.
        require(args.length == 124 || args.length == 164, "SetDisputeGameArgs: unexpected on-chain gameArgs length");
        f.permissioned = args.length == 164;
        bytes32 prestate;
        address vm_;
        address asr;
        address weth;
        assembly {
            prestate := mload(add(args, 0x20)) // data offset 0
            vm_ := shr(96, mload(add(args, 0x40))) // data offset 32
            asr := shr(96, mload(add(args, 0x54))) // data offset 52
            weth := shr(96, mload(add(args, 0x68))) // data offset 72
        }
        f.prestate = prestate;
        f.vm = vm_;
        f.anchorStateRegistry = asr;
        f.delayedWETH = weth;
        if (f.permissioned) {
            address proposer;
            address challenger;
            assembly {
                proposer := shr(96, mload(add(args, 0x9c))) // data offset 124
                challenger := shr(96, mload(add(args, 0xb0))) // data offset 144
            }
            f.proposer = proposer;
            f.challenger = challenger;
        }
    }

    /// @notice Pack the resolved fields into the DisputeGameFactory `gameArgs` blob. Returns empty
    ///         bytes when the slot is being disabled (impl == address(0)).
    function _encodeGameArgs(address impl, GameArgsFields memory m, uint256 chainId)
        internal
        pure
        returns (bytes memory)
    {
        if (impl == address(0)) return bytes("");
        if (m.permissioned) {
            return abi.encodePacked(
                m.prestate, m.vm, m.anchorStateRegistry, m.delayedWETH, chainId, m.proposer, m.challenger
            );
        }
        return abi.encodePacked(m.prestate, m.vm, m.anchorStateRegistry, m.delayedWETH, chainId);
    }

    /// @notice Assert `impl` is a real dispute game whose declared game type and chain are consistent
    ///         with the target slot (blueprint impls return 0 for both; a contract that doesn't
    ///         expose these accessors is not a dispute game).
    function _validateImpl(address impl, uint32 gameType, uint256 chainId) internal view {
        try IDisputeGameImpl(impl).gameType() returns (uint32 implGameType) {
            require(implGameType == 0 || implGameType == gameType, "SetDisputeGameArgs: impl gameType mismatch");
        } catch {
            revert("SetDisputeGameArgs: impl is not a dispute game (gameType reverted)");
        }
        try IDisputeGameImpl(impl).l2ChainId() returns (uint256 implChainId) {
            require(implChainId == 0 || implChainId == chainId, "SetDisputeGameArgs: impl l2ChainId mismatch");
        } catch {
            revert("SetDisputeGameArgs: impl is not a dispute game (l2ChainId reverted)");
        }
    }
}

interface IDisputeGameFactory {
    function gameImpls(uint32 gameType) external view returns (address);
    function gameArgs(uint32 gameType) external view returns (bytes memory);
    function initBonds(uint32 gameType) external view returns (uint256);
    function setImplementation(uint32 gameType, address impl, bytes memory gameArgs) external;
    function setInitBond(uint32 gameType, uint256 amount) external;
}

interface IDisputeGameImpl {
    function gameType() external view returns (uint32);
    function l2ChainId() external view returns (uint256);
}
