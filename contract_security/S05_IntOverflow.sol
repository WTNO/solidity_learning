// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// 复现整形溢出漏洞
// 0.8.0 版本之后会自动检查整型溢出错误，溢出时会报错
// 使用 unchecked 关键字，在代码块中临时关掉溢出检查
// 解决办法：Solidity 0.8.0 之前的版本，在合约中引用 Safemath 库，在整型溢出时报错。
contract IntOverflow {
    mapping(address => uint256) balances;
    uint256 public totalSupply;

    constructor(uint256 _initialSupply) {
        balances[msg.sender] = totalSupply = _initialSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        unchecked {
            require(balances[msg.sender] - _value >= 0);
            balances[msg.sender] -= _value;
            balances[_to] += _value;
        }
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}
