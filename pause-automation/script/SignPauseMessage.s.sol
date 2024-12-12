// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

import {Safe} from "@safe-global/contracts/Safe.sol";

library StringUtils {
    function compareStrings(
        string memory _a,
        string memory _b
    ) internal pure returns (bool) {
        return
            keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }
}

// TODO: will be replaced with interface from optimism monorepo once merged.
interface IDeputyPauseModule {
    error DeputyPauseModule_InvalidDeputy();
    error DeputyPauseModule_InvalidFoundationSafe();
    error DeputyPauseModule_InvalidDeputyGuardianModule();
    error DeputyPauseModule_InvalidSuperchainConfig();
    error DeputyPauseModule_ExecutionFailed(string);
    error DeputyPauseModule_SuperchainNotPaused();
    error DeputyPauseModule_Unauthorized();
    error DeputyPauseModule_NonceAlreadyUsed();

    struct PauseMessage {
        bytes32 nonce;
    }

    struct DeputyAuthMessage {
        address deputy;
    }

    function version() external view returns (string memory);

    function foundationSafe() external view returns (Safe foundationSafe_);

    function deputy() external view returns (address deputy_);

    function pauseMessageTypehash()
        external
        pure
        returns (bytes32 pauseMessageTypehash_);

    function deputyAuthMessageTypehash()
        external
        pure
        returns (bytes32 deputyAuthMessageTypehash_);

    function usedNonces(bytes32) external view returns (bool);

    function pause(bytes32 _nonce, bytes memory _signature) external;
}

//TODO: will be removed once the module is deployed.
contract mockDeputyPauseModule {
    constructor() {}

    function pause(bytes32 _nonce, bytes memory _signature) external pure {
        _nonce;
        _signature;
    }
}

contract SignPauseMessage is Script {
    Safe DeputyGuardian;
    IDeputyPauseModule DeputyPauseModule;
    mockDeputyPauseModule mDPM;

    uint256 privateKey = uint256(vm.envBytes32("PRIVATE_KEY")); //get the privatekey in uint256;
    address signer = vm.addr(privateKey);

    bytes32 internal constant PAUSE_MESSAGE_TYPEHASH =
        keccak256("PauseMessage(bytes32 nonce)");

    /// @notice Typehash for the DeputyAuth message.
    bytes32 internal constant DEPUTY_AUTH_MESSAGE_TYPEHASH =
        keccak256("DeputyAuthMessage(address deputy)");

    /// @notice Struct for the Pause action.
    /// @custom:field nonce Signature nonce.

    struct PauseMessage {
        bytes32 nonce;
    }

    /// @notice Struct for the DeputyAuth action.
    /// @custom:field deputy Address of the deputy account.
    struct DeputyAuthMessage {
        address deputy;
    }

    function setUp() public {
        vm.startBroadcast(privateKey);
        mDPM = new mockDeputyPauseModule();
        vm.stopBroadcast();
    }

    function signAndBrodcast(string memory network) public {
        //TODO: Get from the superchain registry for sepolia the addresses required.
        if (StringUtils.compareStrings(network, "sepolia")) {
            DeputyGuardian = Safe(
                payable(address(0xDEe57160aAfCF04c34C887B5962D0a69676d3C8B))
            );
            DeputyPauseModule = IDeputyPauseModule(address(mDPM)); // need to be replace in the future.
        } else if (StringUtils.compareStrings(network, "mainnet")) {
            DeputyGuardian = Safe(
                payable(address(0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A))
            );
            DeputyPauseModule = IDeputyPauseModule(address(mDPM)); // need to be replace in the future.
        }

        if (address(DeputyGuardian) == address(0)) {
            console.log("DeputyGuardian is not set");
            revert("DeputyGuardian is not set");
        }

        bytes32 nonce = bytes32(DeputyGuardian.nonce());

        // 0. Hash the data with the nonce from the `DeputyGuardianContract`.
        bytes32 structHash = keccak256(
            abi.encode(PAUSE_MESSAGE_TYPEHASH, nonce)
        );

        // Retrieve the private key from the environment variable
        console.log("Signer is:", signer);
        //1. Sign the message
        (uint8 r, bytes32 s, bytes32 v) = vm.sign(
            uint256(privateKey),
            structHash
        );

        // 2. Reconstruction of the signature.
        bytes memory signature = abi.encodePacked(r, s, v);
        console.log("signature is:");
        console.logBytes(signature);

        vm.startBroadcast(uint256(privateKey));
        // 3. Broadcast the transaction to the `DeputyPauseModule` with the signature.
        DeputyPauseModule.pause(nonce, signature); // send the pause transaction to the `DeputyPauseModule`.

        console.log(
            "Broadcasted the pause transaction to",
            address(DeputyPauseModule)
        );

        vm.stopBroadcast();
    }
}
