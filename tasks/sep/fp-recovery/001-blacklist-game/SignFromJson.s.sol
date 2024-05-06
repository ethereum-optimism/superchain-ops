// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {SignFromJson as OriginalSignFromJson} from "script/SignFromJson.s.sol";
import {OptimismPortal2, IDisputeGame} from "@eth-optimism-bedrock/src/L1/OptimismPortal2.sol";
import {Types} from "@eth-optimism-bedrock/scripts/Types.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {console2 as console} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {LibString} from "solady/utils/LibString.sol";
import {GnosisSafe} from "safe-contracts/GnosisSafe.sol";

contract SignFromJson is OriginalSignFromJson {
    using LibString for string;

    // Chains for this task.
    string constant l1ChainName = "sepolia";
    string constant l2ChainName = "op";

    // Safe contract for this task.
    GnosisSafe securityCouncilSafe = GnosisSafe(payable(0xf64bc17485f0B4Ea5F06A96514182FC4cB561977));
    GnosisSafe foundationSafe = GnosisSafe(payable(0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B));

    // Known EOAs to exclude from safety checks.
    address constant l2OutputOracleProposer = 0x49277EE36A024120Ee218127354c4a3591dc90A9; // cast call $L2OO "PROPOSER()(address)"
    address constant l2OutputOracleChallenger = 0xfd1D2e729aE8eEe2E146c033bf4400fE75284301; // In registry addresses.
    address constant systemConfigOwner = 0xfd1D2e729aE8eEe2E146c033bf4400fE75284301; // In registry addresses.
    address constant batchSenderAddress = 0x8F23BB38F531600e5d8FDDaAEC41F13FaB46E98c; // In registry genesis-system-configs
    address constant p2pSequencerAddress = 0x57CACBB0d30b01eb2462e5dC940c161aff3230D3; // cast call $SystemConfig "unsafeBlockSigner()(address)"
    address constant batchInboxAddress = 0xff00000000000000000000000000000011155420; // In registry yaml.

    Types.ContractSet proxies;

    /// @notice Sets up the contract
    function setUp() public {
        proxies = _getContractSet();
    }

    function checkBlacklisted() internal view {
        OptimismPortal2 portal = OptimismPortal2(payable(proxies.OptimismPortal));

        // Read the game that is to be blacklisted from the input JSON.
        string memory inputJson;
        string memory path = "/tasks/sep/fp-recovery/001-blacklist-game/input.json";
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            inputJson = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        address blacklistedGame = stdJson.readAddress(inputJson, "$.transactions[0].contractInputsValues._disputeGameProxy");
        require(portal.disputeGameBlacklist(IDisputeGame(blacklistedGame)), "Dispute game is not blacklisted");
    }

    function getCodeExceptions() internal view override returns (address[] memory) {
        // Safe owners will appear in storage in the LivenessGuard when added
        address[] memory securityCouncilSafeOwners = securityCouncilSafe.getOwners();
        address[] memory shouldHaveCodeExceptions = new address[](6 + securityCouncilSafeOwners.length);

        shouldHaveCodeExceptions[0] = l2OutputOracleProposer;
        shouldHaveCodeExceptions[1] = l2OutputOracleChallenger;
        shouldHaveCodeExceptions[2] = systemConfigOwner;
        shouldHaveCodeExceptions[3] = batchSenderAddress;
        shouldHaveCodeExceptions[4] = p2pSequencerAddress;
        shouldHaveCodeExceptions[5] = batchInboxAddress;

        for (uint256 i = 0; i < securityCouncilSafeOwners.length; i++) {
            shouldHaveCodeExceptions[6 + i] = securityCouncilSafeOwners[i];
        }

        return shouldHaveCodeExceptions;
    }

    /// @notice Checks the correctness of the deployment
    function _postCheck(Vm.AccountAccess[] memory accesses, SimulationPayload memory /* simPayload */ )
        internal
        view
        override
    {
        console.log("Running post-deploy assertions");

        checkStateDiff(accesses);
        checkBlacklisted();

        console.log("All assertions passed!");
    }

    /// @notice Reads the contract addresses from lib/superchain-registry/superchain/extra/addresses/${l1ChainName}/${l2ChainName}.json
    function _getContractSet() internal view returns (Types.ContractSet memory _proxies) {
        string memory addressesJson;

        // Read addresses json
        string memory path = string.concat(
            "/lib/superchain-registry/superchain/extra/addresses/", l1ChainName, "/", l2ChainName, ".json"
        );
        try vm.readFile(string.concat(vm.projectRoot(), path)) returns (string memory data) {
            addressesJson = data;
        } catch {
            revert(string.concat("Failed to read ", path));
        }

        _proxies.OptimismPortal = stdJson.readAddress(addressesJson, "$.OptimismPortalProxy");
    }
}
