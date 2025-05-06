// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {OptimismPortal2, IDisputeGame} from "@eth-optimism-bedrock/src/L1/OptimismPortal2.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {LibString} from "solady/utils/LibString.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";

interface ASR {
    function getAnchorRoot() external view returns (bytes32, uint256);
}

contract SignFromJson is OriginalSignFromJson {
    using LibString for string;

    address constant SENTINEL_MODULE = address(0x1);

    // Chains for this task.
    string constant l1ChainName = "sepolia";
    string constant l2ChainName = "op";

    GnosisSafe safe = GnosisSafe(payable(0x26DF14a0C889de2448d228Ee23B2530550b5B774));

    function setUp() public {}

    function getCodeExceptions() internal view override returns (address[] memory) {
        address[] memory safeOwners = safe.getOwners();
        address[] memory shouldHaveCodeExceptions = new address[](safeOwners.length);

        for (uint256 i = 0; i < safeOwners.length; i++) {
            shouldHaveCodeExceptions[i] = safeOwners[i];
        }
        return shouldHaveCodeExceptions;
    }

    function getAllowedStorageAccess() internal view override returns (address[] memory allowed) {
        allowed = new address[](4);
        allowed[0] = vm.envAddress("OWNER_SAFE");
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory /* simPayload */ )
        internal
        view
        override
    {
        console.log("Running post-deploy assertions");

        ASR asr = ASR(0xE91B4069B8Cbab7DC621C3525B462853467cCF02);
        (bytes32 root, uint256 num) = asr.getAnchorRoot();
        require(root != bytes32(0x0), "invalid root");
        require(num != 0, "invalid num");
    }
}
