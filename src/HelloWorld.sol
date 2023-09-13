// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract HelloWorld {
    event Hello();

    error Unauthed(address expected, address actual);

    bool public helloed;
    address public allowed;

    constructor(address _allowed) {
        allowed = _allowed;
    }

    function helloWorld() public {
        if (msg.sender != allowed) {
            revert Unauthed(allowed, msg.sender);
        }
        helloed = true;
        emit Hello();
    }
}
