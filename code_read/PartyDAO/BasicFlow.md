# <font color="#5395ca">Overview</font>
Party Protocol 提供了链上的功能，用于群体形成、协调和分配。Party Protocol 允许人们汇集资金以获取NFT，然后协同使用或作为群体出售这些NFT。该协议分为两个不同的阶段，按以下顺序进行：
1. 众筹阶段：在此阶段，参与者汇集ETH以获取一个NFT。
2. 治理阶段：在此阶段，参与者对一个NFT进行治理（通常是通过众筹获得的）。

# <font color="#5395ca">start a party</font>
创建自己的party时，需要选择自己想要参与的NFT，这个NFT通过名称、地址来搜索，或者粘贴来自OpenSea、Zora或Foundation的链接，根据你这一项输入的不同，会创建`BuyCrowdfund`、`CollectionBuyCrowdfund`、`AuctionCrowdfund`等多种类型的众筹。

## <font color="#5395ca">1. BuyCrowdfund</font>
### <font color="#5395ca">1.1 创建BuyCrowdfund</font>
#### <font color="#5395ca">1.1.1 参数</font>
调用`CrowdfundFactory`中的`createBuyCrowdfund`函数，创建并初始化一个`BuyCrowdfund`，有两个参数，如下：
1. opts：用于初始化众筹的选项。这些选项是固定的，不能在之后更改，它是一个struct，包含了具体的参数，需要在创建party时在DAPP中设定，参数如下：
     * `string name`：众筹名称
     * `string symbol`：众筹和治理NFT的代币符号
     * `uint256 customizationPresetId`：用于众筹和治理NFT的自定义预设ID（创建Party时的定制Party Card）
     * `IERC721 nftContract`：被购买的NFT的ERC721合同
     * `uint256 nftTokenId`：被购买的NFT的ID
     * `uint40 duration`：众筹购买NFT的持续时间，以秒为单位
     * `uint96 maximumPrice`：众筹最多为NFT支付的金额。
     * `address payable splitRecipient`：当party转变为治理时，收到最终投票权部分的地址。
     * `uint16 splitBps`：当party转变为治理时，`splitRecipient`接收的最终权力总数的百分比（以基点为单位）。
     * `address initialContributor`：如果在部署期间附加了ETH，则会将其解释为贡献。这是谁获得贡献的信用。
     * `address initialDelegate`：如果有初始贡献，这是他们在众筹转变为治理时将委托其投票权的人。
     * `uint96 minContribution`：每个地址可以为此众筹提供的最小ETH金额。
     * `uint96 maxContribution`：每个地址可以为此众筹提供的最大ETH金额。
     * `IGateKeeper gateKeeper`：用于限制谁可以为此众筹提供资金的gatekeeper合同（如果非空）。如果使用，只有投资者或主持人可以调用`buy()`。
     * `bytes12 gateKeeperId`：在gateKeeper合同中要使用的gate ID
     * `bool onlyHostCanBuy`：是否仅允许主持人调用`buy()`
     * `FixedGovernanceOpts governanceOpts`：如果众筹成功，则治理`Party`将使用的固定治理选项（即无法更改）。
2. createGateCallData：每个创建函数中可以接收一个可选的字节`createGateCallData`参数，如果非空，则会针对每个众筹的创建选项中的 `gateKeeper` 地址进行调用。这样做的目的是在 `gatekeeper` 实例上调用一个 `createGate()` 类型的函数，以便用户可以在同一笔交易中部署一个新的众筹与一个新的`gate`。此函数调用预计将返回一个 `bytes12`，该 `bytes12` 将被解码并将覆盖众筹的创建选项中的 `gateKeeperId`。由于工厂没有其他责任、特权或资产，因此不会对 `createGateCallData` 或 `gateKeeper` 进行审查。
#### <font color="#5395ca">1.1.2 初始化</font>
初始化代理合约的存储，信用初始贡献（如果有的话），并设置 `gatekeeper`（门卫）。
* 如果部署者在部署过程中传入了一些ETH，则为其信用初始贡献。
    ```java
    if (initialContribution > 0) {
        _setDelegate(opts.initialContributor, opts.initialDelegate);
        // If this ETH is passed in, credit it to the `initialContributor`.
        _contribute(opts.initialContributor, opts.initialDelegate, initialContribution, 0, "");
    }
    ```
* 设置gateKeeper需要在DAppp中开启Private Party选项，用于限制捐赠者资格（初始捐赠者始终可以进入），有三种类型：
  * TOKEN GATED：捐赠者必须持有`指定ERC-20合约`的代币，且当前持有的代币数量不小于`指定值`，才能向Party贡献ETH。
  * NFT GATED：捐赠者必须持有`指定ERC-721`的收藏品，且当前持有的此收藏品中的NFT数量不小于`指定值`，才能向Party贡献ETH。
  * ALLOW LIST：直接指定可以向Party做出贡献的地址
> 需要注意的是，`BuyCrowdfund`继承了`CrowdfundNFT`合约，进而实现了IERC721接口，因此它的初始化过程也是Crowdfund NFT的初始化。

众筹创建成功后，进入Active生命周期，现在可以进行贡献和收购功能的调用。

### <font color="#5395ca">1.2 贡献（也就是参与众筹）</font>
### <font color="#5395ca">1.2.1 参数</font>
主要通过`Crowdfund`中的`contribute() payable`函数实现，主要功能是为某一个众筹做出贡献或在众筹成功后更新您的治理委托（有关于投票权重）。对于受限制的众筹，可以提供gateData以证明成员身份。包含两个参数：
* `address delegate`：治理阶段委托的地址。
* `bytes gateData`：用于证明资格的传递给门卫的数据。
> `Crowdfund`中还实现了一个`contributeFor()`函数，用于代表另一个地址参与此众筹，与`contribute()`不同的地方在于前者使用参数`recipient`代替了后者代码中`msg.sender`的位置（仅限`contributeFor()`和`contribute()`，不包括这两个函数内部的调用）。

### <font color="#5395ca">1.2.1 过程</font>
1. contributor不可被gateKeeper阻挡且当前众筹处于Active状态。
2. 捐款金额必须大于最低捐款额，小于最高捐款额。
3. 统计当前众筹项目总捐款额。
4. 记录该捐赠者的捐款记录条目，此条目包含本次捐款贡献的金额`amount`和之前的总捐款数`previousTotalContributions`,作用是在众筹结束后确定是否有未使用的捐款，合约会将`previousTotalContributions`与获取NFT所用的`totalEthUsed`进行比较。
    * 如果`previousTotalContributions + amount <= totalEthUsed`，则整个捐款都被使用。
    * 如果`previousTotalContributions >= totalEthUsed`，则整个捐款未使用且退还给捐赠者。
    * 否则，只有捐款的`totalEthUsed - previousTotalContributions`被使用，其余部分应退还给捐赠者。

    也就是说当捐款总额大于NFT价格时，会按照捐款顺序使用捐款，未使用的部分则退还给捐赠者，当然，这是在众筹结束后的事情。
1. 铸造众筹NFT(仅限第一次捐款每个捐赠者只能拥有一个众筹NFT，同一捐赠者的多次贡献不会铸造额外的众筹NFT。)

> 如果有人通过强制（自杀式攻击）将ETH强制转入合同中，我们不能使用 `address(this).balance - msg.value` 作为以前的总贡献。对于公开众筹来说，这并不是什么大问题，但是对于私人众筹（由门卫保护），可能会引起悲伤，因为它最终会导致产生未归属或无法认领的治理权，这意味着该Party将永远无法达成100％的共识。

## <font color="#5395ca">1.3 收购</font>
### <font color="#5395ca">1.3.1 参数</font>
收购功能由`BuyCrowdfund`中的`buy()`函数实现，主要功能是执行任意calldata以进行购买，如果成功购买NFT，则`创建一个派对`，参数如下：
* `callTarget`：调用以购买NFT的目标合约。
* `callValue`：与调用一起发送的ETH数量。
* `callData`：要执行的calldata。
* `governanceOpts`：如果购买成功，则用于初始化`Party`实例中的治理的选项。
    * `address[] hosts`：初始party的host的地址。
    * `uint40 voteDuration`：人们可以对提案进行投票的持续时间。
    * `uint40 executionDelay`：在提案通过后等待多长时间才能执行。
    * `uint16 passThresholdBps`：最小接受票比例，以考虑通过提案，以bps计，其中10000 == 100％。
    * `uint16 feeBps`：治理分配的费用bps。
    * `address payable feeRecipient`：治理分配的费用接收方。
* `hostIndex`：如果调用者是Host，则这是调用者在`governanceOpts.hosts`数组中的索引。

### <font color="#5395ca">1.3.2 执行流程</font>
1. 根据成员变量`onlyHostCanBuy`的值校验调用`buy()`的人的身份，如果为`TRUE`，要求调用者为Party的Host，同时还会对比校验传入的`governanceOpts`与创建众筹时的治理选项的哈希；如果为`FALSE`，则要求调用者身份能通过预设的gateKeeper（如果存在的话），且必须为贡献者。
2. 校验要求当前众筹的生命周期出于Active状态。
3. 校验本次调用是否安全，包括是否有重入风险以及传入的callData参数不能调用IERC721的`approve`和`setApprovalForAll`函数，以防止将NFT从众筹中转移出去。
4. 确认callValue低于maximumPrice，也就是购买价格不高于前面设置好的最多为NFT支付的金额。
5. 购买NFT
    ```java
    (bool s, bytes memory r) = callTarget.call{ value: callValue }(callData);
    ```
6. 购买成功后会校验`totalEthUsed > totalContributions`，以防止未经核算的ETH用于操纵价格和创建“幽灵股份”，影响投票权。
7. 如果购买NFT的花费大于0，围绕新购买的NFT<font color="00dddd">创建一个Party</font>并确定胜利，进入治理阶段。
8. 如果所有NFT都是免费购买或全部赠送的，则通过确定损失来退还所有贡献者。

至此，Party的众筹阶段就结束了，后续操作需要根据众筹结果来决定。

## <font color="#5395ca">2. CollectionBuyCrowdfund</font>
`CollectionBuyCrowdfund`和`BuyCrowdfund`一样都继承了`BuyCrowdfundBase`，也就是说两者只是在初始化和购买NFT两个流程上有一些细微区别。
### <font color="#5395ca">2.1 初始化</font>
初始化代码位于`CollectionBuyCrowdfund`合约的`initialize`函数中，与`BuyCrowdfund`的区别只在于参数不同，如下所示：
* `CollectionBuyCrowdfundOptions opts`：
    * `string name`：众筹名称
    * `string symbol`：众筹和治理NFT的代币符号。
    * `uint256 customizationPresetId`：用于众筹和治理NFT的自定义预设ID。
    * `IERC721 nftContract`：被购买的NFT的ERC721合约。
    * `uint40 duration`：众筹购买NFT的持续时间，以秒为单位。
    * `uint96 maximumPrice`：众筹活动愿意支付的最高价格。
    * `address payable splitRecipient`：当群体转变为治理时，将获得最终投票权的地址。
    * `uint16 splitBps`：splitRecipient最终获得的最终权力总数的百分比（以bps为单位）。
    * `address initialContributor`：如果在部署期间附加了ETH，则将其解释为贡献。这是谁获得该贡献的信用。
    * `address initialDelegate`：如果有初始贡献，则在众筹转变为治理时，他们将委派其投票权的对象。
    * `uint96 minContribution`：每个地址可以向此众筹活动贡献的最小ETH金额。
    * `uint96 maxContribution`：每个地址可以向此众筹活动贡献的最大ETH金额。
    * `IGateKeeper gateKeeper`：用于限制谁可以向此众筹活动贡献的门卫合约（如果非空）。
    * `bytes12 gateKeeperId`：要使用的gateKeeper合约中的gate ID。
    * `FixedGovernanceOpts governanceOpts`：如果众筹成功，治理 Party 将使用的固定治理选项（即无法更改）。
* `bytes createGateCallData`：和`BuyCrowdfund`中的一致，不再赘述。

通过对比`BuyCrowdfund`中的初始化参数，很显然本类型的众筹只少了`nftTokenId`和`onlyHostCanBuy`两个参数，这两个参数的关键在于：
1. 本类型的众筹是购买指定ERC721合约中的任意NFT，而不是哪一个指定的NFT，具体买哪一个需要在购买时才决定。
2. 本类型的众筹购买仅限Host调用。

除了上面两个区别以外，本类型和`BuyCrowdfund`没有其他区别。
## <font color="#5395ca">3. CollectionBatchBuyCrowdfund</font>
从名称上可以看出，此众筹是批量购买指定ERC721合约中的NFT，在`CollectionBuyCrowdfund`的基础上多了一个`nftTokenIdsMerkleRoot`参数，这个参数是可购买的代币ID的默克尔根，如果为null，则可以购买集合中的任何代币ID。  
`CollectionBatchBuyCrowdfund`和`CollectionBuyCrowdfund`的区别在于购买时可以批量购买，并且需要验证购买的代币ID是否在默克尔树中。

## <font color="#5395ca">4. AuctionCrowdfund</font>
本类型的众筹可以重复对特定NFT（即已知的代币ID）进行竞标，直到赢得拍卖。
### <font color="#5395ca">4.1 初始化</font>
#### <font color="#5395ca">4.1.1 参数</font>
代码位于`AuctionCrowdfund`中的`initialize()`函数，参数如下：
* `string name`：众筹的名称。
* `string symbol`：众筹和治理NFT的代币符号。
* `uint256 customizationPresetId`：用于众筹和治理NFT的自定义预设ID。
* `uint256 auctionId`：拍卖ID（特定于IMarketWrapper）。
* `IMarketWrapper market`：处理与拍卖市场的交互的IMarketWrapper合约。
* `IERC721 nftContract`：被购买的NFT的ERC721合约。
* `uint256 nftTokenId`：被购买的NFT的ID。
* `uint40 duration`：众筹竞标NFT的时间限制，以秒为单位。
* `uint96 maximumBid`：允许的最高竞标价。
* `address payable splitRecipient`：当派对转换为治理时，接收最终投票权部分的地址
* `uint16 splitBps`：splitRecipient收到的最终总投票权百分比（以bps为单位）。
* `address initialContributor`：如果在部署期间附加了ETH，则将其解释为贡献。这是谁得到了这个贡献的信用。
* `address initialDelegate`：如果有初始贡献，这是他们在众筹转换为治理时将委托投票权的人。
* `uint96 minContribution`：每个人可以向此众筹贡献的最小ETH金额。
* `uint96 maxContribution`：每个人可以向此众筹贡献的最大ETH金额。
* `IGateKeeper gateKeeper`：门卫合约（如果不为空），用于限制谁可以向此众筹贡献（如果不为空）。如果使用，则只有贡献者或主持人可以调用`bid()`。
* `bytes12 gateKeeperId`：要使用的gateKeeper合约中的gate ID。
* `bool onlyHostCanBid`：派对是否只允许主持人调用`bid()`。
* `FixedGovernanceOpts governanceOpts`：如果众筹成功，则将使用固定的治理选项（即无法更改）创建治理Party。

#### <font color="#5395ca">4.1.2 过程</font>
1. 如果部署者在部署过程中传入了一些ETH，则为其信用初始贡献。
    ```java
    if (initialContribution > 0) {
        _setDelegate(opts.initialContributor, opts.initialDelegate);
        // If this ETH is passed in, credit it to the `initialContributor`.
        _contribute(opts.initialContributor, opts.initialDelegate, initialContribution, 0, "");
    }
    ```
2. 设置gateKeeper需要在DAppp中开启Private Party选项，用于限制捐赠者资格（初始捐赠者始终可以进入），有三种类型：
    * TOKEN GATED：捐赠者必须持有`指定ERC-20合约`的代币，且当前持有的代币数量不小于`指定值`，才能向Party贡献ETH。
    * NFT GATED：捐赠者必须持有`指定ERC-721`的收藏品，且当前持有的此收藏品中的NFT数量不小于`指定值`，才能向Party贡献ETH。
    * ALLOW LIST：直接指定可以向Party做出贡献的地址
3. 检查拍卖是否可以竞标并且有效。
4. 检查当前拍卖的最低出价是否小于本众筹的最高出价。
 
### <font color="#5395ca">4.2 贡献（也就是参与众筹）</font>
也是通过`Crowdfund`中的`contribute() payable`函数实现，和前面一样，不再赘述。

### <font color="#5395ca">4.3 竞标</font>
### <font color="#5395ca">4.3.1 参数</font>
竞标操作的实现代码位于`AuctionCrowdfundBase`合约中，有如下三种实现函数：
1. `bid()`：使用此众筹中的资金在NFT上竞标，将最小可能出价定为最高出价，最高不超过`maximumBid`。仅当`onlyHostCanBid`未启用时，才可由贡献者调用。
2. `bid(FixedGovernanceOpts memory governanceOpts, uint256 hostIndex)`：使用此众筹中的资金在NFT上竞标，将最小可能出价定为最高出价，最高不超过`maximumBid`。
   * `governanceOpts`：众筹创建时的治理选项。仅用于只有主机可以竞标的众筹，以验证调用者是否是主机。
   * `hostIndex`：如果调用者是主机，则这是调用者在“governanceOpts.hosts”数组中的索引。仅用于只有主机可以竞标的众筹，以验证调用者是否是主机。
3. `bid(uint96 amount,FixedGovernanceOpts memory governanceOpts,uint256 hostIndex)`：
   * `amount`：竞标金额。
   * `governanceOpts`：众筹创建时的治理选项。仅用于只有主机可以竞标的众筹，以验证调用者是否是主机。
   * `hostIndex`：如果调用者是主机，则这是调用者在“governanceOpts.hosts”数组中的索引。仅用于只有主机可以竞标

### <font color="#5395ca">4.3.2 过程</font>
1. 检查拍卖是否仍然活跃。
2. 将状态标记为Busy，以防止调用burn()、bid()和contribute()，因为这将导致CrowdfundLifecycle.Busy。
3. 确保拍卖没有被最终确定。（通过参数`IMarketWrapper market`实现）
4. 只有在我们不是当前最高出价者时才进行出价。
5. 获取成为最高出价者所需的最低出价。
   ```java
    // 这里就是前两个竞拍函数和第三个给定竞拍价的函数的区别
    if (amount == type(uint96).max) {
        amount = market_.getMinimumBid(auctionId_).safeCastUint256ToUint96();
    }
   ```
6. 防止未计入账户的 ETH 用于夸大出价并在投票权中创建“幽灵股份”。
7. 确保出价低于本众筹允许的最高竞标价。
8. 将竞拍价提交给市场合约。
9. 将状态标记为Active。

### <font color="#5395ca">4.4 竞标结束</font>
代码实现位于`AuctionCrowdfund`合约中的`finalize`函数，如果我们竞标成功，将会索取NFT，并将创建治理方（Party）；如果输了，将恢复我们的出价。
#### <font color="#5395ca">过程</font>
1. 检查拍卖是否仍处于活动状态并且没有超过“expiry”时间。
2. 如果拍卖尚未最终确定，则进行最终确定。
   * 将状态标记为繁忙，以防止调用burn()、bid()和contribute()，因为这将导致CrowdfundLifecycle.Busy。
   * 如果我们之前已经出价或CF没有过期，则结束拍卖。
   * 如果众筹已过期且我们不是最高出价者，则跳过结束，因为没有赢得拍卖的机会。
3. 确认现在是否拥有 NFT
   * 如果持有NFT，且最后的竞拍价不为0，则围绕NFT创建治理方
   * 否则，我们输掉了拍卖或 NFT 赠予了我们。清除`lastBid`，因此`_getFinalPrice()`为 0，人们可以在烧毁其参与 NFT时赎回其全部贡献。

至此，本类型众筹竞拍结束，如果竞拍成功，则创建Party进入治理阶段。

## <font color="#5395ca">3. RollingAuctionCrowdfund</font>
本类型众筹和`AuctionCrowdfund`相似，其可以重复对特定市场（例如 Nouns）上特定收藏品的 NFT 进行出价，并可以`在赢得拍卖之前继续对新拍卖进行出价`。










