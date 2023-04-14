# Party Protocol 
Party Protocol 是一种用于团队协作的协议。Party Protocol 提供了链上功能，用于团队形成、协调和分配。Party Protocol 允许人们将资金汇集在一起以收购 NFT，然后协调使用或作为团队出售这些 NFT。

## 模式
在此代码库中有几种经常使用的代码模式。在深入了解合同之前熟悉它们将极大地帮助理解为什么要做某些事情：
* 几乎在所有合同中都使用了离线存储模式。
* 显式存储桶模式在 PartyGovernance 和 ProposalExecutionEngine 实现中都被使用。
* 打包存储模式在几乎所有合同中都被使用，以确保不仅在可能的情况下存储插槽被打包，而且经常一起访问的项目（例如，在PartyGovernance中的feeRecipient和feeBps）被打包在同一个插槽中，以便在单个调用中检索。
* Merkle证明被用于实现AllowListGateKeeper。