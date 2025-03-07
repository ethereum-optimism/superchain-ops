// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Simulation} from "@base-contracts/script/universal/Simulation.sol";

contract StateOverrideManager {
    /// @notice The state overrides for the local and tenderly simulation
    Simulation.StateOverride[] internal _stateOverrides;

    /// @notice Creates a default state override for the parent multisig (nonce, threshold, owner).
    function createDefaultTenderlyOverride(address parentMultisig, uint256 nonce)
        public
        view
        returns (Simulation.StateOverride memory)
    {
        Simulation.StateOverride memory defaultOverride;
        defaultOverride.contractAddress = parentMultisig;
        defaultOverride = Simulation.addOverride(
            defaultOverride, Simulation.StorageOverride({key: bytes32(uint256(0x4)), value: bytes32(uint256(0x1))})
        );
        defaultOverride = Simulation.addOverride(
            defaultOverride, Simulation.StorageOverride({key: bytes32(uint256(0x5)), value: bytes32(nonce)})
        );
        defaultOverride = Simulation.addOwnerOverride(parentMultisig, defaultOverride, msg.sender);
        return defaultOverride;
    }
}
