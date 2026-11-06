// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {OPCMUpgradeV900} from "src/template/OPCMUpgradeV900.sol";

interface IAnchorStateRegistryRespected {
    function respectedGameType() external view returns (uint32);
    function setRespectedGameType(uint32) external;
}

interface ISystemConfigView {
    function delayedWETH() external view returns (address);
    function guardian() external view returns (address);
}

interface IOptimismPortalAnchorStateRegistry {
    function anchorStateRegistry() external view returns (address);
}

/// @notice Runs the 046 example task after clearing Unichain Sepolia's SUPER_CANNON_KONA game and rotating its
/// AnchorStateRegistry to SUPER_PERMISSIONED, so the chain runs only SUPER_PERMISSIONED and the registry finds no
/// WETH entry for it. Pins that the upgrade's DelayedWETH re-initialization is still allowlisted, from the
/// SystemConfig rather than from a game type.
contract OPCMUpgradeV900DelayedWETHTest is Test {
    string constant CONFIG = "test/tasks/example/sep/046-opcm-upgrade-v900/config.toml";
    string constant TEST_CONFIG = "test-config-files/opcm-upgrade-v900-super-permissioned-only.toml";
    uint256 internal constant FORK_BLOCK_NUMBER = 12_057_300;
    address internal constant FOUNDATION_UPGRADE_SAFE = 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B;

    // Unichain Sepolia.
    address internal constant DISPUTE_GAME_FACTORY = 0xeff73e5aa3B9AEC32c659Aa3E00444d20a84394b;
    address internal constant SYSTEM_CONFIG = 0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D;
    address internal constant PORTAL = 0x0d83dab629f0e0F9d36c0Cbc89B69a489f0751bD;
    address internal constant SUPER_CANNON_KONA_IMPL = 0x19AF533Cc2A2A55786DCB8672aA5717e64213208;

    // DisputeGameFactory `gameImpls` mapping slot.
    uint256 internal constant GAME_IMPLS_SLOT = 101;
    uint32 internal constant SUPER_PERMISSIONED = 5;
    uint32 internal constant SUPER_CANNON_KONA = 9;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("sepolia"), FORK_BLOCK_NUMBER);
        bytes32 slot = keccak256(abi.encode(uint256(SUPER_CANNON_KONA), GAME_IMPLS_SLOT));
        assertEq(address(uint160(uint256(vm.load(DISPUTE_GAME_FACTORY, slot)))), SUPER_CANNON_KONA_IMPL, "impl slot");
        vm.store(DISPUTE_GAME_FACTORY, slot, bytes32(0));
        address asr = IOptimismPortalAnchorStateRegistry(PORTAL).anchorStateRegistry();
        vm.prank(ISystemConfigView(SYSTEM_CONFIG).guardian());
        IAnchorStateRegistryRespected(asr).setRespectedGameType(SUPER_PERMISSIONED);

        // Unichain Sepolia respects SUPER_PERMISSIONED; OP Sepolia is unchanged.
        string memory config = vm.readFile(CONFIG);
        config = _replace(
            config,
            "initBond = 80000000000000000 # 0.08 ETH, the chain's current SUPER_CANNON_KONA bond\n"
            "startingRespectedGameType = 9 # SUPER_CANNON_KONA, unchanged",
            "initBond = 80000000000000000\nstartingRespectedGameType = 5"
        );
        // The v9 validator reports the cleared SUPER_CANNON_KONA game on the stripped chain.
        config = _replace(
            config,
            "# Live validator output captured during simulation against the v9 OPCM.\n" 'expectedValidationErrors = ""',
            "# Live validator output captured during simulation against the v9 OPCM.\n"
            'expectedValidationErrors = "SCKDG-SHAPE,SCKDG-10"'
        );
        vm.createDir("test-config-files", true);
        vm.writeFile(TEST_CONFIG, config);
    }

    function test_upgrade_allowlists_delayed_weth_without_weth_registry_entry() public {
        OPCMUpgradeV900 task = new OPCMUpgradeV900();
        task.simulate(TEST_CONFIG, FOUNDATION_UPGRADE_SAFE);

        address asr = IOptimismPortalAnchorStateRegistry(PORTAL).anchorStateRegistry();
        assertEq(IAnchorStateRegistryRespected(asr).respectedGameType(), SUPER_PERMISSIONED, "respected game type");

        address delayedWETH = ISystemConfigView(SYSTEM_CONFIG).delayedWETH();
        address[] memory allowed = task.getAllowedStorageAccess();
        bool allowlisted;
        for (uint256 i = 0; i < allowed.length; i++) {
            if (allowed[i] == delayedWETH) allowlisted = true;
        }
        assertTrue(allowlisted, "SystemConfig DelayedWETH not allowlisted");
    }

    /// @notice Returns `s` with `from` replaced by `to`, failing if `from` is absent.
    function _replace(string memory s, string memory from, string memory to) internal pure returns (string memory) {
        string memory out = vm.replace(s, from, to);
        assertTrue(keccak256(bytes(out)) != keccak256(bytes(s)), "config edit did not apply");
        return out;
    }
}
