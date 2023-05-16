# 编写可升级合约
在使用OpenZeppelin Upgrades处理可升级合约时，编写Solidity代码时需要注意一些小细节。

值得一提的是，这些限制源于以太坊虚拟机的工作方式，并适用于所有使用可升级合约的项目，而不仅仅是OpenZeppelin Upgrades。

## 初始化函数
使用OpenZeppelin Upgrades处理Solidity合约时，除了构造函数之外，您可以无需进行任何修改。由于基于代理的可升级性系统的要求，可升级合约中不能使用构造函数。要了解此限制背后的原因，请转到代理。

这意味着，在使用OpenZeppelin Upgrades处理合约时，您需要将其构造函数更改为常规函数，通常命名为initialize，在其中运行所有设置逻辑：
```java
// NOTE: Do not use this code snippet, it's incomplete and has a critical vulnerability!

pragma solidity ^0.6.0;

contract MyContract {
    uint256 public x;

    function initialize(uint256 _x) public {
        x = _x;
    }
}
```

然而，虽然Solidity确保构造函数在合约的生命周期中仅被调用一次，但常规函数可以被多次调用。为了防止合约被多次初始化，您需要添加一个检查，以确保initialize函数仅被调用一次：

```java
// contracts/MyContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract MyContract {
    uint256 public x;
    bool private initialized;

    function initialize(uint256 _x) public {
        require(!initialized, "Contract instance has already been initialized");
        initialized = true;
        x = _x;
    }
}
```

由于在编写可升级合约时，这种模式非常常见，OpenZeppelin Contracts提供了一个Initializable基础合约，该合约具有一个initializer修饰符，以处理这个问题：

```java
// contracts/MyContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MyContract is Initializable {
    uint256 public x;

    function initialize(uint256 _x) public initializer {
        x = _x;
    }
}
```

构造函数和常规函数之间的另一个区别是，Solidity会自动调用合约所有祖先的构造函数。当编写初始化函数时，您需要特别注意手动调用所有父合约的初始化函数。请注意，即使使用继承，initializer修饰符也只能被调用一次，因此父合约应该使用onlyInitializing修饰符：

```java
// contracts/MyContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract BaseContract is Initializable {
    uint256 public y;

    function initialize() public onlyInitializing {
        y = 42;
    }
}

contract MyContract is BaseContract {
    uint256 public x;

    function initialize(uint256 _x) public initializer {
        BaseContract.initialize(); // Do not forget this call!
        x = _x;
    }
}
```


## 使用可升级智能合约库
请记住，此限制不仅影响您的合约，还影响您从库中导入的合约。例如，考虑OpenZeppelin Contracts的ERC20：该合约在其构造函数中初始化代币的名称和符号。
```java
// @openzeppelin/contracts/token/ERC20/ERC20.sol
pragma solidity ^0.8.0;

...

contract ERC20 is Context, IERC20 {

    ...

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    ...
}
```

这意味着您不应该在OpenZeppelin Upgrades项目中使用这些合约。相反，请确保使用@openzeppelin/contracts-upgradeable，它是OpenZeppelin Contracts的官方分支，已经修改为使用初始化函数而不是构造函数。看看@openzeppelin/contracts-upgradeable中的ERC20Upgradeable是什么样子的：

```java
// @openzeppelin/contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol
pragma solidity ^0.8.0;

...

contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    ...

    string private _name;
    string private _symbol;

    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    ...
}
```

无论是使用OpenZeppelin Contracts还是其他智能合约库，都要确保该包已设置为处理可升级合约。

在Contracts：Using with Upgrades中了解更多关于OpenZeppelin Contracts Upgradeable的信息。

## 避免在字段声明中定义初始值
Solidity允许在合约中声明字段时为其定义初始值。

```java
contract MyContract {
    uint256 public hasInitialValue = 42; // equivalent to setting in the constructor
}
```

这相当于在构造函数中设置这些值，并因此不适用于可升级合约。请确保所有初始值都在初始化函数中设置，如下所示；否则，任何可升级实例都不会设置这些字段。

```java
contract MyContract is Initializable {
    uint256 public hasInitialValue;

    function initialize() public initializer {
        hasInitialValue = 42; // set initial value in initializer
    }
}
```
>NOTE
>
>仍然可以定义常量状态变量，因为编译器不会为这些变量保留存储槽，并且每个出现都会被相应的常量表达式替换。因此，以下内容仍适用于OpenZeppelin Upgrades：

```java
contract MyContract {
    uint256 public constant hasInitialValue = 42; // define as constant
}
```

## 初始化实现合约

不要让实现合约未初始化。未初始化的实现合约可能会被攻击者接管，这可能会影响代理。为了防止实现合约被使用，您应该在构造函数中调用_disableInitializers函数，以便在部署时自动锁定它：

```java
/// @custom:oz-upgrades-unsafe-allow constructor
constructor() {
    _disableInitializers();
}
```

# 从您的合约代码创建新实例

当从您的合约代码创建合约的新实例时，这些创建直接由Solidity处理，而不是由OpenZeppelin Upgrades处理，这意味着这些合约将无法进行升级。

例如，在下面的示例中，即使MyContract被部署为可升级，创建的代币合约也不是可升级的：

```java
// contracts/MyContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyContract is Initializable {
    ERC20 public token;

    function initialize() public initializer {
        token = new ERC20("Test", "TST"); // This contract will not be upgradeable
    }
}
```

如果您希望ERC20实例可以升级，最简单的方法是接受该合约的实例作为参数，并在创建后注入它：

```java
// contracts/MyContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract MyContract is Initializable {
    IERC20Upgradeable public token;

    function initialize(IERC20Upgradeable _token) public initializer {
        token = _token;
    }
}
```

# 潜在的不安全操作

在使用可升级智能合约时，您将始终与合约实例进行交互，而不是与底层逻辑合约进行交互。然而，没有任何防止恶意行为者直接向逻辑合约发送交易的措施。尽管如此，这并不构成威胁，因为逻辑合约状态的任何更改都不会影响您的合约实例，因为逻辑合约的存储在您的项目中从未被使用。

然而，有一个例外。如果对逻辑合约的直接调用触发了selfdestruct操作，则逻辑合约将被销毁，您的所有合约实例将最终将所有调用委托给一个没有任何代码的地址。这将有效地破坏您项目中的所有合约实例。

如果逻辑合约包含delegatecall操作，则可以实现类似的效果。如果可以使合约委托调用到一个包含selfdestruct的恶意合约中，则调用合约将被销毁。

因此，在您的合约中不允许使用selfdestruct或delegatecall。

# 修改您的合约

在编写新版本的合约时，无论是由于新功能还是修复错误，还有一个额外的限制需要遵守：您不能更改合约状态变量声明的顺序或类型。您可以通过了解我们的代理来更多地了解这种限制背后的原因。

>WARNING
>违反这些存储布局限制将导致升级后的合约存储值混乱，可能会在您的应用程序中导致关键错误。

这意味着如果您有一个初始合约，看起来像这样：
```java
contract MyContract {
    uint256 private x;
    string private y;
}
```

那么您不能更改变量的类型：
```java
contract MyContract {
    string private x;
    string private y;
}
```

或更改它们声明的顺序：
```java
contract MyContract {
    string private y;
    uint256 private x;
}
```

或在现有变量之前引入一个新变量：
```java
contract MyContract {
    bytes private a;
    uint256 private x;
    string private y;
}
```

或删除一个现有变量：
```java
contract MyContract {
    string private y;
}
```

如果您需要引入一个新变量，请确保始终将其放在最后：
```java
contract MyContract {
    uint256 private x;
    string private y;
    bytes private z;
}
```

请记住，如果您重命名一个变量，那么在升级后它将保持与之前相同的值。如果新变量在语义上与旧变量相同，则可能是期望的行为：
```java
contract MyContract {
    uint256 private x;
    string private z; // starts with the value from `y`
}
```

如果从合约的末尾删除一个变量，请注意，存储将不会被清除。随后的更新添加新变量将导致该变量读取已删除变量的剩余值。
```java
contract MyContract {
    uint256 private x;
}
```

然后升级为：
```java
contract MyContract {
    uint256 private x;
    string private z; // starts with the value from `y`
}
```

请注意，通过更改合约的父合约，您可能会无意中更改合约的存储变量。例如，如果您有以下合约：
```java
contract A {
    uint256 a;
}


contract B {
    uint256 b;
}


contract MyContract is A, B {}
```


那么通过交换声明基础合约的顺序或引入新的基础合约来修改MyContract，将改变变量实际存储的方式：
```java
contract MyContract is B, A {}
```

如果子合约有自己的变量，则还不能向基础合约添加新变量。假设有以下情况：
```java
contract Base {
    uint256 base1;
}


contract Child is Base {
    uint256 child;
}
```

如果Base被修改以添加额外的变量：
```java
contract Base {
    uint256 base1;
    uint256 base2;
}
```
那么变量base2将被分配到子合约在之前版本中所占用的插槽。解决此问题的方法是在您可能希望在未来扩展的基础合约中声明未使用的变量或存储间隔，作为“保留”这些插槽的手段。请注意，此技巧不涉及增加gas使用量。

# 存储空隙
存储空隙是一种约定，用于在基础合约中保留存储槽，允许该合约的未来版本使用这些槽，而不会影响子合约的存储布局。

要创建存储空隙，请在基础合约中声明一个固定大小的数组，并指定初始槽数。可以使用uint256数组，以便每个元素都保留32字节的槽。将数组命名为__gap或以__gap_开头的名称，以便OpenZeppelin Upgrades可以识别该空隙。
```java
contract Base {
    uint256 base1;
    uint256[49] __gap;
}

contract Child is Base {
    uint256 child;
}
```

如果后续修改了Base以添加额外的变量，则应从存储空隙中减少相应的槽数，考虑到Solidity如何打包连续项的规则。例如：
```java
contract Base {
    uint256 base1;
    uint256 base2; // 32 bytes
    uint256[48] __gap;
}
```

或：
```java
contract Base {
    uint256 base1;
    address base2; // 20 bytes
    uint256[48] __gap; // array always starts at a new slot
}
```

或：
```java
contract Base {
    uint256 base1;
    uint128 base2a; // 16 bytes
    uint128 base2b; // 16 bytes - continues from the same slot as above
    uint256[48] __gap;
}
```
为了确定新版本合约中适当的存储空隙大小，您可以尝试使用upgradeProxy进行升级，或者只需使用validateUpgrade运行验证（请参阅Hardhat或Truffle的文档）。如果存储空隙没有正确地被减少，您将看到一个错误消息，指示存储空隙的预期大小。