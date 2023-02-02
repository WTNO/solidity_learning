// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract ConstructorAndModifier {
    address public  owner;
    // 构造函数：是一种特殊的函数，每个合约可以定义一个，并在《《部署合约的时候》》自动运行一次。
    // 在Solidity 0.4.22之前，构造函数不使用 constructor 而是使用与合约名同名的函数作为构造函数而使用
    constructor() {
        owner = msg.sender;
    }

    // 修饰器modifier：是solidity的特有语法（类似装饰器模式？）
    // 定义modifier
    modifier onlyOwner {
        require(msg.sender == owner); // 检查调用者是否为owner地址
        _; // 如果是的话，继续运行函数主体；否则报错并revert交易
    }

    // 带有onlyOwner(上面定义的修饰器)修饰符的函数只能被owner地址调用
    // 由于onlyOwner修饰符的存在，只有原先的owner可以调用，别人调用就会报错。这也是最常用的控制智能合约权限的方法。
    function changeOwner(address _newOwner) external onlyOwner{
      owner = _newOwner; // 只有owner地址运行这个函数，并改变owner
   }

}