// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * 这章貌似没搞懂
 * 在合约中创建新合约
 * 方法一:create
 * Contract x = new Contract{value: _value}(params)
 * Contract是要创建的合约名，x是合约对象（地址），如果构造函数是payable，
 * 可以创建时转入_value数量的ETH，params是新合约构造函数的参数。
 * 新地址 = hash(创建者地址, nonce)
 * nonce：该地址发送交易的总数,对于合约账户是创建的合约总数,每创建一个合约nonce+1
 */
contract CreateNewContract {
    mapping(address => mapping(address => address)) public getPair; // 通过两个代币地址查Pair地址
    address[] public allPairs; // 保存所有Pair地址
    function createPair(address tokenA, address tokenB) external returns (address pairAddr) {
        // 创建新合约
        Pair pair = new Pair(); 
        // 调用新合约的initialize方法
        pair.initialize(tokenA, tokenB);
        // 更新地址map
        pairAddr = address(pair); // address(合约对象)是啥写法？？
        allPairs.push(pairAddr);
        getPair[tokenA][tokenB] = pairAddr;
        getPair[tokenB][tokenA] = pairAddr;
    }
}

contract Pair{
    address public factory; // 工厂合约地址
    address public token0; // 代币1
    address public token1; // 代币2

    constructor() payable {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }
}