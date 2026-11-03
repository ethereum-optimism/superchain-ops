// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {OPCMUpgradeV900} from "src/template/OPCMUpgradeV900.sol";

interface IOptimismPortalLockbox {
    function ethLockbox() external view returns (address);
}

interface IETHLockboxAuth {
    function authorizedPortals(address) external view returns (bool);
}

interface ISystemConfigFeatures {
    function isFeatureEnabled(bytes32) external view returns (bool);
}

/// @notice Runs the 045 example task after stripping Unichain Sepolia's lockbox, pinning that the
/// upgrade deploys a fresh one, wires the portal to it and migrates the portal's ETH into it.
/// OP Sepolia keeps its lockbox in the same run, so both paths of the instruction are covered.
contract OPCMUpgradeV900LockboxTest is Test {
    string constant CONFIG = "test/tasks/example/sep/045-opcm-upgrade-v900/config.toml";
    uint256 internal constant FORK_BLOCK_NUMBER = 11_999_987;
    address internal constant FOUNDATION_UPGRADE_SAFE = 0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B;

    // Unichain Sepolia.
    address internal constant PORTAL = 0x0d83dab629f0e0F9d36c0Cbc89B69a489f0751bD;
    address internal constant SYSTEM_CONFIG = 0xaeE94b9aB7752D3F7704bDE212c0C6A0b701571D;
    address internal constant LOCKBOX = 0x62D47fd9256248D33A38A22ac4F0336Da1cfdfe4;

    // OptimismPortal2 `ethLockbox` slot and SystemConfig `isFeatureEnabled` mapping slot.
    bytes32 internal constant PORTAL_LOCKBOX_SLOT = bytes32(uint256(63));
    uint256 internal constant SYSTEM_CONFIG_FEATURES_SLOT = 109;
    bytes32 internal constant ETH_LOCKBOX = "ETH_LOCKBOX";
    uint256 internal constant PORTAL_ETH = 1 ether;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("sepolia"), FORK_BLOCK_NUMBER);
        bytes32 featureSlot = keccak256(abi.encode(ETH_LOCKBOX, SYSTEM_CONFIG_FEATURES_SLOT));
        // Check the slots against the live layout before rewriting them.
        assertEq(address(uint160(uint256(vm.load(PORTAL, PORTAL_LOCKBOX_SLOT)))), LOCKBOX, "portal lockbox slot");
        assertEq(uint256(vm.load(SYSTEM_CONFIG, featureSlot)), 1, "ETH_LOCKBOX feature slot");
        vm.store(PORTAL, PORTAL_LOCKBOX_SLOT, bytes32(0));
        vm.store(SYSTEM_CONFIG, featureSlot, bytes32(0));
        vm.deal(PORTAL, PORTAL_ETH);
    }

    function test_upgrade_deploys_lockbox_for_chain_without_one() public {
        OPCMUpgradeV900 task = new OPCMUpgradeV900();
        task.simulate(CONFIG, FOUNDATION_UPGRADE_SAFE);

        address lockbox = IOptimismPortalLockbox(PORTAL).ethLockbox();
        assertTrue(lockbox != address(0) && lockbox != LOCKBOX, "portal not wired to a new lockbox");
        assertGt(lockbox.code.length, 0, "new lockbox has no code");
        assertTrue(IETHLockboxAuth(lockbox).authorizedPortals(PORTAL), "portal not authorized on new lockbox");
        assertTrue(ISystemConfigFeatures(SYSTEM_CONFIG).isFeatureEnabled(ETH_LOCKBOX), "ETH_LOCKBOX not enabled");
        assertEq(PORTAL.balance, 0, "portal ETH not migrated");
        assertEq(lockbox.balance, PORTAL_ETH, "new lockbox did not receive the portal ETH");
    }
}
