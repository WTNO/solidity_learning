# 什么是BendDAO
BendDAO 是一种去中心化的非托管 NFT 流动性和借贷协议，用户可以作为存款人或借款人参与其中。存款人向市场提供流动性以赚取被动收入，而借款人则可以使用 NFT 作为抵押品以超额抵押（永久）或无抵押（单块流动性）方式借款。

# <a href="https://github.com/BendDAO/bend-lending-protocol">贷款协议</a>
> 主要合约：LendPoolAddressesProvider 和 LendPoolAddressesProviderRegistry 都控制协议的可升级性，包括储备和 NFT 列表以及协议参数的更改。BEND 持有者将通过 BendDAO 治理控制两者。
## <a href="https://github.com/BendDAO/bend-lending-protocol/blob/main/contracts/protocol/LendPool.sol">1. LendPool（借出池）</a>
LendPool 合约是协议的主合约。它公开了所有可以使用 Solidity 或 web3 库调用的面向用户的操作。

代码学习：
1. Error全部写在一个Errors合约当中，将每个Error约定好一个错误码；
2. 一些通用的成员变量抽象出来，存到一个合约或者接口当中用于继承，如修饰器nonReentrant中用到的_status抽象到了LendPoolStorageExt合约；
3. 继承了ILendPool接口，并且将所有的event定义在接口当中；
4. 合约当中没有定义任何成员变量，全部在继承的LendPoolStorage合约中；
5. 所有逻辑全部写在各种Logic逻辑合约中；
6. 传参采用struct，全部写在DataTypes中。

### 1.1 deposit
将一定数量的基础资产存入储备中，作为回报获得对应的bToken。例如，用户存入100个USDC，获得100个bUSDC。
> 将地址为asset的ERC20代币从msg.sender转移amount个至BToken地址（即存入），BToken mint amountScaled个B代币至onBehalfOf地址（amountScaled = amount.rayDiv(index)）。

| 参数名 | 类型 | 描述 |
| ---- | ---- | ---- |
|asset|address|存入的基础资产的地址。|
|amount|uint256|需要存入的基础资产数量，以基础资产小数单位表示。|
|onBehalfOf|address|接收bToken的地址。当aToken应该发送给调用者时，请使用msg.sender。|
|referralCode|uint16|推荐计划的推荐代码。如果没有推荐，请使用0。|

逻辑代码位置：SupplyLogic.sol
```java
    // 使用OpenZeppelin合约的官方分支contracts-upgradeable，是可升级合约
    IERC20Upgradeable(params.asset).safeTransferFrom(params.initiator, bToken, params.amount);
    IBToken(bToken).mint(params.onBehalfOf, params.amount, reserve.liquidityIndex);
```
### 1.2 withdraw
从储备中提取一定数量的基础资产，销毁所拥有的等量 bTokens。
> 
| 参数名 | 类型 | 描述 |
| ---- | ---- | ---- |
|asset|address|存入的基础资产的地址。|
|amount|uint256|要提取的基础资产数量，以基础资产小数单位表示。|
|to|address|接收基础资产的地址。如果用户想要将其发送到自己的钱包，则与msg.sender相同，如果受益人是不同的钱包，则为不同的地址。|

逻辑代码位置：SupplyLogic.sol
```java
    // 提取资产和销毁bToken两个操作都在BToken中完成
    IBToken(bToken).burn(params.initiator, params.to, amountToWithdraw, reserve.liquidityIndex);
```
> * 从user销毁bToken，并将相应数量的基础资产发送到to地址。
>
> * 从burn方法可以看出每一个基础资产(即ERC20合约)都有相对应的BToken
> 
> * BToken实施了大多数标准的 ERC20 代币方法并稍作修改，以及 Bend 特定方法

### 1.3 borrow
允许用户借出一定数量的储备基础资产。例如，用户借出100个USDC，在其钱包中收到100个USDC，并将抵押资产锁定在合约中。

| 参数名 | 类型 | 描述 |
| ---- | ---- | ---- |
|asset|address|要借入的基础资产的地址。|
|amount|uint256|要借入的基础资产数量，以基础资产小数单位表示。|
|nftAsset|address|用作抵押品的基础NFT的地址。|
|nftTokenId|uint256|用作抵押品的基础NFT的代币ID。|
|onBehalfOf|address|将获得贷款的用户的地址。如果借款人想要根据自己的抵押品借款，则应该是调用该函数的借款人的地址。|
|referralCode|uint16|推荐计划的推荐代码。如果没有推荐，请使用0。|

逻辑代码位置：BorrowLogic.sol
```java
    if (vars.loanId == 0) {
        // 如果资产没抵押过，抵押资产，创建贷款
        IERC721Upgradeable(params.nftAsset).safeTransferFrom(vars.initiator, address(this),   params.nftTokenId);
        vars.loanId = ILendPoolLoan(vars.loanAddress).createLoan(...);
    } else {
        // 如果资产抵押过，更新贷款状态
        ILendPoolLoan(vars.loanAddress).updateLoan(...);
    }

    // 分配债务代币
    IDebtToken(reserveData.debtTokenAddress).mint(...);

    // 根据最新的借贷金额（利用率）更新利率。
    reserveData.updateInterestRates(params.asset, reserveData.bTokenAddress, 0, params.amount);
    // 借出储备基础资产
    IBToken(reserveData.bTokenAddress).transferUnderlyingTo(vars.initiator, params.amount);
```

### 1.4 repay
还清特定储备中的借入金额，销毁相应的贷款，例如，用户还清100个USDC，销毁贷款并收回抵押资产。

| 参数名 | 类型 | 描述 |
| ---- | ---- | ---- |
|nftAsset|address|用作抵押品的基础NFT的地址。|
|nftTokenId|uint256|用作抵押品的基础NFT的代币ID。|
|amount|uint256|要还款的基础资产金额，以基础资产小数单位表示。仅在还款不是代表第三方执行时，使用type（uint256）.max还清整个债务。如果代表另一个用户进行还款，则建议发送略高于当前借入金额的金额。|

逻辑代码位置：BorrowLogic.sol
```java
    vars.repayAmount = vars.borrowAmount;
    vars.isUpdate = false;
    if (params.amount < vars.repayAmount) {
      vars.isUpdate = true;
      vars.repayAmount = params.amount;
    }
    if (vars.isUpdate) {
        // 如果没有全部还清
        ILendPoolLoan(vars.poolLoan).updateLoan(...);
    } else {
        // 如果全部还清
        ILendPoolLoan(vars.poolLoan).repayLoan(...);
    }
    // 销毁债务代币
    IDebtToken(reserveData.debtTokenAddress).burn(loanData.borrower, vars.repayAmount, reserveData.variableBorrowIndex);

    // 根据最新的借贷金额（利用率）更新利率。
    reserveData.updateInterestRates(loanData.reserveAsset, reserveData.bTokenAddress, vars.repayAmount, 0);

    // 将还款金额从msg.sender转移至bToken。
    IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(
      vars.initiator,
      reserveData.bTokenAddress,
      vars.repayAmount
    );

    // 收回抵押资产
    if (!vars.isUpdate) {
      IERC721Upgradeable(loanData.nftAsset).safeTransferFrom(address(this), loanData.borrower, params.nftTokenId);
    }
```
> 从上面两个方法可以看出货币类型的代币采用ERC20，如USDC，NFT类型采用ERC721。

### 1.5 auction
这个函数用于拍卖出于不良状态的抵押物。调用者（清算方）希望购买被清算用户的抵押资产。Bend采用英格兰拍卖机制，最高出价者将获胜。

| 参数名 | 类型 | 描述 |
| ---- | ---- | ---- |
|nftAsset|address|用作抵押品的基础NFT的地址。|
|nftTokenId|uint256|用作抵押品的基础NFT的代币ID。|
|bidPrice|uint256|清算人想要购买基础NFT的出价价格。|
|onBehalfOf|address|将获得基础NFT的用户的地址。如果用户想要将其发送到自己的钱包，则与msg.sender相同，如果NFT的受益人是不同的钱包，则为不同的地址。|

逻辑代码位置：LiquidateLogic.sol
```java
// 计算贷款清算价格
(vars.borrowAmount, vars.thresholdPrice, vars.liquidatePrice) = GenericLogic.calculateLoanLiquidatePrice(...);

// 首次出价需要销毁债务代币并将储备转移至bToken。
// Active状态：贷款已初始化，资金已发放给借款人并抵押品已持有。
if (loanData.state == DataTypes.LoanState.Active) { // 这里的状态判断没看懂
    // 借款的累计债务必须超过阈值（健康因子低于1.0）
    require(vars.borrowAmount > vars.thresholdPrice, Errors.LP_BORROW_NOT_EXCEED_LIQUIDATION_THRESHOLD);
    // 出价必须高于借入债务金额。
    require(params.bidPrice >= vars.borrowAmount, Errors.LPL_BID_PRICE_LESS_THAN_BORROW);
    // 出价必须高于清算价格。
    require(params.bidPrice >= vars.liquidatePrice, Errors.LPL_BID_PRICE_LESS_THAN_LIQUIDATION_PRICE);
} else {
    // 出价必须高于借入债务金额。
    require(params.bidPrice >= vars.borrowAmount, Errors.LPL_BID_PRICE_LESS_THAN_BORROW);

    // 如果暂停持续时间大于0，且拍卖开始时间在暂停开始时间之前
    // 说明拍卖开始后暂停过一段时间，需要设置额外拍卖时间
    if ((poolStates.pauseDurationTime > 0) && (loanData.bidStartTimestamp <= poolStates.pauseStartTime)) {
        vars.extraAuctionDuration = poolStates.pauseDurationTime;
    }
    // 拍卖结束时间=出价开始时间 + 额外拍卖时间 + 配置中的贷款持续时间
    vars.auctionEndTimestamp =
        loanData.bidStartTimestamp +
        vars.extraAuctionDuration +
        (nftData.configuration.getAuctionDuration() * 1 hours);
    // 当前区块时间必须小于拍卖结束时间
    require(block.timestamp <= vars.auctionEndTimestamp, Errors.LPL_BID_AUCTION_DURATION_HAS_END);

    // 出价必须高于最高出价+增量。
    vars.minBidDelta = vars.borrowAmount.percentMul(PercentageMath.ONE_PERCENT);
    require(params.bidPrice >= (loanData.bidPrice + vars.minBidDelta), Errors.LPL_BID_PRICE_LESS_THAN_HIGHEST_PRICE);
}
// 这个方法用于确保贷款状态有效：价格必须高于当前最高价格和贷款必须处于“激活”或“拍卖”状态。
// 此函数里面修改了一系列贷款的状态
ILendPoolLoan(vars.loanAddress).auctionLoan(...);
// 将最高出价者的出价金额锁定到借贷池。
IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(vars.initiator, address(this), params.bidPrice);
// 将最后一次出价的金额从借贷池中退回给上一个出价者。
if (loanData.bidderAddress != address(0)) {
    IERC20Upgradeable(loanData.reserveAsset).safeTransfer(loanData.bidderAddress, loanData.bidPrice);
}
```

### 1.6 redeem
这个函数用于赎回非健康NFT贷款，其状态处于拍卖中。调用者必须是贷款的借款人。借款人可以在赎回时间到期之前赎回自己的东西。

| 参数名 | 类型 | 描述 |
| ---- | ---- | ---- |
|nftAsset|address|用作抵押品的基础NFT的地址。|
|nftTokenId|uint256|用作抵押品的基础NFT的代币ID。|
|amount|uint256|还清债务的金额。|
|bidFine|uint256|出价罚款的金额。（类似于利息？）|

```java
// 如果暂停持续时间大于0，且拍卖开始时间在暂停开始时间之前
// 说明拍卖开始后暂停过一段时间，需要设置额外赎回时间
if ((poolStates.pauseDurationTime > 0) && (loanData.bidStartTimestamp <= poolStates.pauseStartTime)) {
    vars.extraRedeemDuration = poolStates.pauseDurationTime;
}
// 赎回结束时间=出价开始时间 + 额外赎回时间 + 配置中的赎回持续时间
vars.redeemEndTimestamp = (loanData.bidStartTimestamp +
  vars.extraRedeemDuration +
  nftData.configuration.getRedeemDuration() *
  1 hours);
// 当前区块时间必须小于赎回结束时间
require(block.timestamp <= vars.redeemEndTimestamp, Errors.LPL_BID_REDEEM_DURATION_HAS_END);

// 在获取依赖于最新借贷指数的借贷金额之前，必须先更新状态。
reserveData.updateState();

// 计算贷款清算价格
(vars.borrowAmount, , ) = GenericLogic.calculateLoanLiquidatePrice(...);

// 检查出价是否在最小值和最大值范围内
(, vars.bidFine) = GenericLogic.calculateLoanBidFine(...);

// 检查出价是否足够
require(vars.bidFine <= params.bidFine, Errors.LPL_INVALID_BID_FINE);

// 检查最小的偿还债务金额，使用配置中的赎回阈值。
vars.repayAmount = params.amount;
vars.minRepayAmount = vars.borrowAmount.percentMul(nftData.configuration.getRedeemThreshold());
require(vars.repayAmount >= vars.minRepayAmount, Errors.LP_AMOUNT_LESS_THAN_REDEEM_THRESHOLD);

// 检查最大的偿还债务金额，为借款金额的90%
vars.maxRepayAmount = vars.borrowAmount.percentMul(PercentageMath.PERCENTAGE_FACTOR - PercentageMathTEN_PERCENT);
require(vars.repayAmount <= vars.maxRepayAmount, Errors.LP_AMOUNT_GREATER_THAN_MAX_REPAY);

// 此函数要求：1.调用者必须是贷款的持有者；2.贷款必须处于“拍卖”状态。
ILendPoolLoan(vars.poolLoan).redeemLoan(...);

// 销毁债务代币
IDebtToken(reserveData.debtTokenAddress).burn(loanData.borrower, vars.repayAmount, reserveDatavariableBorrowIndex);

// 根据最新的借贷金额（利用率）更新利率。
reserveData.updateInterestRates(loanData.reserveAsset, reserveData.bTokenAddress, vars.repayAmount, 0);

// 将还款金额从借款人转移到bToken。
IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(
  vars.initiator,
  reserveData.bTokenAddress,
  vars.repayAmount
);

if (loanData.bidderAddress != address(0)) {
    // 将最后一次出价的金额从借贷池中退回给出价者
    IERC20Upgradeable(loanData.reserveAsset).safeTransfer(loanData.bidderAddress, loanData.bidPrice);
    // 将出价罚款金额从借款人转移到第一个出价者
    IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(vars.initiator, loanData.firstBidderAddress, vars.bidFine);
}
```

### liquidate
此函数用于清算状态为拍卖的非健康NFT贷款。调用者（清算者）购买被清算用户的抵押资产，并收回抵押资产。

| 参数名 | 类型 | 描述 |
| ---- | ---- | ---- |
|nftAsset|address|用作抵押品的基础NFT的地址。|
|nftTokenId|uint256|用作抵押品的基础NFT的代币ID。|
|amount|uint256|还清债务的额外金额。在大多数情况下应该为0。|

```java
// 省略前面清算时间和清算价格的计算

// 最后的出价价格无法覆盖借款金额
if (loanData.bidPrice < vars.borrowAmount) {
    // 计算额外债务金额
    vars.extraDebtAmount = vars.borrowAmount - loanData.bidPrice;
    // params.amount:用于偿还债务的额外金额。大多数情况下应该为 0
    require(params.amount >= vars.extraDebtAmount, Errors.LP_AMOUNT_LESS_THAN_EXTRA_DEBT);
}

// 如果投标金额大于借款金额
if (loanData.bidPrice > vars.borrowAmount) {
    vars.remainAmount = loanData.bidPrice - vars.borrowAmount;
}

// 此函数要求：1.调用者必须发送本金+利息；2.贷款必须处于active状态。
ILendPoolLoan(vars.poolLoan).liquidateLoan(...);

// 销毁债务代币
IDebtToken(reserveData.debtTokenAddress).burn(
    loanData.borrower,
    vars.borrowAmount,
    reserveData.variableBorrowIndex
);

// 根据最新的借款金额（利用率）更新利率。
reserveData.updateInterestRates(loanData.reserveAsset, reserveData.bTokenAddress, vars.borrowAmount,0);

// 将额外的借款金额从清算人（调用者）转移到借贷池。
if (vars.extraDebtAmount > 0) {
    IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(vars.initiator, address(this),  varsextraDebtAmount);
}
// 从借贷池转移借款金额到bToken，还清债务。
IERC20Upgradeable(loanData.reserveAsset).safeTransfer(reserveData.bTokenAddress, vars.borrowAmount);

// 将剩余金额转移给借款人
if (vars.remainAmount > 0) {
    IERC20Upgradeable(loanData.reserveAsset).safeTransfer(loanData.borrower, vars.remainAmount);
}

// 将ERC721代币转移给竞拍者
IERC721Upgradeable(loanData.nftAsset).safeTransferFrom(address(this), loanData.bidderAddress, paramsnftTokenId);
```
> 关于拍卖auction和清算liquidate两个函数的理解（仅限当前，后面可能会改）：
>
> 1. 在拍卖中，采取的是价高者得，条件是出价必须高于借款金额和清算金额，每轮竞拍加价必须大于1%；
>
> 2. 在清算中，逻辑更加复杂，待学习完LendPoolLoan进一步理解。
>
> 3. 两者联系是拍卖中付完款后只是将loan中的竞拍者bidderAddress改为了最后一个竞拍成功的代表onBehalfOf，并没有将抵押物NFT转移给竞拍者；而清算则是在拍卖结束后来调用此函数进行清算，付款并获取抵押物NFT（可能理解有误，待进一步学习）。

### View Methods
<a href="https://docs.benddao.xyz/developers/lending-protocol/lendpool#view-methods">直接查看文档</a>
<a href="https://github.com/BendDAO/bend-lending-protocol/blob/main/contracts/protocol/LendPool.sol">源码</a>