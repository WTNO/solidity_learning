// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract DataStorage {
    uint[] x = [1, 2, 3];

    function callData(uint256[] calldata _number) public pure returns(uint256[] calldata) {
        // 这里没懂
        return(_number);
    }

    // storage（合约的状态变量）赋值给本地storage（函数里的）时候，会创建引用，改变新变量会影响原变量。
    function storageTest() public {
        // 相当于Java的值传递
        uint[] storage xStorage = x;
        xStorage[0] = 100;
    }

    // storage赋值给memory，会创建独立的副本，修改其中一个不会影响另一个；反之亦然。
    // 自动报错要限制为view
    // 没搞懂怎么debug
    function memoryTest() public view {
        uint[] memory xMemory = x;
        xMemory[0] = 101;
        xMemory[1] = 102;
        xMemory[2] = 103;
        uint[] memory xMemory_ = x;
        xMemory_[0] = 1000;
    }

    function globalVariable() public view returns(address, uint, bytes memory){
        address sender = msg.sender; // 请求发起地址
        uint blockNum = block.number; // 当前区块高度
        bytes memory data = msg.data; // 请求数据
        return(sender, blockNum, data);
    }
}