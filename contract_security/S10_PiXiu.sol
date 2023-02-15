// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PiXiu is ERC20, Ownable {
    address public pair;

    // 构造函数：初始化代币名称和代号
    constructor() ERC20("HoneyPot", "Pi Xiu") {
        // goerli uniswap v2 factory
        address factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        // 貔貅代币地址
        address tokenA = address(this);
        //  goerli WETH
        address tokenB = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
        //将tokenA和tokenB按大小排序
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        // 用tokenA和tokenB地址计算salt
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        // 计算合约地址方法 hash()
        // abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(type(Pair).creationCode))
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(hex"ff", factory, salt, hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f")
                    )
                )
            )
        );
    }

    /**
     * 铸造函数，只有合约所有者可以调用
     */
    function mint(address to, uint amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     * 貔貅函数：只有合约拥有者可以卖出
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        // 当转账的目标地址为 LP 时，会revert
        if(to == pair){
            require(from == owner(), "Can not Transfer");
        }
    }
}
