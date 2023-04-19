# <font color="#5395ca">start a party</font>
创建自己的party时，需要选择自己想要参与的NFT，这个NFT通过名称、地址来搜索，或者粘贴来自OpenSea、Zora或Foundation的链接，根据你这一项输入的不同，会创建`BuyCrowdfund`、`CollectionBuyCrowdfund`、`AuctionCrowdfund`三种类型的众筹。

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
1. contributor不可被gateKeeper阻挡且当前众筹出于Active状态。
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
## <font color="#5395ca">1. BuyCrowdfund</font>
## <font color="#5395ca">1. BuyCrowdfund</font>
## <font color="#5395ca">1. BuyCrowdfund</font>
## <font color="#5395ca">1. BuyCrowdfund</font>
## <font color="#5395ca">1. BuyCrowdfund</font>


