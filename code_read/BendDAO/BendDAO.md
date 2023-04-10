本文档记录BendDAO所有相关问题
# 1. 清算
## 1.1 清算示例
假设当您在BendDAO上借入60 ETH时，BAYC的底价为100 ETH。

如果底价下降到75 ETH，则24小时清算保护可能会被触发，因为您的NFT支持的贷款的健康系数低于1。

健康系数 = (75 * 80%) / (60 + 利息) < 1

健康系数 = (地板价 * 清算阈值) / 含息债务。

## 1.2 什么是健康系数
健康系数是您存入的NFT对借入的ETH及其基础价值的安全性的数字表示。该值越高，您的资金在清算情况下的安全状态就越高。

<font color="red">如果健康系数达到1，则可以触发您的存款的清算。健康系数低于1可能会被清算。对于HF = 2，抵押品价值与借款价值相比可以减少1/2，即50％。</font>

健康系数取决于您的抵押品的清算阈值与您借入资金的价值之间的比率。

您可以在<a href="https://docs.benddao.xyz/portal/risk/nft-risk-parameters">风险参数</a>部分找到所有抵押品参数。

## 1.3 当健康系数降低时会发生什么？
根据存款价值波动，健康系数将会增加或减少。

如果健康系数增加，借款状况将会改善，使清算阈值变得更加不可能达到。

如果抵押品价值相对于借入资产而言下降，则健康系数也会降低，从而增加清算风险。

## 1.4 Bend 是如何计算抵押的 NFT 的价值的？
NFT底价目前被用作抵押NFT的价格来源。原始价格数据来自OpenSea和LooksRare，这是最知名的NFT市场。抵押价值以以太币计价，而非在Bend上使用的USDT。

更多详情请查看：https://docs.benddao.xyz/portal/protocol-overview/oracle-price-feeding

## 1.5 为什么 Bend 上面不会发生市场清算危机？
24小时清算保护和NFT拍卖机制的存在意味着NFT不会被立即清算。同时，清算人的出价必须等同于OpenSea的底价。
> 24小时清算保护    
> 
> * NFT持有人不想交出其NFT的所有权。这就是为什么他们寻找其他流动性解决方案而不是出售NFT。为了避免市场波动造成的损失，借款人将有 24 小时的清算保护期来偿还贷款。如果您在 24 小时清算保护期内还款，您的 NFT 支持的贷款将永远不会被清算。
> * 在拍卖期间（24小时清算保护期），为了 NFT 持有人的安全，借款人（有抵押 NFT 的用户）仍然能够在拍卖开始后的 24 小时内偿还贷款。
> * <font color = #00FFFF>为确保安全和公平，即使在NFT底价恢复到正常价格之后，借款人在偿还部分贷款债务（默认情况下为50%）的同时还要向清算人支付最高罚款（债务的5％，最高为0.2 ETH）。 </font>
> * 在 Bend 拍卖机制下，只要出价高于底价，任何出价人都可以获得 NFT 的所有权。这样一来，所有的 NFT 都将获得一个价格发现机制，使交易透明化。

## 1.6 当清算发生时会怎么样？
当NFT贷款的“健康系数”低于1时，竞标者可以通过NFT拍卖和24小时清算保护来触发清算。借款人（抵押NFT的用户）将能够在24小时的时间窗口内偿还贷款。

## 1.7 Bend 的清算门槛是多少？
清算阈值是最大贷款价值比（LTV），即债务加利息与抵押品价值之和。如果抵押品有一个清算阈值，当债务价值达到抵押品价值的清算阈值时，贷款将被清算。清算阈值是按抵押品指定的，并以百分点表示。
> 清算门槛和健康系数什么关系？
>
> 健康系数 = (地板价 * 清算门槛) / 含息债务
>
> 清算门槛 = 健康系数 * 含息债务 / 地板价 (这里的健康系数应该是按照1来计算)
>
> 从这个公式可以看出，偿还部分债务可以提高健康系数以降低清算风险。

## 1.8 如果我是出价最高的人，我怎样才能得到 NFT？
拍卖结束后，最高出价者的拍卖页面上将有一个“清算”按钮。点击按钮后，清算的 NFT 将转移到您的钱包中。

## 1.9 如果出价超过债务，谁将获得差额？
借款人。如果抵押品在拍卖中以高于贷款金额的价格出售，超出部分将归借款人所有。

## 1.10 如果以太币价格下跌，我的贷款会被清算吗？
在 Bend 上，所有 NFT 均以以太币而非 USDT 计价。Ether 的价格和 NFT 的价格没有必然联系。