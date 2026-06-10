// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/*
    1. 当前合约可以收集资产：收款函数
    2. 需要记录投资人，并且查看
    3. 在锁定期内，达到目标值，生产商可以提款
    4. 在锁定期内，未达到目标值，投资人可以退款
*/ 
contract FundMeDemo {

    //  创建引入聚合合约接口的类型 
    AggregatorV3Interface internal dataFeed;


    //  记录投资人的地址和投资额
    mapping(address=>uint256) public fundersToAmount;

    //  设置最小的交易值为一个 ETH （默认使用的单位是 Wei）
    uint256 constant MINIMUM_VALUE = 100 * 10 ** 18; 

    //  定义筹款方取款最小值
    uint256 constant TARGET_FUNDS = 1000 * 10 ** 18;

    //  合约拥有者（筹款方可以调用 收款函数？ 收款方是合约的拥有者）
    address owner;

    //  合约部署时间
    uint256 deploymentTimestamp;

    //  锁定期时间（单位：秒）
    uint256 lockTime;

    //  外部合约 ERC20 调用当前合约地址
    address public erc20Addr; 

    //  FundMe 投资终止（比如到期） Flag
    bool public getFundSuccess;


    //  通过构造函数初始化外部合约 (在使用这个合约之前我们需要获取地址？)
    constructor (uint256 _lockTime) {

        //  在构造函数中给对应的合约接口赋值地址 ETH -> USD :0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
        dataFeed = AggregatorV3Interface(0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43);
        owner = msg.sender;
        deploymentTimestamp = block.timestamp;
        lockTime = _lockTime;
    }

    
    //  收款函数
    //  payable: 当前函数可以接收 ETH
    function fund() external payable {
        
        //  设置最小的 value
        require(convertETHToUSD(msg.value) >= MINIMUM_VALUE, "Send More ETH");
        //  判断当前函数调用时间是否在窗口期内
        require(block.timestamp < deploymentTimestamp + lockTime, "Window is closed");
        //  用 mapping 存储发送交易的地址和金额（key 是投资人地址）
        fundersToAmount[msg.sender] = msg.value;
    }

    /**
   * Returns the latest answer.
   * 当前函数返回的是 ETH 对 USD 的价格
   */
  function getChainlinkDataFeedLatestAnswer() public view returns (int256) {
    // prettier-ignore
    (
      /* uint80 roundId */
      ,
      int256 answer,
      /*uint256 startedAt*/
      ,
      /*uint256 updatedAt*/
      ,
      /*uint80 answeredInRound*/
    ) = dataFeed.latestRoundData();
    return answer;
  }


  // 将链上的 ETH 转换成 USD
  function convertETHToUSD(uint256 ethAmount) internal view returns (uint256){

    //  从聚合合约中获取当前的 ETH -> USD 价格
    uint256 ethPrice = uint256(getChainlinkDataFeedLatestAnswer());
    //  保证精度 / 10 ** 18
    return ethPrice * ethAmount / (10 ** 8);
  }

    //  转换合约所有人（适用于转账的场景？）
  function transferOwnership(address newOnwer) public onlyOwner{
    owner = newOnwer;
  }

  /** 
    * 在锁定期内，筹款金额达到目标值，筹款方可以提款
  */
  function getFund() external windowClosed onlyOwner{
    
    //  获取当前合约的余额信息
    require( convertETHToUSD(address(this).balance) >= TARGET_FUNDS, "Target is not reached");
    //  transfer: transfer ETH and revert if tx failed 
    //  payable(msg.sender).transfer(address(this).balance);
    //  send: transfer ETH and return false if tx failed
    //  bool success = payable (msg.sender).send(address(this).balance);
    //  call: transfer ETH with data return value of function and bool 
    bool success;  
    // 当前 call 仅返回ETH转账执行的结果，没有调用其他函数
    (success, ) = payable (msg.sender).call{value: address(this).balance}("");
    require(success, "Transfer tx is failed");
    fundersToAmount[msg.sender] = 0;
    // 取款函数执行完毕 将 flag 设置为 true
    getFundSuccess = true;
  }

  /*
  * 投资人退款函数
  */
  function refund() external windowClosed {
    
    //  当前筹款达到 TARGET 时 投资人不可以提款
    require(convertETHToUSD(address(this).balance) < TARGET_FUNDS, "Target is Reached");
    //  查询当前合约中是否保存了投资人的地址（当前地址是否在 mapping 中有投资记录）
    require(fundersToAmount[msg.sender] != 0, "There is no fund for you");
    //  将投资人的 fund 转入投资人账户
    bool success;
    (success, ) = payable (msg.sender).call{value: fundersToAmount[msg.sender]}("");
    require(success, "Transfer tx is failed");
    //  将合约中存储的投资人投资金额设置为 0 
    fundersToAmount[msg.sender] = 0;
  }

  /*
  * 用 modifier 替换重复的 require 代码
  */
  modifier windowClosed () {
    //  判断当前函数调用时间是否达到窗口期
    require(block.timestamp >= deploymentTimestamp + lockTime, "Window is not closed");
    _;
  }

  /*
  * 限制筹款方调用的修改器
  */
  modifier onlyOwner () {
    //  限制谁能调用这个函数
    require(msg.sender == owner, "This funciton can only called by owner");
    _;
  }

  /*
    * ERC20 mint 通证之后更改当前合约 mapping 中存储的投资人资产信息
  */
  function setFunderToAmount(address funder, uint256 amountToUpdate) public {

    // 验证调用方地址合法性
    require(msg.sender == erc20Addr, "You do not have the permission to call this function.");
    //  更改 mapping 中存储的投资人资产信息
    fundersToAmount[funder] = amountToUpdate;
  }

  /*
    * 调用当前函数时，将当前合约中的地址设置为 ERC20 子合约 中的 sender 调用方地址
  */
  function setErc20Addr(address _erc20Addr) public onlyOwner {
    erc20Addr = _erc20Addr;
  }

}