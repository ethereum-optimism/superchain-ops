// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {JsonTxBuilderBase} from "src/JsonTxBuilderBase.sol";
import {MultisigBuilder} from "@base-contracts/script/universal/MultisigBuilder.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/console.sol";
import {Vm} from "forge-std/Vm.sol";
import {Utils} from "src/libraries/Utils.sol";

/// @title PresignPauseFromJson
/// @notice A script that reads a JSON file and builds a series of transactions from it. This script is
///     intended to be used only in the presigned pause runbooks.
contract PresignPauseFromJson is MultisigBuilder, JsonTxBuilderBase {
    function getAllowedStorageAccess() internal view override returns (address[] memory allowed) {
        allowed = new address[](2);
        allowed[0] = vm.envAddress("SUPERCHAIN_CONFIG_ADDR"); // The storage for the pause will be set to `1`.
        allowed[1] = _ownerSafe(); // The nonce is updated in the  Foundation Operations Safe (FOS).
    }

    function _simulationOverrides()
        internal
        view
        virtual
        override
        returns (Simulation.StateOverride[] memory overrides_)
    {
        // If SIMULATE_WITHOUT_LEDGER is set, we add an override to allow the script to run using the same
        // test address as defined in presigned-pause.just. This is necessary because the presigner tool requires
        // access to the private key of the address that will sign the transaction. Therefore we must insert a test
        // address into the owners list.
        if (Utils.isFeatureEnabled("SIMULATE_WITHOUT_LEDGER")) {
            console.log("Adding override for test sender");
            address safe = _ownerSafe();
            uint256 nonce = _getNonce(safe);
            overrides_ = new Simulation.StateOverride[](1);
            overrides_[0] = Simulation.overrideSafeThresholdOwnerAndNonce(safe, vm.envAddress("TEST_SENDER"), nonce);
        }
    }

    /// @notice Overrides the MultisigBuilder's _addOverrides function to prevent creating multiple separate state
    ///         overrides for the owner safe when using SIMULATE_WITHOUT_LEDGER.
    function _safeOverrides(address _safe, address _owner)
        internal
        view
        override
        returns (Simulation.StateOverride memory override_)
    {
        if (Utils.isFeatureEnabled("SIMULATE_WITHOUT_LEDGER")) {
            override_;
        } else {
            override_ = super._safeOverrides(_safe, _owner);
        }
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3[] memory) {
        string memory jsonContent = vm.readFile(vm.envOr("INPUT_JSON_PATH", string("input.json")));
        return _buildCallsFromJson(jsonContent);
    }

    // todo: allow passing this as a script argument.
    function _ownerSafe() internal view override returns (address) {
        return vm.envAddress("PRESIGNER_SAFE");
    }

    /// @notice This function is called after the simulation of the transactions is done.
    ///     It checks that the transactions only write to the nonce of the PRESIGNER_SAFE contract and the paused slot of
    ///     the SuperchainConfig contract.
    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload)
        internal
        view
        virtual
        override
    {
        checkStateDiff(accesses);
        for (uint256 i; i < accesses.length; i++) {
            Vm.AccountAccess memory accountAccess = accesses[i];

            for (uint256 j; j < accountAccess.storageAccesses.length; j++) {
                Vm.StorageAccess memory storageAccess = accountAccess.storageAccesses[j];

                if (storageAccess.isWrite) {
                    console.log("Checking Owner Safe storage writes");
                    if (storageAccess.account == _ownerSafe()) {
                        require(storageAccess.slot == bytes32(uint256(5)), "The only allowed write is to the nonce");
                        require(
                            uint256(storageAccess.previousValue) == uint256(storageAccess.newValue) - 1,
                            "The nonce should have increased by 1"
                        );
                    } else if (storageAccess.account == vm.envAddress("SUPERCHAIN_CONFIG_ADDR")) {
                        console.log("Checking SuperchainConfig storage writes");
                        require(
                            storageAccess.slot
                                == bytes32(0x54176ff9944c4784e5857ec4e5ef560a462c483bf534eda43f91bb01a470b1b6),
                            "The only allowed write is to paused slot."
                        );
                        require(uint256(storageAccess.newValue) == 1, "The contract should be paused.");
                    } else {
                        revert("No other storage writes are allowed");
                    }
                }
            }
        }
        simPayload; // Silences unused variable warning.
    }
}
