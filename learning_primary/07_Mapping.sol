// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * solidity中的哈希表：映射（Mapping）类型。
 */
contract Mapping {
    mapping(uint => address) public idToAddress; // id映射到地址
    mapping(address => address) public swapPair; // 币对的映射，地址到地址

    // 映射规则
    // 1:映射的KeyType只能是solidity默认的类型，如uint、address等，不能用自定义结构体（可以用数组？）；ValueType可以用自定义结构体
    struct Student {
        uint id;
        string name;
        uint score;
    }
    // mapping(uint[3] => Student) public errorDemo; // 报错
    mapping(bytes => Student) public bytesDemo;
    // mapping(Student => uint) public errorDemo;
    mapping(uint => Student) public correctDemo;

    // 2:映射的存储位置必须是storage，因此可以用于合约的状态变量和library函数的参数（？）;
    //   不能用于 public 函数的参数或返回结果中

    // 3:如果映射声明为public，会自动创建getter函数
    function getterTest() public {
        // correctDemo.get(1); // getter咋写
    }

    // 4:给映射新增的键值对的语法为_Var[_Key] = _Value
    function writeMap (uint _Key, address _Value) public{ // 参数必须是memory或calldata
        idToAddress[_Key] = _Value;
    }

    mapping(string => Student) public balanceOf;
}