# <font color="#5395ca">Crowdfund Contracts（众筹合约）</font>
这些合约允许人们创建和参加众筹，将ETH汇集在一起以获得NFT。针对特定的收购模式，存在多个众筹合约。

## <font color="#5395ca">1. 关键概念</font>
* 众筹：实现各种策略的合约，允许人们将ETH汇集在一起以获得NFT，最终目标是围绕它形成一个Party。
* 众筹NFT：代表对众筹所做的贡献的唯一NFT（ERC721）。每个贡献者在首次贡献时都会获得一个。在众筹结束（成功或失败）时，众筹NFT可以被销毁，以赎回未使用的ETH或在新的Party中获取治理NFT。
* Party：治理合约，在众筹获得NFT后将被创建并保管NFT。
* Globals：保存配置值的单个合约，由多个生态合约引用。
代理：所有众筹实例都部署为简单的代理合约，将调用转发到从Crowdfund继承的特定众筹实现。

## <font color="#5395ca">2. 合约预览</font>
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
  
## <font color="#5395ca">3. 合约说明</font>

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

## <font color="#5395ca">4. 众筹生命周期</font>
所有众筹都共享一个生命周期的概念，其中只能执行某些操作。这些操作在 `Crowdfund.CrowdfundLifecycle` 中定义：
* <font color="#abcd">Invalid</font> : 众筹不存在。
* <font color="#abcd">Active</font> : 众筹已创建，可以进行贡献和收购功能的调用。
* <font color="#abcd">Expired</font> : 众筹已过期，不再允许进行更多的贡献。
* <font color="#abcd">Busy</font> : 合约在复杂操作期间设置的临时状态，用作可重入性保护。
* <font color="#abcd">Lost</font> : 众筹未能及时获得 NFT。贡献者可以收回他们的全部贡献。
* <font color="#abcd">Won</font> : 众筹已获得 NFT，现在由治理方持有。贡献者可以领取他们的治理 NFT 或收回未使用的 ETH。

## <font color="#5395ca">5. Crowdfund Card Customization</font>

## <font color="#5395ca">6. 做出贡献</font>
在众筹处于活动生命周期时，用户可以向其捐赠ETH。
向众筹做出贡献的唯一方式是通过可支付的`contribute()`函数。为每个用户创建贡献记录，跟踪个人贡献金额以及总贡献金额，以确定每个用户的贡献的一部分被用于成功的众筹。

### <font color="#5395ca">众筹NFT</font>
用户第一次贡献时，由众筹合约本身实现，他们将铸造一个绑定灵魂的Crowdfund NFT。稍后可以销毁此NFT以退还未使用的ETH 和/或 铸造包含治理Party中投票权的NFT。  
> 贡献者只能拥有一个众筹NFT；同一贡献者的多次贡献不会铸造额外的众筹NFT。

### <font color="#5395ca">会计</font>
每个贡献都记录在数组中，存储在贡献者的地址下。  
对于每个贡献，存储两个详细信息：1）贡献的金额和2）贡献时的previousTotalContributions。  
为确定众筹结束后是否有未使用的贡献，合约将`previousTotalContributions`与获取NFT所用的`totalEthUsed`进行比较。
* 如果`previousTotalContributions + amount <= totalEthUsed`，则整个贡献都被使用。
* 如果`previousTotalContributions >= totalEthUsed`，则整个贡献未使用且退还给贡献者。
* 否则，只有贡献的`totalEthUsed - previousTotalContributions`被使用，其余部分应退还给贡献者。  

未使用的贡献可以在Party输或赢之后被回收。例如，如果众筹筹集了10 ETH以获取一个以7 ETH赢得的NFT，则剩余的3 ETH将被退还。如果Party输了，所有10 ETH将被退还。  
所有这些的会计逻辑都在Crowdfund合约中处理，所有众筹类型都从中继承。

### <font color="#5395ca">额外参数</font>
`contribute()`函数接受一个委托参数，这将是用户在治理党中铸造其投票权时的初始委托。即使是0价值的贡献，未来的贡献也可以更改初始委托。即使众筹结束后，也可以使用0值调用`contribute()`函数，以更新用户选择的委托。  
`contribute()`函数接受一个`gateData`参数，这将传递给所选方的`gatekeeper`（如果有）。如果使用了`gatekeeper`，则`gatekeeper`必须使用此任意数据来证明贡献者有参与的资格。

## <font color="#5395ca">7. 获胜</font>
每种众筹类型都有自己的获胜标准和操作方式。

### <font color="#5395ca">BuyCrowdfund</font>
如果在众筹到期之前允许的参与者成功调用`buy()`函数，则`BuyCrowdfund`获胜。  

谁可以调用`buy()`函数取决于`onlyHostCanBuy`和众筹是否使用`gatekeeper`。如果`onlyHostCanBuy`，则只有主持人可以调用它。如果众筹使用`gatekeeper`，则只有贡献者可以调用它。前者优先于后者，这意味着如果两者都为真，则只有主持人可以调用它。  

`buy()`函数将使用ETH（最高价格为`maximumPrice`）执行任意调用，以尝试获取预定的NFT。在任意调用成功返回后，该NFT必须由该方持有。然后，它将继续创建治理Party。

### <font color="#5395ca">CollectionBuyCrowdfund</font>
如果在众筹到期之前主持人成功调用`buy()`函数，则`CollectionBuyCrowdfund`获胜。  
`buy()`函数将使用价值（最高价格为`maximumPrice`）执行任意调用，以尝试从预定的ERC721获取任何NFT代币ID。  
在任意调用成功返回后，该NFT必须由该方持有。然后，它将继续创建治理Party，除非NFT是免费（或“赠送”的）。在这种情况下，它将退还所有贡献者的原始贡献金额并宣布损失。

### <font color="#5395ca">AuctionCrowdfund</font>
与其他众筹相比，`AuctionCrowdfund`需要更多的步骤和积极的干预，因为它需要与拍卖互动。

在众筹处于`Active`状态时，只有允许的方可以调用`bid()`来对众筹开始的拍卖进行竞标。

谁可以调用`bid()`取决于`onlyHostCanBid`和众筹是否使用`gatekeeper`。如果`onlyHostCanBid`，则只有主持人可以调用它。如果众筹使用`gatekeeper`，则只有贡献者可以调用它。前者优先于后者，这意味着如果两者都为真，则只有主持人可以调用它。

对于每个`bid()`调用，出价金额将是由所使用的市场包装器确定的最小获胜金额。出价将最多使用`maximumBid` ETH。众筹合同将委托调用Market Wrapper执行出价，因此众筹只使用可信赖的Market Wrappers非常重要。

在拍卖结束后，必须有人调用`finalize()`，无论众筹是否投标。这将解决拍卖（如果必要），可能会将出价的ETH退还给方或获取拍卖的NFT。即使在众筹到期后，仍然可以调用`finalize()`，在这种情况下，众筹甚至可能仍然获胜。如果获得了NFT，则将继续创建治理方。

如果设置了`onlyHostCanBid`选项，则只有主持人才能调用`bid()`。

### <font color="#5395ca">创建治理方</font>
在每个众筹中，在party通过获取NFT获胜后，它将创建一个新的治理Party实例，使用在众筹创建时提供的相同的固定治理选项。治理Party创建时的`totalVotingPower`仅为NFT的结算价格（我们为其支付了多少ETH）。购买的NFT也会立即转移到治理Party中。

此后，众筹将处于Won生命周期，将不再允许任何贡献。贡献者可以`burn()`其Crowdfund NFT，以退还未使用的任何ETH，并铸造包含Party内投票权的治理NFT。

## <font color="#5395ca">8. 失败</font>
通常情况下，众筹在未能获得目标NFT之前到期时失败。唯一的例外是`AuctionCrowdfund`，如果它持有NFT，则即使在到期后仍然可以被结算并获胜。

当众筹进入Lost生命周期时，贡献者可以通过`burn()`函数烧毁其Crowdfund NFT，以退还他们贡献的所有ETH。

## <font color="#5395ca">9. 销毁</font>
在众筹结束（Won或Lost生命周期）时，贡献者可以通过burn()函数销毁他们的Crowdfund NFT。  
如果众筹失败，销毁参与NFT将退还贡献者的所有贡献ETH。  
如果众筹获胜，销毁参与NFT将退还贡献者未使用的任何ETH，并在治理方中铸造投票权。

### <font color="#5395ca">计算投票权</font>
1. 贡献者的投票权等同于他们贡献的以太币数量，该以太币被用于获取 NFT。每个个人贡献都会被追踪，并与贡献时筹集到的总 ETH 数量进行比较。如果用户在众筹已经筹集到足够的 ETH 来获取 NFT 后进行贡献，则只有他们之前的贡献会计入最终的投票权。其他的贡献将在他们销毁众筹 NFT 时退还。

2. 如果众筹使用了有效的 splitBps 值创建，则每个贡献者投票权的此百分比将保留给 splitRecipient 领取。如果他们也是贡献者，则将两者的总和发放给他们。

### <font color="#5395ca">销毁他人的 NFT</font>
在众筹结束之前，贡献者变得不活跃是很常见的。为了确保治理方的成员在提案流程中拥有足够的投票权尽快运作，任何人都可以销毁任何贡献者的众筹 NFT。这样做将使贡献者的代表在治理方中获得贡献者的投票权，使代表能够开始使用该投票权。

## <font color="#5395ca">10. Gatekeepers</font>
`Gatekeeper`允许众筹限制谁可以为其做出贡献。每个`Gatekeeper`实现都存储多个`gates`，即一组用于定义参与者是否允许为众筹做出贡献的条件。每个`gates`都有自己的 ID。  

对于某些众筹，例如 `AuctionCrowdfund` 和 `BuyCrowdfund`，使用`Gatekeeper`也限制了谁可以执行某些操作。例如，对于 `BuyCrowdfund`，它限制谁可以调用 `buy()`，仅限于贡献者（而不是如果 `onlyHostCanBuy` 为 false，则任何人都可以调用它）。  

创建众筹时，用户可以选择在门卫实现中创建一个新门或使用现有门通过传入其门 ID。目前支持两种门卫类型：
* TokenGateKeeper
* AllowListGateKeeper
### <font color="#5395ca">TokenGateKeeper</font>
此 `Gatekeeper` 仅允许持有特定代币（例如 ERC20 或 ERC721）的持有者做出贡献，且其余额高于特定余额。每个`gate`在创建时存储其所需的代币和最低余额。虽然 ERC20 和 ERC721 代币将是主要用例，但实现了 `balanceOf()` 的任何合约都可以用于`Gatekeeper`。
### <font color="#5395ca">AllowListGateKeeper</font>
此 `Gatekeeper` 仅允许来自允许清单中的地址做出贡献。`Gatekeeper`存储了一个 Merkle 根，它使用提供的证明检查一个地址是否属于允许清单。每个 `gate` 在创建时存储其使用的 Merkle 根。
