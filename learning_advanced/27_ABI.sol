// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * 应用二进制接口(Application Binary Interface)是与以太坊智能合约交互的标准
 * 编码有四个函数
 * 1.abi.encode
 * 2.abi.encodePacked
 * 3.abi.encodeWithSignature
 * 4.abi.encodeWithSelector
 *
 * 解码有一个函数：abi.decode
 */
contract ABI {
    uint x = 10;
    address addr = 0x7A58c0Be72BE218B41C608b7Fe7C5bB630736C71;
    string name = "0xAA";
    uint[2] array = [5, 6];

    // abi.encode会将每个数据都填充为32字节
    // 适用于和合约交互
    function abiEncode() external view returns(bytes memory result) {
        result = abi.encode(x, addr, name, array);
    }

    // abi.encodePacked将给定参数根据其所需最低空间编码，类似 abi.encode，但是会把其中填充的很多0省略
    // 适用于想省空间，并且不与合约交互的时候，如算一些数据的hash时(例如前面的计算salt)
    function abiEncodePacked() external view returns(bytes memory result) {
        result = abi.encodePacked(x, addr, name, array);
    }

    // abi.encodeWithSignature和abi.encode类似，区别在于第一个参数为函数签名
    // 等同于在abi.encode编码结果前加上了4字节的函数选择器
    // 适用于调用其他合约的时候
    function abiEncodeWithSignature() external view returns(bytes memory result) {
        result = abi.encodeWithSignature("mint(uint256)", x, addr, name, array);
    }

    // encodeWithSelector和abi.encodeWithSignature类似，区别在于第一个参数为函数选择器，为函数签名Keccak哈希的前4个字节。
    // 适用于调用其他合约的时候
    function abiEncodeWithSelector() external view returns(bytes memory result) {
        result = abi.encodeWithSelector(bytes4(keccak256("mint(uint256)")), x, addr, name, array);
    }

    // abi解码
    function decode(bytes memory data) public pure returns(uint _x, address _addr, string memory _name, uint[2] memory _array) {
        (_x, _addr, _name, _array) = abi.decode(data, (uint, address, string, uint[2]));
    }

    // 解码abiEncodeWithSelector生成的编码失败
    function decode2(bytes memory data) public pure returns(string memory method, uint _x, address _addr, string memory _name, uint[2] memory _array) {
        (method, _x, _addr, _name, _array) = abi.decode(data, (string, uint, address, string, uint[2]));
    }
}