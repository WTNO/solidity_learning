// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// 已知 合约代码（或接口） 和 地址 情况下调用目标合约的函数
contract CallOtherContract {
    /**
     * 方法一：传入目标合约地址，生成目标合约的引用
     */
    function callGetBalance(address payable _address) public view returns(uint) {
        return OtherContract(_address).getBalance();
    }

    /**
     * 方法二：传入合约的引用，只需要把上面参数的address类型改为目标合约名
     */
    function callSetX(OtherContract _address, uint256 _x) external {
        _address.setX(_x);
    }

    /**
     * 方法三：创建合约变量
     */
    function callGetX(address payable _address) public view returns(uint) {
        OtherContract oc = OtherContract(_address);
        // IOtherContract ioc = IOtherContract(_address); // 是警告不是报错！！！坑死人！
        return oc.getX();
    }

    /**
     * 方法四：当目标合约的函数是payable，可以通过调用它来给合约转账_Name(_Address).f{value: _Value}()
     */
    function callAndSendEth(address payable _address, uint256 _x) payable public {
        OtherContract(_address).setX{value: msg.value}(_x);
    }
}

interface IOtherContract {
    function getBalance() external returns(uint);
    function setX(uint256 x) external payable;
    function getX() external view returns(uint x);
}

contract OtherContract is IOtherContract {
    uint256 private _x = 0; // 状态变量_x
    // 收到eth的事件，记录amount和gas
    event Log(uint amount, uint gas);

    fallback() external payable{}
    receive() external payable{}
    
    // 返回合约ETH余额
    function getBalance() view public override returns(uint) {
        return address(this).balance;
    }

    // 可以调整状态变量_x的函数，并且可以往合约转ETH (payable)
    function setX(uint256 x) external override payable{
        _x = x;
        // 如果转入ETH，则释放Log事件
        if(msg.value > 0){
            emit Log(msg.value, gasleft());
        }
    }

    // 读取_x
    function getX() external view override returns(uint x){
        x = _x;
    }
}