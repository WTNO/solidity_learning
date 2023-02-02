// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract Function_Return {
    // 返回多个变量
    function returnMultiple() public pure returns(uint256, bool, uint256[3] memory) {
        return (1, true, [uint256(5), 2, 4]);
    }

    // 命名式返回
    function returnNamed_1() public pure returns(uint256 _number, bool _bool, uint256[3] memory _array) {
        _number = 5;
        _bool = 1 > 1;
        _array = [uint256(5), 2, 4];
    }

    // 命名式返回,也可以使用return返回变量
    function returnNamed_2() public pure returns(uint256 _number, bool _bool, uint256[3] memory _array) {
        return (1, true, [uint256(5), 2, 4]);
    }

    // 读取返回值，解构式赋值
    function readReturn() public pure {
        // 读取全部返回值
        uint256 _number;
        bool _bool;
        uint256[3] memory _array;
        // 调用上面的命名式返回
        (_number, _bool, _array) = returnNamed_1();

        // 解构式赋值可以读取部分返回值，不读取的留空
        (, _bool,) = returnNamed_2();
    }

}