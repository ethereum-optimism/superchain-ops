// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {stdToml} from "lib/forge-std/src/StdToml.sol";
import {SimpleTaskBase} from "src/tasks/types/SimpleTaskBase.sol";
import {Action} from "src/libraries/MultisigTypes.sol";
import {RevShareCodeRepo} from "src/libraries/RevShareCodeRepo.sol";
import {Proxy} from "optimism/packages/contracts-bedrock/src/universal/Proxy.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

/// @notice Interface for the FeesDepositor contract on L1.
///         This is used to deposit fees into L2.
interface IFeesDepositor {
    function initialize(uint96 _minDepositAmount, address _l2Recipient, address _messenger, uint32 _gasLimit)
        external;
    function minDepositAmount() external view returns (uint96);
    function l2Recipient() external view returns (address);
    function gasLimit() external view returns (uint32);
}

/// @notice Interface for the CREATE2 deployer contract.
interface ICreate2Deployer {
    function deploy(uint256 value, bytes32 salt, bytes memory code) external;
}

/// @notice A template contract for deploying and initializing the FeesDepositor contract.
contract DeployFeesDepositor is SimpleTaskBase {
    using LibString for string;
    using stdToml for string;

    /// @notice The address of the CREATE2 deployer contract.
    /// @notice This is present in OP Stack chains as a Preinstall and on L1.
    address internal constant CREATE2_DEPLOYER = address(0x13b0D85CcB8bf860b6b79AF3029fCA081AE9beF2);

    /// @notice The salt for the deployment of the FeesDepositor contract.
    string public salt;
    /// @notice The address of the L2 recipient of the fees.
    address public l2Recipient;
    /// @notice The minimum amount of fees the depositor needs before initiating a deposit.
    uint96 public minDepositAmount;
    /// @notice The address of the portal contract.
    address public portal;
    /// @notice The gas limit for the deposit.
    uint32 public gasLimit;
    /// @notice The address of the proxy admin owner.
    address public proxyAdminOwner;

    /// @notice The initialization code for the proxy contract. Sent to the CREATE2 deployer.
    bytes internal _proxyInitCode;
    /// @notice The calculated address of the proxy contract.
    address internal _proxyCalculatedAddress;
    /// @notice The calculated address of the FeesDepositor implementation contract.
    address internal _implCalculatedAddress;

    /// @notice Returns the safe address string identifier.
    function safeAddressString() public pure override returns (string memory) {
        return "ProxyAdminOwner";
    }

    /// @notice Returns the storage write permissions required for this task. This is an array of
    /// contract names that are expected to be written to during the execution of the task.
    function _taskStorageWrites() internal pure virtual override returns (string[] memory) {}

    /// @notice Returns an array of strings that refer to contract names in the address registry.
    /// Contracts with these names are expected to have their balance changes during the task.
    /// By default returns an empty array. Override this function if your task expects balance changes.
    function _taskBalanceChanges() internal view virtual override returns (string[] memory) {}

    /// @notice Sets up the template with implementation configurations from a TOML file.
    /// State overrides are not applied yet. Keep this in mind when performing various pre-simulation assertions in this function.
    function _templateSetup(string memory _taskConfigFilePath, address) internal override {
        string memory tomlContent = vm.readFile(_taskConfigFilePath);
        salt = tomlContent.readString(".salt");
        require(bytes(salt).length > 0, "salt must be set");

        // Default to 0 if not set
        minDepositAmount = uint96(tomlContent.readUint(".minDepositAmount"));

        l2Recipient = tomlContent.readAddress(".l2Recipient");
        require(l2Recipient != address(0), "l2Recipient must be set");

        portal = tomlContent.readAddress(".portal");
        require(portal != address(0), "portal must be set");

        uint256 _gasLimitRaw = tomlContent.readUint(".gasLimit");
        require(_gasLimitRaw > 0, "gasLimit must be set");
        require(_gasLimitRaw <= type(uint32).max, "gasLimit must be less than uint32.max");
        gasLimit = uint32(_gasLimitRaw);

        proxyAdminOwner = simpleAddrRegistry.get("ProxyAdminOwner");

        _proxyInitCode = bytes.concat(type(Proxy).creationCode, abi.encode(proxyAdminOwner));

        _proxyCalculatedAddress =
            Create2.computeAddress(bytes32(bytes(salt)), keccak256(_proxyInitCode), CREATE2_DEPLOYER);
        vm.label(_proxyCalculatedAddress, "Proxy");

        _implCalculatedAddress = Create2.computeAddress(
            bytes32(bytes(salt)), keccak256(RevShareCodeRepo.feesDepositorCreationCode), CREATE2_DEPLOYER
        );
        vm.label(_implCalculatedAddress, "FeesDepositorV100");
    }

    /// @notice Builds the deployment transactions for the FeesDepositor implementation and proxy.
    /// @dev This function deploys both the implementation contract and the proxy contract using CREATE2,
    ///      then initializes the proxy with the implementation. The calculated addresses are validated
    ///      implicitly because if the calculated address of the Proxy would differ from the one we
    ///      calculated, the task would fail on the check for code to be present, since the changes
    ///      in build function revert and the parent contract validates that accessed accounts have code.
    function _build(address) internal override {
        // Deploy the FeesDepositor implementation contract using CREATE2
        ICreate2Deployer(CREATE2_DEPLOYER).deploy(0, bytes32(bytes(salt)), RevShareCodeRepo.feesDepositorCreationCode);

        // Deploy the proxy contract using CREATE2 with the calculated initialization code
        ICreate2Deployer(CREATE2_DEPLOYER).deploy(0, bytes32(bytes(salt)), _proxyInitCode);

        // Initialize the proxy by upgrading to the implementation and calling initialize
        Proxy(payable(_proxyCalculatedAddress)).upgradeToAndCall(
            _implCalculatedAddress,
            abi.encodeCall(IFeesDepositor.initialize, (minDepositAmount, l2Recipient, portal, gasLimit))
        );
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory, address) internal view override {
        require(
            IFeesDepositor(payable(_proxyCalculatedAddress)).minDepositAmount() == minDepositAmount,
            "minDepositAmount mismatch"
        );
        require(IFeesDepositor(payable(_proxyCalculatedAddress)).l2Recipient() == l2Recipient, "l2Recipient mismatch");
        require(IFeesDepositor(payable(_proxyCalculatedAddress)).gasLimit() == gasLimit, "gasLimit mismatch");
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function _getCodeExceptions() internal view virtual override returns (address[] memory) {
        address[] memory codeExceptions = new address[](1);
        codeExceptions[0] = _proxyCalculatedAddress;
        return codeExceptions;
    }
}
