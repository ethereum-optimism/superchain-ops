// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {console2 as console} from "forge-std/console2.sol";
import {LibString} from "solady/utils/LibString.sol";
import {VerificationBase, SuperchainRegistry} from "script/verification/Verification.s.sol";
import "@eth-optimism-bedrock/src/dispute/lib/Types.sol";
import {IAnchorStateRegistry} from "@eth-optimism-bedrock/src/dispute/interfaces/IAnchorStateRegistry.sol";
import {ISemver} from "@eth-optimism-bedrock/src/universal/ISemver.sol";

// Describes an initial anchor state for a game type.
// It's not exported from the contracts package.
struct StartingAnchorRoot {
    GameType gameType;
    OutputRoot outputRoot;
}

// This contract checks for a correct update of anchors in an existing AnchorStateRegistry.
// It confirms that the implementation doesn't change and that the expected new anchors are set.
abstract contract AnchorStateRegistryAnchorUpdate is VerificationBase, SuperchainRegistry {
    using LibString for string;

    address immutable asrImpl;
    IAnchorStateRegistry immutable asr;
    StartingAnchorRoot[] startingAnchorRoots;

    constructor(StartingAnchorRoot[] memory _startingAnchorRoots) {
        startingAnchorRoots = _startingAnchorRoots;
        asrImpl = getProxyImplementation(proxies.AnchorStateRegistry);
        asr = IAnchorStateRegistry(proxies.AnchorStateRegistry);

        addAllowedStorageAccess(proxies.AnchorStateRegistry);

        _precheckASR();
    }

    function _precheckASR() internal view {
        console.log("precheck ASR");

        require(ISemver(address(asr)).version().eq(standardVersions.AnchorStateRegistry.version), "pre-au-10");
    }

    function checkAnchorUpdates() public {
        console.log("check anchor updates");

        // Note that the DisputeGameUpgrade already checks for the correct ASRs of each game.

        // require implementation to be the same after temporarily being set to the
        // storage setter contract.
        require(asrImpl == getProxyImplementation(proxies.AnchorStateRegistry), "au-10");

        for (uint256 i = 0; i < startingAnchorRoots.length; i++) {
            StartingAnchorRoot memory anchor = startingAnchorRoots[i];
            console.log("check anchor for game type", anchor.gameType.raw());
            (Hash root, uint256 l2BlockNumber) = asr.anchors(anchor.gameType);
            require(anchor.outputRoot.root.raw() == root.raw(), "au-20");
            require(anchor.outputRoot.l2BlockNumber == l2BlockNumber, "au-30");
        }
    }
}
