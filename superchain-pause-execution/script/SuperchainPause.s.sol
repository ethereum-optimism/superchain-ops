// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

interface IDeputyPauseModule {
    function pause(bytes32 _nonce, bytes memory _signature) external;
}

contract SuperchainPause is Script {
    /// @notice Typehash for PauseMessage.
    bytes32 internal constant PAUSE_MESSAGE_TYPEHASH = keccak256("PauseMessage(bytes32 nonce)");

    /// @notice Typehash for DeputyAuthMessage.
    bytes32 internal constant DEPUTY_AUTH_MESSAGE_TYPEHASH = keccak256("DeputyAuthMessage(address deputy)");

    /// @notice Asserts that the DANGEROUS_SUBMIT_SIGNATURE environment variable is set to true.
    function assertDangerousSubmitSignature() public view {
        bool dangerousSubmitSignature = vm.envOr("DANGEROUS_SUBMIT_SIGNATURE", false);
        if (!dangerousSubmitSignature) {
            revert("DANGEROUS_SUBMIT_SIGNATURE is not set to true");
        }
    }

    /// @notice Retrieves or computes the address of the DeputyPauseModule. If CREATE_NEW_MODULE is
    ///         true, will compute the address of the DeputyPauseModule based on the creator
    ///         address. Otherwise, will return the address of the DeputyPauseModule provided in
    ///         the environment.
    /// @return Address of the DeputyPauseModule.
    function getModuleAddress() public view returns (address) {
        bool createNewModule = vm.envOr("CREATE_NEW_MODULE", false);
        address dpmAddress = vm.envOr("DEPUTY_PAUSE_MODULE_ADDRESS", address(0));
        address creatorAddress = vm.envOr("DEPUTY_PAUSE_MODULE_CREATOR_ADDRESS", address(0));

        if (createNewModule) {
            if (dpmAddress != address(0)) {
                revert("Cannot provide both DEPUTY_PAUSE_MODULE_ADDRESS and CREATE_NEW_MODULE");
            }

            if (creatorAddress == address(0)) {
                revert("Must provide DEPUTY_PAUSE_MODULE_CREATOR_ADDRESS when CREATE_NEW_MODULE is true");
            }

            uint64 nonce = vm.getNonce(creatorAddress);
            return vm.computeCreateAddress(creatorAddress, nonce);
        } else {
            if (creatorAddress != address(0)) {
                revert("Cannot provide DEPUTY_PAUSE_MODULE_CREATOR_ADDRESS when CREATE_NEW_MODULE is false");
            }

            if (dpmAddress == address(0)) {
                revert("Must provide DEPUTY_PAUSE_MODULE_ADDRESS when CREATE_NEW_MODULE is false");
            }

            return dpmAddress;
        }
    }

    /// @notice Retrieves the private key of the Pause Deputy from the environment.
    /// @return Private key of the Pause Deputy.
    function getPauseDeputyKey() public view returns (uint256) {
        return uint256(vm.envBytes32("PAUSE_DEPUTY_PRIVATE_KEY"));
    }

    /// @notice Retrieves the address of the Pause Deputy from the private key.
    /// @return Address of the Pause Deputy.
    function getPauseDeputyAddress() public view returns (address) {
        return vm.addr(getPauseDeputyKey());
    }

    /// @notice Helper function to compute EIP-712 typed data hash
    /// @param _verifyingContract The verifying contract.
    /// @param _chainId Chain ID to use for the domain separator.
    /// @param _structHash The struct hash.
    /// @return The EIP-712 typed data hash.
    function hashTypedData(address _verifyingContract, uint256 _chainId, bytes32 _structHash)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                keccak256(
                    abi.encode(
                        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                        keccak256("DeputyPauseModule"),
                        keccak256("1"),
                        _chainId,
                        _verifyingContract
                    )
                ),
                _structHash
            )
        );
    }

    /// @notice Generates the signature for the auth message.
    function signAuthMessage() public {
        console.log(block.chainid);
        bytes32 structHash = keccak256(abi.encode(DEPUTY_AUTH_MESSAGE_TYPEHASH, getPauseDeputyAddress()));
        bytes32 digest = hashTypedData(getModuleAddress(), block.chainid, structHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(getPauseDeputyKey(), digest);
        console.logBytes(abi.encodePacked(r, s, v));
    }

    /// @notice Generates the signature for the pause message.
    /// @param _nonce Nonce to use for the pause message.
    function signPauseMessage(bytes32 _nonce) public {
        bytes32 structHash = keccak256(abi.encode(PAUSE_MESSAGE_TYPEHASH, _nonce));
        bytes32 digest = hashTypedData(getModuleAddress(), block.chainid, structHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(getPauseDeputyKey(), digest);
        console.logBytes(abi.encodePacked(r, s, v));
    }

    /// @notice Triggers the Superchain-wide pause.
    /// @param _nonce Nonce used for the pause message.
    /// @param _signature Signature for the pause message.
    function pause(bytes32 _nonce, bytes memory _signature) public {
        assertDangerousSubmitSignature();
        vm.startBroadcast();
        IDeputyPauseModule(getModuleAddress()).pause(_nonce, _signature);
        vm.stopBroadcast();
    }
}
