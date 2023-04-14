# <font color="#5395ca">Crowdfund Contracts（众筹合约）</font>
这些合约允许人们创建和参加众筹，将ETH汇集在一起以获得NFT。针对特定的收购模式，存在多个众筹合约。

## <font color="#5395ca">关键概念</font>
* 众筹：实现各种策略的合约，允许人们将ETH汇集在一起以获得NFT，最终目标是围绕它形成一个Party。
* 众筹NFT：代表对众筹所做的贡献的唯一NFT（ERC721）。每个贡献者在首次贡献时都会获得一个。在众筹结束（成功或失败）时，众筹NFT可以被销毁，以赎回未使用的ETH或在新的Party中获取治理NFT。
* Party：治理合约，在众筹获得NFT后将被创建并保管NFT。
* Globals：保存配置值的单个合约，由多个生态合约引用。
代理：所有众筹实例都部署为简单的代理合约，将调用转发到从Crowdfund继承的特定众筹实现。

## <font color="#5395ca">合约预览</font>
在这个阶段涉及的主要合约包括：
* `CrowdfundFactory`
    * 工厂合约，用于部署新的代理众筹实例。
* `Crowdfund`
  * 所有众筹合约的抽象基类。实现大多数众筹的贡献账户和生命周期逻辑。
* `BuyCrowdfund`
  * 众筹以低于最高价格购买特定的NFT（即已知的代币ID）。
* `CollectionBuyCrowdfund`
  * 众筹以低于最高价格从集合中购买任何NFT（即任何代币ID）。类似于BuyCrowdfund，但允许购买集合中的任何代币ID。
* `AuctionCrowdfund`
  * 众筹可以重复竞标特定的NFT（即已知的代币ID），直到拍卖结束。
* `IMarketWrapper`
  * 一个通用接口，供AuctionCrowdfund消费，以抽象出与任何拍卖市场的交互。
* `IGateKeeper`
  * 由门卫合约实现的接口，限制谁可以参与众筹。目前有两个此接口的实现：
* `AllowListGateKeeper`
  * 基于地址是否存在于默克尔树中来限制参与。
* `TokenGateKeeper`
  * 基于地址是否拥有一个代币（ERC20或ERC721）的最低余额来限制参与。
* `Globals`
  * 一个定义全局配置值的合约，其他协议中的合约都会引用它。
  
## <font color="#5395ca">合约说明</font>
### <font color="#5395ca">CrowdfundFactory</font>
CrowdfundFactory合约是创建众筹实例的主要合约。它部署指向特定实现的代理实例，该实现继承自Crowdfund。
### <font color="#5395ca">BuyCrowdfund</font>
BuyCrowdfund通过createBuyCrowdfund()函数创建。（???有点抽象）
* 正在尝试购买特定的ERC721合约+代币ID。
* 在活动期间，用户可以贡献ETH。
* 如果任何人通过buy()成功获取NFT，则成功。
* 如果在获取NFT之前过期，则失败。
### <font color="#5395ca">CrowdfundFactory</font>
### <font color="#5395ca">CrowdfundFactory</font>
### <font color="#5395ca">CrowdfundFactory</font>
### <font color="#5395ca">CrowdfundFactory</font>
### <font color="#5395ca">CrowdfundFactory</font>
### <font color="#5395ca">CrowdfundFactory</font>
### <font color="#5395ca">CrowdfundFactory</font>

