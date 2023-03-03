// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface DelegateERC20 {
    function delegateTransfer(
        address to,
        uint256 value,
        address origSender
    ) external returns (bool);
}

interface IDetectionBot {
    function handleTransaction(address user, bytes calldata msgData) external;
}

interface IForta {
    function setDetectionBot(address detectionBotAddress) external;

    function notify(address user, bytes calldata msgData) external;

    function raiseAlert(address user) external;
}

contract Forta is IForta {
    mapping(address => IDetectionBot) public usersDetectionBots;
    mapping(address => uint256) public botRaisedAlerts;

    // 设置检测bot
    function setDetectionBot(address detectionBotAddress) external override {
        usersDetectionBots[msg.sender] = IDetectionBot(detectionBotAddress);
    }

    // 唤醒DetectionBot进行检测
    function notify(address user, bytes calldata msgData) external override {
        if (address(usersDetectionBots[user]) == address(0)) return;
        try usersDetectionBots[user].handleTransaction(user, msgData) {
            return;
        } catch {}
    }

    // 触发警报,警报数量+1
    function raiseAlert(address user) external override {
        if (address(usersDetectionBots[user]) != msg.sender) return;
        botRaisedAlerts[msg.sender] += 1;
    }
}

// 找出漏洞，防止CryptoVault的token被耗尽
// CryptoVault持有100 DET (DoubleEntryToken)
// CryptoVault持有100 LGT (LegacyToken)
contract CryptoVault {
    address public sweptTokensRecipient;
    IERC20 public underlying; // DET

    constructor(address recipient) {
        sweptTokensRecipient = recipient;
    }

    // 设置underlying 
    function setUnderlying(address latestToken) public {
        require(address(underlying) == address(0), "Already set");
        underlying = IERC20(latestToken);
    }

    // 任何人都可以调用，允许金库将任意 token的整个余额转移到sweptTokensRecipient
    // 用于检索卡在合约中的代币的常用函数
    // 逻辑中阻止了underlying也就是DET的转账，但是可以通过CryptoVault.sweepToken(address(legacyTokenContract))抽空underlying
    // TODO：因此，我们需要做的就是阻止underlying被抽空
    function sweepToken(IERC20 token) public {
        require(token != underlying, "Can't transfer underlying token");
        token.transfer(sweptTokensRecipient, token.balanceOf(address(this)));
    }
}

contract LegacyToken is ERC20("LegacyToken", "LGT"), Ownable {
    DelegateERC20 public delegate;

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function delegateToNewContract(DelegateERC20 newContract) public onlyOwner {
        delegate = newContract;
    }

    // 转移代币，在sweepToken中被调用
    function transfer(address to, uint256 value) public override returns (bool) {
        if (address(delegate) == address(0)) {
            return super.transfer(to, value); // 由当前合约转移
        } else {
            // 源头，msg.sender为CryptoVault合约
            return delegate.delegateTransfer(to, value, msg.sender); // 由DelegateERC20合约转移
        }
    }
}

contract DoubleEntryPoint is ERC20("DoubleEntryPointToken", "DET"), DelegateERC20, Ownable {
    address public cryptoVault;
    address public player;
    address public delegatedFrom;
    Forta public forta;

    constructor(
        address legacyToken,
        address vaultAddress,
        address fortaAddress,
        address playerAddress
    ) {
        delegatedFrom = legacyToken;
        forta = Forta(fortaAddress);
        player = playerAddress;
        cryptoVault = vaultAddress;
        _mint(cryptoVault, 100 ether);
    }

    // 只接受来自LegacyToken的调用
    modifier onlyDelegateFrom() {
        require(msg.sender == delegatedFrom, "Not legacy contract");
        _;
    }

    modifier fortaNotify() {
        address detectionBot = address(forta.usersDetectionBots(player));

        // Cache old number of bot alerts
        // 记录进入逻辑之前的警报数量
        uint256 previousValue = forta.botRaisedAlerts(detectionBot);

        // Notify Forta,usersDetectionBots[player]不能为空，需要调用过setDetectionBot
        // 唤醒Forta进行检测
        forta.notify(player, msg.data);

        // Continue execution
        _;

        // Check if alarms have been raised
        // 检查警报数量是否增加，增加了就回退
        if (forta.botRaisedAlerts(detectionBot) > previousValue)
            revert("Alert has been triggered, reverting");
    }

    // 只接受来自LegacyToken的调用
    function delegateTransfer(
        address to,
        uint256 value,
        address origSender
    ) public override onlyDelegateFrom fortaNotify returns (bool) {
        // _transfer只检查to和origSender不是address(0)，以及origSender是否有足够的代币转账到to（它也检查上下溢出条件）
        // 不检查origSender是msg.sender或是否有足够的授权（allowance）
        // 因此需要onlyDelegateFrom
        _transfer(origSender, to, value);
        return true;
    }
}

// last:部署本合约，并调用Forta中的setDetectionBot
contract DetectionBot is IDetectionBot {
    address private cryptoVault;

    constructor(address _cryptoVault) {
        cryptoVault = _cryptoVault;
    }

    // 从调用溯源可知msgData是调用delegateTransfer(address to,uint256 value,address origSender)的数据
    // 要在这个函数里面阻止CryptoVault的DET代币被LegacyToken抽空
    function handleTransaction(address user, bytes calldata msgData) external override {
        address to;
        uint256 value;
        address origSender;
        // 前四个字节是选择器
        bytes memory selector = abi.encodePacked(msgData[0], msgData[1], msgData[2], msgData[3]);
        (to, value, origSender) = abi.decode(msgData[4:],(address, uint256, address));

        bytes memory delegateTransferSelector = abi.encodeWithSignature("delegateTransfer(address,uint256,address)");

        // origSender不能是CryptoVault合约且签名不能为delegateTransfer的签名
        if (keccak256(selector) == keccak256(delegateTransferSelector) && cryptoVault == origSender) {
            // 同时满足说明是LegacyToken调用了CryptoVault.transfer,必须警告
            Forta(msg.sender).raiseAlert(user);
        }
    }
}
