// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// 哈希函数（hash function）是一个密码学概念，它可以将任意长度的消息转换为一个固定长度的值，这个值也称作哈希（hash）
contract Hash {
    function hash(uint _num, string memory _string, address _addr) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_num, _string, _addr));
    }
}