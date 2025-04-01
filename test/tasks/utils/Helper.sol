// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

/// @notice This function is used to replace the Multicall3NoValueCheck address in the deployed bytecode
/// with the address of the old multicall3 address ca11bde05977b3631167028862be2a173976ca11.
function replaceMulticallBytecode(bytes memory deployedBytecode) pure returns (bytes memory) {
    address VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
    Vm vm = Vm(VM_ADDRESS);

    string memory deployedBytecodeString = vm.toString(deployedBytecode);
    deployedBytecodeString = vm.replace(
        deployedBytecodeString, "90664a63412b9b07bbfbeacfe06c1ea5a855014c", "ca11bde05977b3631167028862be2a173976ca11"
    );
    deployedBytecode = vm.parseBytes(deployedBytecodeString);
    return deployedBytecode;
}
