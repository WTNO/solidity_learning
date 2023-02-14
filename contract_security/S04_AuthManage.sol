// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AuthManage is ERC20, Ownable {
    constructor() ERC20("Wrong Access", "WA") {}

    // 错误的mint函数，没有限制权限
    function badMint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    // 错误的mint函数，没有限制权限
    function badBurn(address account, uint256 amount) public {
        _burn(account, amount);
    }

    // 正确的mint函数，使用 onlyOwner 修饰器限制权限
    function goodMint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // 正确的burn函数，如果销毁的不是自己的代币，则会检查授权
    function goodBurn(address account, uint256 amount) public {
        if (msg.sender != account) {
            _spendAllowance(account, msg.sender, amount);
        }
        _burn(account, amount);
    }
}
