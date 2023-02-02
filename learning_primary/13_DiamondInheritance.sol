// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/* 继承树：
  God
 /  \
Adam Eve
 \  /
people
*/

contract God {
    event Log(string message);

    function foo() public virtual {
        emit Log("God.foo called");
    }

    function bar() public virtual {
        emit Log("God.bar called");
    }
}

contract Adam is God {
    function foo() public virtual override {
        emit Log("Adam.foo called");
    }

    function bar() public virtual override {
        emit Log("Adam.bar called");
        super.bar();
    }
}

contract Eve is God {
    function foo() public virtual override {
        emit Log("Eve.foo called");
        Eve.foo();
    }

    function bar() public virtual override {
        emit Log("Eve.bar called");
        super.bar();
    }
}

contract people is Adam, Eve {
    // 这个函数一调用页面就崩了？？？？
    function foo() public override(Eve, Adam) {
        super.foo();
    }
    // 调用合约people中的super.bar()会依次调用Eve、Adam，最后是God合约。
    function bar() public override(Eve, Adam) {
        super.bar();
    }
}