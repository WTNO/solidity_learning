# <font color="#5395ca">Overview</font>
Party Protocol 提供了链上的功能，用于群体形成、协调和分配。Party Protocol 允许人们汇集资金以获取NFT，然后协同使用或作为群体出售这些NFT。该协议分为两个不同的阶段，按以下顺序进行：
1. 众筹阶段：在此阶段，参与者汇集ETH以获取一个NFT。
2. 治理阶段：在此阶段，参与者对一个NFT进行治理（通常是通过众筹获得的）。

# <font color="#5395ca">众筹阶段</font>
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

### <font color="#5395ca">1.3.2 过程</font>
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
   * `governanceOpts`：众筹创建时的治理选项。仅用于只有Host可以竞标的众筹，以验证调用者是否是Host。
   * `hostIndex`：如果调用者是Host，则这是调用者在“governanceOpts.hosts”数组中的索引。仅用于只有Host可以竞标的众筹，以验证调用者是否是Host。
3. `bid(uint96 amount,FixedGovernanceOpts memory governanceOpts,uint256 hostIndex)`：
   * `amount`：竞标金额。
   * `governanceOpts`：众筹创建时的治理选项。仅用于只有Host可以竞标的众筹，以验证调用者是否是Host。
   * `hostIndex`：如果调用者是Host，则这是调用者在“governanceOpts.hosts”数组中的索引。仅用于只有Host可以竞标

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
代码实现位于`AuctionCrowdfund`合约中的`finalize`函数，如果我们竞标成功，将会索取NFT，并将创建治理NFT（Party）；如果输了，将恢复我们的出价。
#### <font color="#5395ca">过程</font>
1. 检查拍卖是否仍处于活动状态并且没有超过“expiry”时间。
2. 如果拍卖尚未最终确定，则进行最终确定。
   * 将状态标记为繁忙，以防止调用burn()、bid()和contribute()，因为这将导致CrowdfundLifecycle.Busy。
   * 如果我们之前已经出价或CF没有过期，则结束拍卖。
   * 如果众筹已过期且我们不是最高出价者，则跳过结束，因为没有赢得拍卖的机会。
3. 确认现在是否拥有 NFT
   * 如果持有NFT，且最后的竞拍价不为0，则围绕NFT创建治理NFT——Party。
   * 否则，我们输掉了拍卖或 NFT 赠予了我们。清除`lastBid`，因此`_getFinalPrice()`为 0，人们可以在烧毁其参与 NFT时赎回其全部捐赠。

至此，本类型众筹竞拍结束，如果竞拍成功，则创建Party进入治理阶段。

## <font color="#5395ca">5. RollingAuctionCrowdfund</font>
本类型众筹和`AuctionCrowdfund`相似，其可以重复对特定市场（例如 Nouns）上特定收藏品的 NFT 进行出价，并可以`在赢得拍卖之前继续对新拍卖进行出价`。
和`AuctionCrowdfund`相比，`RollingAuctionCrowdfund`只有竞标结束的实现不同。
## <font color="#5395ca">竞标结束</font>
具体实现位于`RollingAuctionCrowdfund`合约的`finalize(FixedGovernanceOpts memory governanceOpts)`函数，流程如下：
1. 检查拍卖是否仍处于活动状态并且未超过 expiry 时间。
2. 如果拍卖尚未最终确定，则进行最终确定。
   * 将状态标记为繁忙，以防止调用burn()、bid()和contribute()，因为这将导致CrowdfundLifecycle.Busy。
   * 如果我们之前已经出价或CF没有过期，则结束拍卖。
   * 如果众筹已过期且我们不是最高出价者，则跳过结束，因为没有赢得拍卖的机会。
3. 确认现在是否拥有 NFT
   * 如果持有NFT，且最后的竞拍价不为0，则围绕NFT创建治理NFT——Party。
   * 如果当前众筹生命周期为`Expired`，清除`lastBid`，因此`_getFinalPrice()`为 0，人们可以在销毁其参与NFT时赎回其全部捐赠。
   * 最后一种情况是如果这个拍卖失败了（或者在极少数情况下，如果 NFT 免费获得并且资金仍未使用），则继续进行下一个拍卖。

## <font color="#5395ca">6. 其他操作</font>
### <font color="#5395ca">6.1 burn(address payable contributor)</font>
销毁参与者的 NFT，可能会铸造投票权或退还未使用的 ETH 给贡献者。无论他们是否是贡献者，都可以将贡献者作为`splitRecipient`。任何人都可以代表贡献者调用此功能，在治理阶段解锁他们的投票权，确保代表们（`delegates`）获得他们的投票权并且治理不会停滞。
流程：
1. 执行此操作要求众筹赢得了拍卖，并且必须已经创建了一个Party。
2. 如果`contributor`依然存在，也就是说这个`contributor`贡献过且NFT还没销毁，则允许销毁NFT。
3. 计算`contributor`贡献的ETH中`已使用`和`未使用`两部分的金额，并根据两者计算`contributor`在治理阶段将拥有的投票权重。
```java
    votingPower = ((1e4 - splitBps_) * ethUsed) / 1e4;
    if (splitRecipient_ == contributor) {
        // Split recipient is also the contributor so just add the split
        // voting power.
        votingPower += (splitBps_ * totalEthUsed + (1e4 - 1)) / 1e4; // roundup
    }
```
4. 获取委派投票权的地址。如果为 null，则委派给自己。
5. 为贡献者铸造治理NFT（注意区别与前面的众筹NFT），如果铸造失败，则将其铸造到众筹本身并托管给贡献者，以便以后`claim`索取。
6. 将应返还给贡献者的未使用ETH进行退款。如果转账失败，贡献者仍然可以通过后续操作`claim`从众筹中索取资金。

### <font color="#5395ca">6.2 claim(address payable receiver)</font>
此操作用于索取应返还的治理NFT或退款，但由于`_burn()`中的错误（例如，未实现 `onERC721Received()`或无法接收ETH的合约），无法提供。只有在使用 `burn()`无法返回退款和治理NFT铸造时才调用此函数。流程：
1. 本函数需要由贡献者调用，因此通过msg.sender来获取治理NFT和退款信息。
2. 如果`claimInfo.refund`不为0，则从当前合约转账ETH到`receiver`。
3. 如果`claimInfo.governanceTokenId`不为0，则将治理NFT从当前合约转移至`receiver`。

# <font color="#5395ca">治理阶段</font>
在众筹获得其NFT之后，它会创建一个新的治理NFT——Party，并将NFT转移至该Party。贡献者将在新Party中被铸造为NFT成员，其投资额将对应于其在众筹中的贡献，从而获得相应的投票权。投票权可用于投票支持提案，提案包含Party可执行的可能行动。在此阶段需要了解的主要概念有：
* `Precious`：一组ERC-721代币，由治理合约（Party）保管，通常在众筹阶段获得。这些是受保护的资产，与其他资产相比，在提案中受到额外限制。
* `Governance NFT`：代表在治理Party中具有投票权的会员身份的NFT（ERC721）。
* `Party`：治理合约本身，它保管Precious，跟踪投票权，管理提案的生命周期，并同时是Governance NFT的代币合约。
* `Proposals（提案）`：Party将执行的链上操作，必须按照整个治理生命周期的进展才能执行。
* `Distributions`：一种（非受控）机制，通过该机制，各方可以按其相对投票权（Governance NFT）比例向Party持有的ETH和ERC-20代币分配。
* `Party Hosts`：可以单方面否决Party中提案的预定义帐户。通常在创建众筹时定义。
* `Globals`：一个单一的合约，保存了配置值，由多个生态系统合约引用。
* `Proxies`：所有Party实例都部署为简单的代理合约，将调用转发给Party实现合约。
* `ProposalExecutionEngine`：一个可升级的合约，Party合约将delegatecall到该合约中，该合约实现执行特定提案类型的逻辑。

涉及的主要合约有：
* `PartyFactory`：创建新的代理Party实例。
* `Party`：治理合约，也保管Precious NFT。这也是Governance NFT的ERC-721合约。
* `ProposalExecutionEngine`：可升级的逻辑（和一些状态）合约，用于从Party上下文执行每种提案类型。
* `TokenDistributor`：托管分配存入的ETH和ERC20代币给Party成员的托管合约。
* `Globals`：一个定义全局配置值的合约，被整个协议中的其他合约引用。

## <font color="#5395ca">1. 创建Party</font>
### <font color="#5395ca">1.1 参数</font>
当众筹成功获得NFT并且花费大于0时，会围绕获得的NFT创建一个Party，具体实现是由位于`Crowdfund`中的`_createParty()`函数调用`PartyFactory`来创建，参数如下：
* `address authority`：是可以在创建的Party上铸造代币的地址。在典型的流程中，众筹合约将把它设置为自己。
* `Party.PartyOptions memory opts`：用于初始化Party的选项。这些选项是固定的，不能在后期更改，也就是前文中的治理选项。
  * `string name`：Party名称。
  * `string symbol`：治理NFT的代币符号。
  * `uint256 customizationPresetId`：治理NFT的自定义预设ID。
  * `PartyGovernance.GovernanceOpts governance`：
    * `hosts`：初始Party Host的数组。这是唯一可以更改的配置，因为Host可以将其特权转让给其他帐户。
    * `voteDuration`：在提出提案后，成员可以投票的持续时间（以秒为单位），以使其通过。如果在提案通过之前此窗口过期，则将被视为失败。
    * `executionDelay`：提案通过后必须等待的时间（以秒为单位），然后才能执行。这给了Host时间否决已通过的恶意提案。
    * `passThresholdBps`：考虑通过提案所需的最小投票比例与totalVotingPower供应的比率。这是以基点表示的，即100 = 1％。
    * `totalVotingPower`：Party的总投票权。这应该是授予成员的所有（可能的）治理NFT的权重之和。请注意，该假设没有任何地方得到强制执行，因为可能有用于铸造超过100％的选票的用例，但是众筹合同中的逻辑不能铸造超过totalVotingPower。
    * `feeBps`：从该Party的分配中收取的费用，以保留给feeRecipient索取。通常，这将设置为由PartyDAO控制的地址。
    * `feeRecipient`：可以为该Party索取分配费用的地址。
* `IERC721[] memory preciousTokens`和`uint256[] memory preciousTokenIds`：共同定义了Party将保管的NFT，并强制执行额外的限制，以便它们不会轻易转出Party。此列表在Party创建后无法更改。请注意，此列表从未存储在链上（仅存储哈希值），在执行提案时需要将其传递到execute()调用中。
  
> Party是通过PartyFactory合约创建的。通常情况下，这是由众筹实例自动完成的，但直接与PartyFactory合约进行交互也是一个有效的用例，例如，围绕您已经拥有的NFT组建治理Party。

### <font color="#5395ca">1.2 过程</font>
1. 部署一个新的Proxy实例，其实现指向Globals合约中由GLOBAL_PARTY_IMPL键定义的Party合约。
2. 将资产转移到创建的Party中，通常是Precious NFT。
3. 作为authority，通过调用Party.mint()向Party成员铸造治理NFT。
   * 在典型的流程中，当贡献者销毁其贡献NFT时，众筹合约将调用此函数。
4. 可选地，作为authority，调用Party.abdicate()来撤销铸造特权，一旦所有Governance NFT都被铸造。
5. 在Party创建后的任何步骤中，具有治理NFT的成员都可以执行治理操作，尽管在投票权的总供应量尚未被铸造或分配的情况下，他们可能无法达成共识。

## <font color="#5395ca">2. 提出提案</font>
只能活跃成员（具有投票权）才能调用此功能。一旦准备就绪，任何成员或代表（具有非零有效投票权的人）都可以使用提案属性调用`propose()`，这将分配一个唯一的非零提案ID，并将提案置于投票状态。创建提案还将自动为提出人投票。随后，成员可以通过`accept()`来支持它，Party的主持人可以通过`veto()`单方面拒绝该提案。

### <font color="#5395ca">2.1 入口与参数</font>
本功能实现位于`PartyGovernance`合约中的`propose()`函数，参数如下：
* `Proposal memory proposal`：提案的详细信息
  * `uint40 maxExecutableTime`：提案无法再执行的时间，如果提案已执行，并且仍处于InProgress状态，则忽略此值。
  * `uint40 cancelDelay`：提案可以保持InProgress状态的最短时间（以秒为单位），在此之前无法取消。
  * `bytes proposalData`：编码的提案数据。前4个字节是提案类型，后面是特定于提案类型的编码提案参数。
* `uint256 latestSnapIndex`：在提案创建之前，调用者最近的投票权快照的索引，应该在链外检索并传递。

> 提案数据应该被添加前缀（像函数调用一样），使用4字节的`IProposalExecutionEngine.ProposalType`值作为开头，后面跟着特定于该提案类型的ABI编码数据（请参见[提案类型](https://github.com/PartyDAO/party-protocol/blob/main/docs/governance.md#arbitrarycalls-proposal-type)），例如，`abi.encodeWithSelector(bytes4(ProposalType.ListOnZoraProposal)`, `abi.encode(ZoraProposalData(...)))`。

> 提案状态  
> `Invalid`：提案不存在。  
> `Voting(投票中)`：提案已经被提出（通过`propose()`），没有被Party主持人否决，并且在投票窗口内。成员可以对提案进行投票，Party主持人可以否决提案。  
> `Defeated(失败)`：提案要么超过了投票窗口而没有达到通过阈值（passThresholdBps）的投票，要么被Party主持人否决。  
> `Passed(已通过)`：提案已经达到至少通过阈值（passThresholdBps）的投票，但仍需等待执行延迟（executionDelay）过去才能执行。此时成员可以继续对提案进行投票，Party主持人可以否决提案。  
> `Ready(准备就绪)`：与已通过相同，但此时已经满足执行延迟（executionDelay）或提案已经一致通过。任何成员都可以通过`execute()`执行提案，除非已经到达maxExecutableTime。  
> `InProgress(进行中)`：提案已经执行至少一次，但还有进一步步骤需要完成，因此需要再次执行。在提案处于进行中状态时，不允许执行其他提案，因此只能有一个提案处于进行中状态。不允许对进行中的提案进行投票或否决，但如果cancelDelay已到达，则可以通过`cancel()`强制取消。  
> `Complete(已完成)`：提案已经执行并完成了所有步骤。不允许进行投票或否决，也不能取消或再次执行。  
> `Cancelled(已取消)`：提案已经执行至少一次，但在第一次执行后cancelDelay秒内未能完成并被强制取消。  

### <font color="#5395ca">2.2 过程</font>
1. 存储创建提案的时间和提案哈希值到成员变量`_proposalStateByProposalId`。
2. 自动为提出人投票。

> 需要注意的一点是，提案属性（除了提案ID）中没有一个会被存储在链上。相反，只有这些字段的哈希值（由提案ID作为键）被存储在链上，以优化gas使用，并强制这些属性在生命周期操作之间不会更改。

## <font color="#5395ca">3. 对提案进行投票</font>
任何处于Voting、Passed或Ready状态的提案都可以通过`Party.accept()`由成员和代表进行投票。`accept()`函数会在提案创建时投出调用者的总有效投票权。一旦为提案投票的总投票权达到或超过通过阈值比例`passThresholdBps` ，提案将进入通过状态。

成员可以继续投票，甚至超过通过状态，以实现一致投票，这将使提案绕过`executionDelay`，并为某些提案类型解锁特定行为。当总投票权的`99.99%`被投票给提案时，满足一致投票条件,不检查100%是因为在众筹期间可能存在舍入误差。

### <font color="#5395ca">3.1 入口与参数</font>
本功能实现位于`PartyGovernance`合约中的`accept()`函数，参数如下：
* `uint256 proposalId`：要接受的提案的ID。
* `uint256 snapIndex`：调用者在提案创建前最后一次投票权快照的索引。应在链外检索并传递。

### <font color="#5395ca">3.2 过程</font>
1. 获取有关提案的信息。
2. 要求当前提案状态是否为Voting、Passed、Ready中的一种。
3. 要求不能重复投票，没投过则标记调用者已投票。
4. 增加此提案上的已投票总数。
5. 如果提案达到通过阈值，则更新提案状态为`Passed`。

## <font color="#5395ca">3. 否决权</font>
在提案的Voting、Passed和Ready阶段，Party Host可以通过调用`Party.veto()`单方面否决该提案，立即将提案置于Defeated状态。此时，无法对提案采取进一步行动。  

否决权背后的理念是，如果Party中的投票权被过度集中，以至于恶意行为者可以通过恶意提案，Party Host可以作为最后的防线。另一方面，Party Host也可以通过否决每个合法提案来拖延Party的进展，因此Party需要非常小心地选择他们的Host。

### <font color="#5395ca">说明</font>
本功能实现位于`PartyGovernance`合约中的`vote()`函数，只有`proposalId`一个参数，执行过程如下：
1. 要求当前提案状态是否为Voting、Passed、Ready中的一种。
2. 将 votes 设置为 -1 表示否决（也就是`type(uint96).max`）。

## <font color="#5395ca">4. 执行提案</font>
当一个提案获得足够的票数通过且执行延迟窗口已经过期，或者如果该提案达成了一致意见，任何具有当前非零有效投票权的成员都可以执行该提案。这是通过Party.execute()函数实现的。  
如果发生以下情况，调用execute()将失败：
* 该提案已经被执行并完成（处于Complete状态）。
* 该提案尚未被执行，但其maxExecutableTime已过。
* 该提案的执行失败。
* 存在另一个已被执行但未完成（还有更多步骤）的提案。
* 如果该提案是原子性的，即为单步提案，则立即进入完成状态。
  
### <font color="#5395ca">4.1 入口与参数</font>
本功能实现位于`PartyGovernance`合约中的`execute()`函数，参数如下：
* `uint256 proposalId`：要执行的提案的ID。
* `Proposal memory proposal`：提案的详细信息。
* `IERC721[] memory preciousTokens`和`uint256[] memory preciousTokenIds`：共同定义了Party保管的NFT。
* `bytes calldata progressData`：上一次execute()调用返回的数据（如果有）。
* `bytes calldata extraDat`：提案可能需要执行步骤的链下数据。

### <font color="#5395ca">4.2 过程</font>
1. 获取关于提案的信息。
2. 要求提案当前状态必须是`Ready`或者`InProgress`。
3. 如果提案状态是`Ready`，也就是说提案尚未执行，则要求它没有过期。请注意，已经执行但仍有更多步骤的提案会忽略maxExecutableTime。
4. 检查先前的列表是否有效。
5. 预先将提案设置为已完成，以避免在更深层的调用中再次执行它。
6. 执行提案：
    * 设置提案执行引擎的参数。 
    * 在提案执行后获取返回的进度数据。
    * 如果返回的进度数据为空，则提案已完成，不应再次执行,返回`true`。
7. 如果上一步返回的是`false`，则将第五步预设的已完成状态清零。

> 多步骤提案
>
> 有些提案类型需要完成多个步骤和交易。例如，`ListOnZoraProposal`类型的提案。此提案将首先将一个NFT作为拍卖品列在Zora上，然后如果拍卖在一定时间内没有获得任何竞标或者完成后有获胜出价，Party将需要取消或完成该拍卖。为了完成这个过程，提案必须多次执行，直到被认为是完成的，并可以进入`Complete`状态。  
> 
> 通常，在多步骤提案中，需要在步骤之间记住一些状态。例如，`ListOnZoraProposal`类型将需要记住它创建的Zora拍卖的ID，以便在最后一步取消或完成它。与其在链上存储这些（可能复杂的）数据，执行提案将发出一个带有任意字节的`nextProgressData`参数的`ProposalExecuted`事件，该参数应在下一次调用`execute()`时传递，以推进提案。Party只会存储`nextProgressData`的哈希，并确认其与传入的哈希匹配。该数据包含推进提案到下一步所需的任何编码状态。  
> 
> 一旦提案执行了最后一步，它将在ProposalExecuted事件中发出一个空的nextProgressData。

## <font color="#5395ca">5. 取消提案</font>
多步骤提案存在无法完成的风险，因为它们可能会继续回滚。如果一个提案处于`InProgress`状态，则无法执行其他提案，因此Party可能会永久卡住，无法执行任何其他提案。为了防止这种情况发生，提案具有cancelDelay属性。在提案处于InProgress状态超过一定时间后，可以通过调用`cancel()`将其强制进入Complete状态。还有一个全局（在Globals合约中定义）的配置值（GLOBAL_PROPOSAL_MAX_CANCEL_DURATION），将cancelDelay限制为不太久的未来持续时间。

取消提案应该被视为最后的手段，因为它可能会让Party处于破碎的状态（例如，资产被卡在另一个协议中），因为提案无法适当地清理自己。因此，Party应该小心，不要传递具有太短的`cancelDelay`的提案，除非他们完全信任所有其他成员。

### <font color="#5395ca">5.1 入口与参数</font>
本功能实现位于`PartyGovernance`合约中的`cancel()`函数，参数如下：
`uint256 proposalId`：要取消的提案的ID。
`Proposal calldata proposal`：要取消的提案的细节。

### <font color="#5395ca">5.1 过程</font>
1. 获取有关提案的信息。
2. 提案详情必须与`propose()`中保持一致。
3. 要求提案必须处于`InProgress`状态。
4. 将`cancelDelay`限制在全局最大和最小取消延迟之间，以减轻Party因设置不切实际的`cancelDelay`或过于低的`cancelDelay`而意外永久卡住的风险。
5. 执行`cancel()`必须已经超出了 $executedTime + cancelDelay$。
6. 通过将完成时间设置为当前时间，并设置高位以标记提案已取消。
7. 通过`delegatecall`调用提案引擎实现来执行取消操作。








