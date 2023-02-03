// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * selfdestruct命令可以用来删除智能合约，并将该合约剩余ETH转到指定地址。
 * 是为了应对合约出错的极端情况而设计的
 * 使用方法：selfdestruct(接收合约中剩余ETH的地址);
 */
contract SelfdestructTest {
    address public  owner;
    constructor() payable {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner); // 检查调用者是否为owner地址
        _; // 如果是的话，继续运行函数主体；否则报错并revert交易
    }

    receive() payable external {}

    function deleteContract() public onlyOwner {
        selfdestruct(payable(msg.sender));
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
}