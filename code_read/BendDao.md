# 什么是BendDAO
BendDAO 是一种去中心化的非托管 NFT 流动性和借贷协议，用户可以作为存款人或借款人参与其中。存款人向市场提供流动性以赚取被动收入，而借款人则可以使用 NFT 作为抵押品以超额抵押（永久）或无抵押（单块流动性）方式借款。

# <a href="https://github.com/BendDAO/bend-lending-protocol">贷款协议</a>
> 主要合约：LendPoolAddressesProvider 和 LendPoolAddressesProviderRegistry 都控制协议的可升级性，包括储备和 NFT 列表以及协议参数的更改。BEND 持有者将通过 BendDAO 治理控制两者。
## <a href="https://github.com/BendDAO/bend-lending-protocol/blob/main/contracts/protocol/LendPool.sol">LendPool（借出池）</a>
LendPool 合约是协议的主合约。它公开了所有可以使用 Solidity 或 web3 库调用的面向用户的操作。

代码学习：
1. Error全部写在一个Errors合约当中，将每个Error约定好一个错误码；
2. 一些通用的成员变量抽象出来，存到一个合约或者接口当中用于继承，如修饰器nonReentrant中用到的_status抽象到了LendPoolStorageExt合约；
3. 继承了ILendPool接口，并且将所有的event定义在接口当中；
4. 合约当中没有定义任何成员变量，全部在继承的LendPoolStorage合约中；
5. 所有逻辑全部写在各种Logic逻辑合约中；
6. 传参采用struct，全部写在DataTypes中。

### deposit
将一定数量的标的资产存入储备，作为回报获得覆盖的bTokens。 例如，用户存入 100 USDC 并获得 100 bUSDC的回报。
```java
    // 使用OpenZeppelin合约的官方分支contracts-upgradeable，是可升级合约
    IERC20Upgradeable(params.asset).safeTransferFrom(params.initiator, bToken, params.amount);
    IBToken(bToken).mint(params.onBehalfOf, params.amount, reserve.liquidityIndex);
```
### withdraw
从储备中提取一定数量的基础资产，销毁所拥有的等量 bTokens。
```java
    // 提取资产和销毁bToken两个操作都在BToken中完成
    IBToken(bToken).burn(params.initiator, params.to, amountToWithdraw, reserve.liquidityIndex);
```
> BToken实施了大多数标准的 ERC20 代币方法并稍作修改，以及 Bend 特定方法




## <a href="https://github.com/BendDAO/bend-lending-protocol/blob/main/contracts/protocol/LendPoolLoan.sol">LendPoolLoan（借出池贷款）</a>
## <a href="https://github.com/BendDAO/bend-lending-protocol/blob/main/contracts/protocol/LendPoolAddressesProvider.sol">LendPoolAddressesProvider（借出池地址提供者）</a>
## <a href="https://github.com/BendDAO/bend-lending-protocol/blob/main/contracts/protocol/LendPoolAddressesProviderRegistry.sol">LendPoolAddressesProviderRegistry（借出池地址提供商注册表）</a>
## <a href="https://github.com/BendDAO/bend-lending-protocol/blob/main/contracts/protocol/BToken.sol">BTokens</a>
## <a href="https://github.com/BendDAO/bend-lending-protocol/blob/main/contracts/protocol/DebtToken.sol">debtTokens（债务代币）</a>
## <a href="">boundNFTs</a>
<br>

# <a href="https://github.com/BendDAO/bend-lending-protocol">交换协议</a>