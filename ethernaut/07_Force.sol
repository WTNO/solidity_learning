// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Force {
    /*

                   MEOW ?
         /\_/\   /
    ____/ o o \
  /~____  =ø= /
 (______)__m_m)

*/
}

contract Delete {
    // 通过自毁函数删除合约，并将合约余额发送到指定地址
    function deleteContract(address force) public {
        selfdestruct(payable(force));
    }

    receive() external payable {

    }
}
