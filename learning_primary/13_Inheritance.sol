// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract Grandpa {
    event Log(string msg);

    // virtual: 父合约中的函数，如果希望子合约重写，需要加上virtual关键字。
    // 定义3个function: hip(), pop(), man()，Log值为Yeye。
    function hip() public virtual{
        emit Log("Yeye");
    }

    function pop() public virtual{
        emit Log("Yeye");
    }

    function yeye() public virtual {
        emit Log("Yeye");
    }
}

contract Father is Grandpa{
    // override：子合约重写了父合约中的函数，需要加上override关键字。
    // override 和 virtual可以同时用
    // 继承两个function: hip()和pop()，输出改为Baba。
    function hip() public virtual override{
        emit Log("Baba");
    }

    // function pop() public virtual override{
    //     emit Log("Baba");
    // }

    function baba() public virtual{
        emit Log("Baba");
    }
}

/**
 * 多重继承
 * solidity的合约可以继承多个合约。
 * 1.继承时要按辈分最高到最低的顺序排。比如我们写一个Erzi合约，继承Yeye合约和Baba合约，那么就要写成contract Erzi is Yeye, Baba，
 *   而不能写成contract Erzi is Baba, Yeye，不然就会报错。
 * 2.如果某一个函数在多个继承的合约里都存在，比如例子中的hip()和pop()，在子合约里必须重写，不然会报错。
 * 3.重写在多个父合约中都重名的函数时，override关键字后面要加上所有父合约名字，例如override(Yeye, Baba)。
 */
 contract Son is Grandpa, Father{
    // 继承两个function: hip()和pop()，输出值为Erzi。
    function hip() public virtual override(Grandpa, Father){
        emit Log("Erzi");
    }

    function pop() public virtual override {
        emit Log("Erzi");
    }

    function callParent() public {
        Grandpa.hip(); // 通过父合约名.函数名()的方式来调用父合约函数
        super.hip(); // 通过super.函数名()来调用最近的父合约函数(最右边)
    }
}