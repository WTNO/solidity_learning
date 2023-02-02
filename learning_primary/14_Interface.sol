// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface animal {
    event Log(string message);
    function call() external;
    function walk() external;
}

// 抽象合约实现接口所有函数必须实现
abstract contract dog is animal{
    function call() public virtual override; // 可以有没实现的抽象函数,但是继承接口的合约必须实现接口定义的所有功能

    // function call() external virtual override {
    //     emit Log("dog wangwangwang"); //不能用中文？？？
    // }

    function walk() public virtual override{
        emit Log("dog walking");
    }
}

// 继承名单不需要写interface
contract jinmao is dog {
    function call() public override {
        emit Log("jinmao wangwangwang");
    }

    function walk() public override{
        dog.walk();
        emit Log("jimao running");
    }
}

// abstract contract A{ function foo(uint a) public view returns(uint); }
// contract A{ function foo(uint a) internal returns(uint); }
// abstract contract A{ function foo(uint a) internal pure virtual returns(uint); }
// contract A{ function foo(uint a) external pure virtual returns(uint); }