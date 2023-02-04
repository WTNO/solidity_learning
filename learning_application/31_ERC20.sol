// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./31_IERC20.sol";

contract ERC20 is IERC20 {
    // 下面三个状态变量为public类型，会自动生成一个同名getter函数，实现IERC20规定的balanceOf(), allowance()和totalSupply()。
    // 用override修饰public变量，会重写继承自父合约的与变量同名的getter函数，
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;
    uint256 public override totalSupply;

    // 名次
    string public name;
    // 代号
    string public symbol;
    // 小数位数
    uint256 public decimals = 18; // 小数位

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function transfer(address to, uint256 value) external override returns(bool) {
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external override returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * 授权转账逻辑:被授权方将授权方sender的amount数量的代币转账给接收方recipient
     */
    function transferFrom(address from, address to, uint256 value) external override returns(bool) {
        // 获取被授权方的授权数额
        uint256 approvalNum = allowance[from][msg.sender];
        // if (approvalNum < value) {
        //     return false;
        // }
        require(approvalNum >= value, "allowance not enough");
        allowance[from][msg.sender] -= value; // 不是应该是 allowance[授权方][被授权方] 吗？
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        return true;
    }
    
    /**
     * 铸造代币函数，不在IERC20标准中。任何人可以铸造任意数量的代币，实际应用中会加权限管理，只有owner可以铸造代币：
     */
    function mint(uint amount) external {
        // require(msg.sender == owner, "YOU DON'T HAVE PERMISSION TO ACCESS");
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    /**
     * 销毁代币函数，不在IERC20标准中
     */
    function burn(uint amount) external {
        // require(msg.sender == owner, "YOU DON'T HAVE PERMISSION TO ACCESS");
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}