// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract ConstantAndImmutable {
    // constant变量必须在声明的时候初始化，之后不能改变
    uint256 public constant CONSTANT_NUM = 10;
    string public constant CONSTANT_STRING = "0xAA";
    bytes public constant CONSTANT_BYTES = "WTF";
    address public constant CONSTANT_ADDRESS = 0x0000000000000000000000000000000000000000;

    // 编译不通过
    // CONSTANT_NUM = 9;

    // immutable变量可以在声明时或构造函数中初始化，之后不能改变
    uint256 public immutable IMMUTABLE_NUM = 9999999999;
    address public immutable IMMUTABLE_ADDRESS;
    uint256 public immutable IMMUTABLE_BLOCK;
    uint256 public immutable IMMUTABLE_TEST;

    // 利用constructor初始化immutable变量，因此可以利用
    constructor(){
        IMMUTABLE_ADDRESS = address(this);
        IMMUTABLE_BLOCK = block.number;
        IMMUTABLE_TEST = test();
    }

    function test() public pure returns(uint256){
        uint256 what = 9;
        return(what);
    }

    string constant x5 = "hello world";
    address constant x6 = address(0);
    // string immutable x7 = "hello world"; // 报错Immutable variables cannot have a non-value type，咩啊
    address immutable x8 = address(0);
}