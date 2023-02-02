// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * 函数可以重载，修饰器不可以重载
 */
contract Overload {
    function saySomething() public pure returns(string memory){
        return("Nothing");
    }

    function saySomething(string memory something) public pure returns(string memory){
        return(something);
    }

    function f(uint8 _in) public pure returns (uint8 out) {
        out = _in * 2;
    }

    function f(uint256 _in) public pure returns (uint256 out) {
        out = _in;
    }

    // 返回函数签名（来自29章）
    function uint8Selector() external pure returns(bytes4 mSelector){
        return bytes4(keccak256("f(uint8)"));
    }

    function uint256Selector() external pure returns(bytes4 mSelector){
        return bytes4(keccak256("f(uint256)"));
    }

    // 返回值不同不可以重载
    // function f(uint256 _in) public pure returns (uint8 out) {
    //     return uint8(50);
    // }

    // 调用f(50)，因为50既可以被转换为uint8，也可以被转换为uint256，因此会报错。
    // 编译报错
    function test() public pure {
        // f(50);
    }
}