// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {VmSafe} from "forge-std/Vm.sol";
import {stdToml} from "forge-std/StdToml.sol";
import {IGnosisSafe} from "@base-contracts/script/universal/IGnosisSafe.sol";

import {L2TaskBase} from "src/improvements/tasks/types/L2TaskBase.sol";
import {SuperchainAddressRegistry} from "src/improvements/SuperchainAddressRegistry.sol";
import {Action} from "src/libraries/MultisigTypes.sol";

/// @notice A template for calling `approveHash` on a Gnosis Safe. This is intended to be used for
/// Base's L1 ProxyAdmin Owner (L1PAO) which has an additional level of nesting than the OP-governed
/// L1PAO. The Base L1PAO is structured like this:
///   ┌───────┐┌───────┐┌───────┐┌───────┐┌───────┐┌───────┐
///   │Signer1││Signer2││Signer3││Signer4││Signer5││Signer6│
///   └┬──────┘└┬──────┘└┬──────┘└┬──────┘└┬──────┘└┬──────┘
///   ┌▽────────▽┐┌──────▽────────▽┐┌──────▽────────▽┐
///   │Base      ││Security Council││Opt. Foundation │
///   └┬─────────┘└┬───────────────┘└┬───────────────┘
///   ┌▽───────────▽┐                │
///   BaseNested    │                │
///   └┬────────────┘                │
///   ┌▽─────────────────────────────▽┐
///   │L1PAO                          │
///   └┬──────────────────────────────┘
///   ┌▽─────────┐
///   │ProxyAdmin│
///   └──────────┘
/// Therefore this template enables the Base and their Security Council (SC) to approve a
/// transaction on what we're calling the "Base Nested" contract. Specifically, this template is a
/// nested task that supports the following sequence:
///   1. Base and SC signers sign offline, and a facilitator collects their signatures.
///   2. The Base facilitator calls `approveHash` on the Base Nested contract. The transaction being
///      approved is an `approveHash` call from the BaseNested contract to the L1PAO.
///   3. The SC facilitator calls `approveHash` on the Base Nested contract. This is approving the
///      same transactions as step 2.
///   4. A facilitator can now execute this task. This will result in BaseNested calling `approveHash`
///      on the L1PAO. This enables the L1PAO to execute the transaction once it receives the
///      Optimism Foundation's approval, which happens outside of this task.
contract GnosisSafeApproveHash is L2TaskBase {
    using stdToml for string;

    /// @notice Safe transaction hash to be approved.
    bytes32 public safeTxHash;

    /// @notice The L1 ProxyAdmin Owner.
    address public l1PAO;

    /// @notice The BaseNested Safe that is approving a hash on the L1PAO.
    address public baseNested;

    /// @notice Returns the safe address string identifier.
    function safeAddressString() public pure override returns (string memory) {
        revert("safeAddressString must be set in the config file");
    }

    /// @notice Returns the storage write permissions required for this task. This is an array of
    /// contract names that are expected to be written to during the execution of the task.
    function _taskStorageWrites() internal view virtual override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "ProxyAdminOwner";
        return storageWrites;
    }

    /// @notice Returns an array of strings that refer to contract names in the address registry.
    /// Contracts with these names are expected to have their balance changes during the task.
    /// By default returns an empty array. Override this function if your task expects balance changes.
    function _taskBalanceChanges() internal view virtual override returns (string[] memory) {
        return new string[](0);
    }

    /// @notice Sets up the template with implementation configurations from a TOML file.
    /// State overrides are not applied yet. Keep this in mind when performing various pre-simulation assertions in this function.
    function _templateSetup(string memory _taskConfigFilePath) internal override {
        super._templateSetup(_taskConfigFilePath);

        // Only allow one chain to be modified at a time with this template.
        SuperchainAddressRegistry.ChainInfo[] memory chains = superchainAddrRegistry.getChains();
        require(chains.length == 1, "Must specify exactly one chain id to approve a hash for");

        // Read safe addresses from the address registry.
        l1PAO = superchainAddrRegistry.getAddress("ProxyAdminOwner", chains[0].chainId);
        baseNested = superchainAddrRegistry.get("BaseNestedSafe");

        // Read the safeTxHash from the TOML file and validate it.
        string memory toml = vm.readFile(_taskConfigFilePath);
        safeTxHash = toml.readBytes32(".safeTxHash");
        require(safeTxHash != bytes32(0), "safeTxHash is required");
        require(!isHashApprovedOnL1PAO(safeTxHash), "safeTxHash is already approved");
    }

    /// @notice Builds the actions for executing the operations
    function _build() internal override {
        IGnosisSafe(l1PAO).approveHash(safeTxHash);
    }

    /// @notice This method performs all validations and assertions that verify the calls executed as expected.
    function _validate(VmSafe.AccountAccess[] memory, Action[] memory) internal view override {
        require(isHashApprovedOnL1PAO(safeTxHash), "safeTxHash is not approved");
    }

    /// @notice Override to return a list of addresses that should not be checked for code length.
    function getCodeExceptions() internal view virtual override returns (address[] memory) {
        return new address[](0);
    }

    /// @notice Helper method to return whether or not a given hash is already approved.
    function isHashApprovedOnL1PAO(bytes32 _hash) internal view returns (bool) {
        require(l1PAO != address(0), "l1PAO is not set");
        require(baseNested != address(0), "baseNested is not set");
        return IGnosisSafe(l1PAO).approvedHashes(baseNested, _hash) == 1;
    }
}
