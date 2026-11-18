// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "forge-std/Test.sol";
import {Claim} from "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {OPCMUpgradeV1000, IOPContractsManagerV1000} from "src/template/OPCMUpgradeV1000.sol";

contract OPCMUpgradeV1000PureHarness is OPCMUpgradeV1000 {
    function checkConfigFields(OPCMUpgrade memory u) external pure {
        _checkConfigFields(u);
    }

    function buildOneGameConfig(address proposer, uint32 gt, OPCMUpgrade memory u)
        external
        pure
        returns (IOPContractsManagerV1000.DisputeGameConfig memory)
    {
        return _buildOneGameConfig(proposer, gt, u);
    }

    function decodeZKTiming(bytes memory args) external pure returns (uint64, uint64, uint256) {
        return _decodeZKTiming(args);
    }

    function gameConfigHash(OPCMUpgrade memory u) external pure returns (bytes32) {
        return _gameConfigHash(u);
    }
}

/// @notice Fork-free checks of the template's config rules and ZK_DISPUTE_GAME encodings. The end-to-end behavior
/// against a v10 OPCM is covered by the example task once one is deployed on Sepolia.
contract OPCMUpgradeV1000Test is Test {
    string constant RGT_ERR =
        "OPCMUpgradeV1000: startingRespectedGameType must be an enabled super game type (5, 9 or 10)";
    string constant SCK_DISABLED_ERR =
        "OPCMUpgradeV1000: disabled SUPER_CANNON_KONA must have zero cannonKonaPrestate and superCannonKonaInitBond";
    string constant ZK_DISABLED_ERR = "OPCMUpgradeV1000: disabled ZK_DISPUTE_GAME must have zero zk fields";
    string constant CHALLENGE_ERR = "OPCMUpgradeV1000: zkMaxChallengeDuration out of range";
    string constant PROVE_ERR = "OPCMUpgradeV1000: zkMaxProveDuration out of range";

    OPCMUpgradeV1000PureHarness internal harness;

    function setUp() public {
        harness = new OPCMUpgradeV1000PureHarness();
    }

    /// @dev Both games enabled, respecting ZK_DISPUTE_GAME.
    function _valid() internal pure returns (OPCMUpgradeV1000.OPCMUpgrade memory u) {
        u.cannonKonaPrestate = Claim.wrap(bytes32(uint256(0x03)));
        u.chainId = 10;
        u.startingRespectedGameType = 10;
        u.superCannonKonaEnabled = true;
        u.superCannonKonaInitBond = 0.08 ether;
        u.zkChallengerBond = 1 ether;
        u.zkEnabled = true;
        u.zkInitBond = 0.08 ether;
        u.zkMaxChallengeDuration = 604800;
        u.zkMaxProveDuration = 259200;
        u.zkPrestate = Claim.wrap(bytes32(uint256(0x007a)));
    }

    function _sckOff(OPCMUpgradeV1000.OPCMUpgrade memory u)
        internal
        pure
        returns (OPCMUpgradeV1000.OPCMUpgrade memory)
    {
        u.superCannonKonaEnabled = false;
        u.cannonKonaPrestate = Claim.wrap(bytes32(0));
        u.superCannonKonaInitBond = 0;
        return u;
    }

    function _zkOff(OPCMUpgradeV1000.OPCMUpgrade memory u)
        internal
        pure
        returns (OPCMUpgradeV1000.OPCMUpgrade memory)
    {
        u.zkEnabled = false;
        u.zkPrestate = Claim.wrap(bytes32(0));
        u.zkMaxChallengeDuration = 0;
        u.zkMaxProveDuration = 0;
        u.zkChallengerBond = 0;
        u.zkInitBond = 0;
        return u;
    }

    function _expectConfigRevert(OPCMUpgradeV1000.OPCMUpgrade memory u, string memory err) internal {
        vm.expectRevert(bytes(err));
        harness.checkConfigFields(u);
    }

    /// @notice The respected game type must be SUPER_PERMISSIONED or an enabled SUPER_CANNON_KONA/ZK_DISPUTE_GAME.
    function test_checkConfigFields_respectedGameTypeMustBeEnabled() public {
        OPCMUpgradeV1000.OPCMUpgrade memory u = _valid();
        u.startingRespectedGameType = 9;
        harness.checkConfigFields(u);
        u.startingRespectedGameType = 5;
        harness.checkConfigFields(_zkOff(_sckOff(u)));

        u = _zkOff(_valid());
        _expectConfigRevert(u, RGT_ERR);

        u = _sckOff(_valid());
        u.startingRespectedGameType = 9;
        _expectConfigRevert(u, RGT_ERR);

        u = _valid();
        u.startingRespectedGameType = 1;
        _expectConfigRevert(u, RGT_ERR);
    }

    /// @notice An enabled SUPER_CANNON_KONA needs a prestate and a bond; a disabled one must have neither.
    function test_checkConfigFields_superCannonKonaFields() public {
        OPCMUpgradeV1000.OPCMUpgrade memory u = _valid();
        u.cannonKonaPrestate = Claim.wrap(bytes32(0));
        _expectConfigRevert(u, "OPCMUpgradeV1000: cannonKonaPrestate is zero");

        u = _valid();
        u.superCannonKonaInitBond = 0;
        _expectConfigRevert(u, "OPCMUpgradeV1000: superCannonKonaInitBond is zero");

        u = _sckOff(_valid());
        u.cannonKonaPrestate = Claim.wrap(bytes32(uint256(1)));
        _expectConfigRevert(u, SCK_DISABLED_ERR);

        u = _sckOff(_valid());
        u.superCannonKonaInitBond = 1;
        _expectConfigRevert(u, SCK_DISABLED_ERR);
    }

    /// @notice An enabled ZK_DISPUTE_GAME mirrors the OPCM's `_isValidZKDisputeGameConfig`: non-zero prestate,
    /// durations in (0, uint32 max], non-zero challenger bond, plus a non-zero init bond.
    function test_checkConfigFields_zkBounds() public {
        OPCMUpgradeV1000.OPCMUpgrade memory u = _valid();
        u.zkMaxChallengeDuration = type(uint32).max;
        u.zkMaxProveDuration = type(uint32).max;
        harness.checkConfigFields(u);

        u = _valid();
        u.zkMaxChallengeDuration = 0;
        _expectConfigRevert(u, CHALLENGE_ERR);
        u.zkMaxChallengeDuration = uint64(type(uint32).max) + 1;
        _expectConfigRevert(u, CHALLENGE_ERR);

        u = _valid();
        u.zkMaxProveDuration = 0;
        _expectConfigRevert(u, PROVE_ERR);
        u.zkMaxProveDuration = uint64(type(uint32).max) + 1;
        _expectConfigRevert(u, PROVE_ERR);

        u = _valid();
        u.zkPrestate = Claim.wrap(bytes32(0));
        _expectConfigRevert(u, "OPCMUpgradeV1000: zkPrestate is zero");

        u = _valid();
        u.zkChallengerBond = 0;
        _expectConfigRevert(u, "OPCMUpgradeV1000: zkChallengerBond is zero");

        u = _valid();
        u.zkInitBond = 0;
        _expectConfigRevert(u, "OPCMUpgradeV1000: zkInitBond is zero");
    }

    /// @notice A disabled ZK_DISPUTE_GAME must leave every ZK field at zero.
    function test_checkConfigFields_disabledZKMustBeZero() public {
        OPCMUpgradeV1000.OPCMUpgrade memory u = _zkOff(_valid());
        u.startingRespectedGameType = 9;
        harness.checkConfigFields(u);

        u.zkInitBond = 1;
        _expectConfigRevert(u, ZK_DISABLED_ERR);
        u = _zkOff(_valid());
        u.startingRespectedGameType = 9;
        u.zkMaxProveDuration = 1;
        _expectConfigRevert(u, ZK_DISABLED_ERR);
        u = _zkOff(_valid());
        u.startingRespectedGameType = 9;
        u.zkPrestate = Claim.wrap(bytes32(uint256(1)));
        _expectConfigRevert(u, ZK_DISABLED_ERR);
    }

    /// @notice The ZK_DISPUTE_GAME config is the 128-byte `ZKDisputeGameConfig` the OPCM requires, and a disabled
    /// game is sent with empty args and no bond.
    function test_buildOneGameConfig_zkEncoding() public view {
        OPCMUpgradeV1000.OPCMUpgrade memory u = _valid();
        IOPContractsManagerV1000.DisputeGameConfig memory cfg = harness.buildOneGameConfig(address(1), 10, u);
        assertTrue(cfg.enabled);
        assertEq(cfg.gameType, 10);
        assertEq(cfg.initBond, u.zkInitBond);
        assertEq(cfg.gameArgs.length, 128);
        (bytes32 prestate, uint64 maxChallenge, uint64 maxProve, uint256 challengerBond) =
            abi.decode(cfg.gameArgs, (bytes32, uint64, uint64, uint256));
        assertEq(prestate, Claim.unwrap(u.zkPrestate));
        assertEq(maxChallenge, u.zkMaxChallengeDuration);
        assertEq(maxProve, u.zkMaxProveDuration);
        assertEq(challengerBond, u.zkChallengerBond);

        cfg = harness.buildOneGameConfig(address(1), 10, _zkOff(u));
        assertFalse(cfg.enabled);
        assertEq(cfg.initBond, 0);
        assertEq(cfg.gameArgs.length, 0);
    }

    /// @notice `_decodeZKTiming` reads the durations and challenger bond from the 140-byte args the OPCM packs in
    /// `OPContractsManagerUtils.makeGameArgs`: prestate | verifier | maxChallengeDuration | maxProveDuration |
    /// challengerBond | anchorStateRegistry | weth.
    function test_decodeZKTiming_readsOPCMPackedArgs() public view {
        bytes memory packed = abi.encodePacked(
            bytes32(uint256(0x007a)),
            address(0x1111111111111111111111111111111111111111),
            uint64(604800),
            uint64(259200),
            uint256(1 ether),
            address(0x2222222222222222222222222222222222222222),
            address(0x3333333333333333333333333333333333333333)
        );
        (uint64 maxChallenge, uint64 maxProve, uint256 challengerBond) = harness.decodeZKTiming(packed);
        assertEq(maxChallenge, 604800);
        assertEq(maxProve, 259200);
        assertEq(challengerBond, 1 ether);
    }

    function test_decodeZKTiming_rejectsOtherLengths() public {
        vm.expectRevert(bytes("OPCMUpgradeV1000: unexpected ZK_DISPUTE_GAME gameArgs length"));
        harness.decodeZKTiming(new bytes(128));
    }

    /// @notice Chains sharing a DisputeGameFactory are compared by this hash: it covers every game field and ignores
    /// `chainId` and `expectedValidationErrors`.
    function test_gameConfigHash_coversGameFieldsOnly() public view {
        OPCMUpgradeV1000.OPCMUpgrade memory a = _valid();
        OPCMUpgradeV1000.OPCMUpgrade memory b = _valid();
        b.chainId = 130;
        b.expectedValidationErrors = "SYSCON-130";
        bytes32 base = harness.gameConfigHash(a);
        assertEq(harness.gameConfigHash(b), base);

        for (uint256 i = 0; i < 10; i++) {
            b = _valid();
            if (i == 0) b.cannonKonaPrestate = Claim.wrap(bytes32(uint256(0x04)));
            if (i == 1) b.startingRespectedGameType = 9;
            if (i == 2) b.superCannonKonaEnabled = false;
            if (i == 3) b.superCannonKonaInitBond = 0.09 ether;
            if (i == 4) b.zkChallengerBond = 2 ether;
            if (i == 5) b.zkEnabled = false;
            if (i == 6) b.zkInitBond = 0.09 ether;
            if (i == 7) b.zkMaxChallengeDuration = 1;
            if (i == 8) b.zkMaxProveDuration = 1;
            if (i == 9) b.zkPrestate = Claim.wrap(bytes32(uint256(0x007b)));
            assertTrue(harness.gameConfigHash(b) != base, vm.toString(i));
        }
    }
}
