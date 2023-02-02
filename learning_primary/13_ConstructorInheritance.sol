// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// 部署失败！！！！！！！！！！
// creation of C errored: Error encoding arguments: Error: invalid BigNumber string (argument="value", value="", code=INVALID_ARGUMENT, version=bignumber/5.5.0)
// abstract contract Father {
//     uint public a;

//     constructor(uint _a) {
//         a = _a;
//     }
// }

// // 构造函数的继承
// contract Son is Father {
//     constructor(uint _c) Father(_c * _c) {
        
//     }
// }

// contract C is Father {
//     constructor(uint _c) Father(_c * _c) {}
// }


// 构造函数的继承
abstract contract A {
    uint public a;

    constructor(uint _a) {
        a = _a;
    }
}

contract B is A(1) {
}

contract C is A {
    constructor(uint _c) A(_c * _c) {}
}
