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
BuyCrowdfund通过CrowdfundFactory合约中的createBuyCrowdfund()函数创建。主要参数如下：
* `IERC721 nftContract`：被购买NFT的ERC721合约。
* `uint256 nftTokenId`：被购买NFT的ID。
* `uint40 duration`：众筹竞标该NFT的时间长度，以秒为单位。
* `uint96 maximumPrice`：该众筹最多愿意支付的ETH数量。如果为零，则没有最大值。
* `bool onlyHostCanBuy`：如果为true，则只有主办方可以调用buy()。

主要逻辑：
* 旨在购买特定的ERC721合约+代币ID(指定NFT，在前端界面可以指定一个或者一组NFT)。
* 在活动期间，用户可以贡献ETH。
* 如果任何人通过buy()执行带有价值的任意调用成功获取NFT，则成功。
* 如果在获取NFT之前到期时间过去，则失败。
### <font color="#5395ca">CollectionBuyCrowdfund</font>
CollectionBuyCrowdfund是通过CrowdfundFactory合约中的createCollectionBuyCrowdfund()函数创建，主要参数如下：
* `IERC721 nftContract`：正在购买的NFT的ERC721合同。
* `uint40 duration`：此众筹有多长时间竞标NFT，以秒为单位。
* `uint96 maximumPrice`：此众筹将为NFT支付的最大ETH金额。如果为零，则没有最大值。

主要逻辑：
* 试图在ERC721合同上购买集合中的任意代币。（目前不知道是不是只能买一个）
* 在活动期间，用户可以贡献ETH。
* 如果主机通过buy（）执行具有价值的任意调用成功获取符合条件的NFT，则成功。
* 如果在获取符合条件的NFT之前过期时间过去，则失败。

### <font color="#5395ca">AuctionCrowdfund</font>
AuctionCrowdfund一种可以重复竞标特定NFT（即已知token ID）的拍卖众筹，直到获胜为止。通过CrowdfundFactory合约中的createAuctionCrowdfund()函数创建的，主要参数如下：
* `uint256 auctionId`：IMarketWrapper实例特定的拍卖ID。
* `IMarketWrapper market`：拍卖协议包装合同。
* `IERC721 nftContract`：正在购买的NFT的ERC721合同。
* `uint256 nftTokenId`：正在购买的NFT的ID。
* `uint40 duration`：此众筹有多长时间竞标NFT，以秒为单位。
* `uint96 maximumBid`：此众筹将对NFT进行的最大ETH出价。
* `bool onlyHostCanBid`：如果为真，则只有主机可以调用bid（）。

主要逻辑是：
* 试图在拍卖市场上购买特定的ERC721合同和特定的token ID。
* 直接与Market Wrapper交互，Market Wrapper是NFT拍卖协议的抽象/包装。
* 这些Market Wrappers继承自协议的v1版本，并且实际上是通过delegatecall调用的。
* 在活动期间，用户可以贡献ETH。
* 在活动期间，任何人都可以通过bid()函数进行ETH竞标。
* 当允许的参与者（例如主机、贡献者）调用finaliz()尝试结算拍卖并且众筹最终持有NFT时，则成功。
* 如果在获取符合条件的NFT之前过期时间过去，则失败。

>常见的创建选项
>除了为每种众筹类型描述的创建选项外，所有众筹类型都有一些共同的选项：
>* `string name`：众筹/治理方的名称。
>* `string symbol`：众筹/治理方NFT的代币符号。
>* `uint256 customizationPresetId`：用于众筹和治理NFT的自定义预设ID。定义众筹的tokenURI（）SVG图像将如何呈现（例如颜色，浅色/深色模式）。
>* `address splitRecipient`：当方转变为治理时，接收一部分投票权（或额外的投票权）的地址。
>* `uint16 splitBps`：splitRecipient收到的最终总投票权的百分比（以基点为单位）。
>* `address initialContributor`：如果在部署过程中附加了ETH，则将其解释为贡献。这是谁获得该贡献的信用。
>* `address initialDelegate`：如果有初始贡献，则他们最初将其投票权委托给的人当众筹转变为治理时。
>* `IGateKeeper gateKeeper`：要使用的门卫合同（如果非空）来限制谁可以为此众筹做出贡献（有时购买/出价）。
>* `bytes12 gateKeeperId`：要使用的gateKeeper合同内的门户ID。
>* `FixedGovernanceOpts governanceOpts`：如果众筹成功，治理方将使用的固定治理选项。除了方主机，该字段的哈希值仅在创建时存储在链上。必须再次全部提供该字段，以便方可获胜。
>
>众筹在初始化时具有大多数固定选项，即创建众筹后无法更改。唯一的例外是customizationPresetId，可以在治理阶段后更改。

### <font color="#5395ca">可选的Gatekeeper创建数据（暂时没搞懂）</font> 
前面提到的每个创建函数中可以接收一个可选的字节`createGateCallData`参数，如果非空，则会针对每个众筹的创建选项中的 `gateKeeper` 地址进行调用。这样做的目的是在 `gatekeeper` 实例上调用一个 `createGate()` 类型的函数，以便用户可以在同一笔交易中部署一个新的众筹与一个新的`gate`。此函数调用预计将返回一个 `bytes12`，该 `bytes12` 将被解码并将覆盖众筹的创建选项中的 `gateKeeperId`。由于工厂没有其他责任、特权或资产，因此不会对 `createGateCallData` 或 `gateKeeper` 进行审查。

### <font color="#5395ca">可选的初始贡献</font> 
所有创建函数都是可支付的。任何附加到调用中的以太将附加到众筹代理的部署中。这将在 `Crowdfund` 构造函数中检测到，并被视为对众筹的初始贡献。该方的 `initialContributor` 选项将指定谁应为此贡献获得信用。

### <font color="#5395ca">众筹生命周期</font>
所有众筹都共享一个生命周期的概念，其中只能执行某些操作。这些操作在 `Crowdfund.CrowdfundLifecycle` 中定义：
* Invalid: 众筹不存在。
* Active: 众筹已创建，可以进行贡献和收购功能的调用。
* Expired: 众筹已过期，不再允许进行更多的贡献。
* Busy: 合约在复杂操作期间设置的临时状态，用作可重入性保护。
* Lost: 众筹未能及时获得 NFT。贡献者可以收回他们的全部贡献。
* Won: 众筹已获得 NFT，现在由治理方持有。贡献者可以领取他们的治理 NFT 或收回未使用的 ETH。
### <font color="#5395ca">Crowdfund Card Customization</font>
### <font color="#5395ca">CrowdfundFactory</font>
### <font color="#5395ca">CrowdfundFactory</font>
### <font color="#5395ca">CrowdfundFactory</font>

