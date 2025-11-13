// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IOptimismPortal2} from "@eth-optimism-bedrock/interfaces/L1/IOptimismPortal2.sol";
import {ICreate2Deployer} from "src/interfaces/ICreate2Deployer.sol";

/// @title RevShareCommon
/// @notice Common constants and helper functions shared across RevShare libraries
library RevShareCommon {
    /// @notice The address of the CREATE2 Deployer predeploy on L2.
    address internal constant CREATE2_DEPLOYER = 0x13b0D85CcB8bf860b6b79AF3029fCA081AE9beF2;

    /// @notice The address of the ProxyAdmin predeploy on L2.
    address internal constant PROXY_ADMIN = 0x4200000000000000000000000000000000000018;

    /// @notice The address of the FeeSplitter predeploy on L2.
    address internal constant FEE_SPLITTER = 0x420000000000000000000000000000000000002B;

    /// @notice The gas limit for the upgrade calls on L2.
    uint64 internal constant UPGRADE_GAS_LIMIT = 150_000;

    /// @notice The salt prefix for the RevShare system.
    string internal constant SALT_SEED = "RevShare";

    /// @notice Deploys a contract via CREATE2 on L2 by depositing a transaction to the OptimismPortal2
    /// @param _portal The OptimismPortal2 address on L1
    /// @param _gasLimit Gas limit for the L2 transaction
    /// @param _salt Salt for CREATE2 deployment
    /// @param _initCode Contract creation code (creationCode + constructor args)
    function depositCreate2(address _portal, uint64 _gasLimit, bytes32 _salt, bytes memory _initCode) internal {
        IOptimismPortal2(payable(_portal)).depositTransaction({
            _to: CREATE2_DEPLOYER,
            _value: 0,
            _gasLimit: _gasLimit,
            _isCreation: false,
            _data: abi.encodeCall(ICreate2Deployer.deploy, (0, _salt, _initCode))
        });
    }

    /// @notice Calls a contract on L2 by depositing a transaction to the OptimismPortal2
    /// @param _portal The OptimismPortal2 address on L1
    /// @param _target Target contract address on L2
    /// @param _gasLimit Gas limit for the L2 transaction
    /// @param _data Calldata for the L2 transaction
    function depositCall(address _portal, address _target, uint64 _gasLimit, bytes memory _data) internal {
        IOptimismPortal2(payable(_portal)).depositTransaction({
            _to: _target,
            _value: 0,
            _gasLimit: _gasLimit,
            _isCreation: false,
            _data: _data
        });
    }

    /// @notice Generates a salt for CREATE2 deployments
    /// @param _suffix Suffix to append to the salt seed
    /// @return Salt for CREATE2 deployment
    function getSalt(string memory _suffix) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(SALT_SEED, ":", _suffix));
    }
}
