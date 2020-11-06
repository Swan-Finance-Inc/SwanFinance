const SwanStakingTest = artifacts.require("SwanStake");
const ERC20 = artifacts.require("Swan")

var BN = require('bignumber.js');

const { time } = require('@openzeppelin/test-helpers');


contract("SwanStaking", (accounts)=>{
	let erc20Instance = null;
	let swanInstance = null;

	before(async () => {
        erc20Instance = await ERC20.deployed();
        swanInstance = await SwanStakingTest.deployed();
	});

	it("SwanToken address should be correct", async () => {
		const tokenAddress = await swanInstance.swanTokenAddress();
		assert.equal(tokenAddress, erc20Instance.address,"Addresses are not same");
	});

	it("Total Staked Swan tokens should initially be zero", async () => {
		const totalStaked = await swanInstance.totalStakedTokens();
		assert.equal(totalStaked.toString(), "0","Total Staked is more than 0");
		
	});

it("User should be able to Transfer and Approve tokens", async () => {
		const transferAmount = new BN(30000000000000000000000);
		const approveAmount = new BN(2500000000000000000000);
									

		const beforeBalance = await erc20Instance.balanceOf(accounts[1]);

		await erc20Instance.transfer(accounts[1],transferAmount);
		await erc20Instance.transfer(accounts[2],transferAmount);

		await erc20Instance.approve(swanInstance.address,approveAmount,{ from:accounts[1]} );
		await erc20Instance.approve(swanInstance.address,approveAmount,{ from:accounts[2]} );
	});

	/** 
		* Requirements for testing stake Function
		* Check the Struct update.
		* Increase in Contract Balance
		* userTotalStake mapping
		* isStaker mapping
		* 	
	**/
	it("User should be able to STAKE $2k(or more) in Main Account", async () => {
		const stakeAmount = new BN(2000000000000000000000);
		
		const bool_beforeStake = await swanInstance.isStaker(accounts[1]);
		
		const tokenBalanceBeforeStake = await swanInstance.userTotalStakes(accounts[1]);
		const staked = await swanInstance.stake(stakeAmount,{from:accounts[1]});
		const event = staked.logs[0].args;

		const bool_afterStake = await swanInstance.isStaker(accounts[1]);
		const tokenBalanceAfterStake = await swanInstance.userTotalStakes(accounts[1]);
		const totalStakedTokens = await swanInstance.totalStakedTokens();

		const currentTokenBalance = tokenBalanceAfterStake - tokenBalanceBeforeStake;

		assert.equal(event._user,accounts[1],"User address is not Same");
		assert.equal(event._amount.toString(), "2000000000000000000000","Amount entered is not Same");
		assert.equal(event._lockupPeriod.toString(), "4","LockUpPeriod is not same");
		assert.equal(event._interest.toString(), "14", "Interest assigned is wrong");

		assert.equal(bool_beforeStake, false, "User assigned as Staker before Staking")
		assert.equal(bool_afterStake,true,"User NOT assigned as Staker even after Staking")
		assert.equal(BigInt(currentTokenBalance).toString(), event._amount.toString(), "User token staking details didn't update as expected");
		assert.equal(totalStakedTokens.toString(), "2000000000000000000000","Staking Contract token balance did not update as expected");
	});

/**
		*Requirements for testing stakeTokensOneMonth Function
		* Must increases Contract's Balance
		* Must modify the struct
		* Must deduct User balance of Tokens
		* Must update userTotalStake mapping
		* APY must be added correctly
	**/

	it("STAKERs should be able to Stake for 1 month LockUp period with High APY", async ()=>{

		// Checking User Stake Details update in Swan Stakng Contract
		const stake = await swanInstance.stakeTokensOneMonth(1000, {from:accounts[1] });
		const tokenBalanceAfterStake = await swanInstance.userTotalStakes(accounts[1]);
		
		// Checking SwanStaking contract token balance change
		const totalStakedTokens = await swanInstance.totalStakedTokens();

		const event = stake.logs[0].args

		//Checking sturct updation in the Staking contract
		assert.equal(event._user,accounts[1],"User address is not Same");
		assert.equal(event._amount.toString(), "1000","Amount entered is not Same");
		assert.equal(event._lockupPeriod.toString(), "1","LockUpPeriod is not same");
		assert.equal(event._interest.toString(), "16","APY not assigned currectly for 16%");	
		assert.equal(tokenBalanceAfterStake.toString(), "2000000000000000001000", "User token staking details didn't update as expected");
		assert.equal(totalStakedTokens.toString(), "2000000000000000001000","Staking Contract token balance did not update as expected")
	})

	it("Non-STAKERs should be able to Stake for 1 month LockUp period with Low APY", async ()=>{

		// Checking User Stake Details update in Swan Stakng Contract
		const stake = await swanInstance.stakeTokensOneMonth(1000, {from:accounts[2] });
		const tokenBalanceAfterStake = await swanInstance.userTotalStakes(accounts[2]);
		
		// Checking SwanStaking contract token balance change
		const totalStakedTokens = await swanInstance.totalStakedTokens();

		const event = stake.logs[0].args

		//Checking sturct updation in the Staking contract
		assert.equal(event._user,accounts[2],"User address is not Same");
		assert.equal(event._amount.toString(), "1000","Amount entered is not Same");
		assert.equal(event._lockupPeriod.toString(), "1","LockUpPeriod is not same");
		assert.equal(event._interest.toString(), "12","APY not assigned currectly for 12%");	
	
		assert.equal(tokenBalanceAfterStake.toString(), "1000", "User token staking details didn't update as expected");
		assert.equal(totalStakedTokens.toString(), "2000000000000000002000","Staking Contract token balance did not update as expected")
	})

	it("STAKERs should be able to Stake for 3 month LockUp period with High APY", async ()=>{

		// Checking User Stake Details update in Swan Stakng Contract
		const stake = await swanInstance.stakeTokensThreeMonth(1000, {from:accounts[1] });
		const tokenBalanceAfterStake = await swanInstance.userTotalStakes(accounts[1]);
		
		// Checking SwanStaking contract token balance change
		const totalStakedTokens = await swanInstance.totalStakedTokens();
		const event = stake.logs[0].args
		//Updating time to check withdrawl functions	

		//Checking sturct updation in the Staking contract
		assert.equal(event._user,accounts[1],"User address is not Same");
		assert.equal(event._amount.toString(), "1000","Amount entered is not Same");
		assert.equal(event._lockupPeriod.toString(), "3","LockUpPeriod is not same");
		assert.equal(event._interest.toString(), "20","APY not assigned currectly for 16%");
	
		assert.equal(tokenBalanceAfterStake.toString(), "2000000000000000002000", "User token staking details didn't update as expected");
		assert.equal(totalStakedTokens.toString(), "2000000000000000003000","Staking Contract token balance did not update as expected")
	})


    it("Non-STAKERs should be able to Stake for 3 month LockUp period with Low APY", async ()=>{

		// Checking User Stake Details update in Swan Stakng Contract
		const stake = await swanInstance.stakeTokensThreeMonth(1000, {from:accounts[2] });
		const tokenBalanceAfterStake = await swanInstance.userTotalStakes(accounts[2]);
		
		// Checking SwanStaking contract token balance change
		const totalStakedTokens = await swanInstance.totalStakedTokens();

		const event = stake.logs[0].args

		//Updating time to check withdrawl functions	

		//Checking sturct updation in the Staking contract
		assert.equal(event._user,accounts[2],"User address is not Same");
		assert.equal(event._amount.toString(), "1000","Amount entered is not Same");
		assert.equal(event._lockupPeriod.toString(), "3","LockUpPeriod is not same");
		assert.equal(event._interest.toString(), "16","APY not assigned currectly for 12%");	

		assert.equal(tokenBalanceAfterStake.toString(), "2000", "User token staking details didn't update as expected");
		assert.equal(totalStakedTokens.toString(), "2000000000000000004000","Staking Contract token balance did not update as expected")
	})


});


