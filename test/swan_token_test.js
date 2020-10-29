const ERC20 = artifacts.require("Swan")
const SwanStakingContract = artifacts.require("SwanStake")

const { time } = require('@openzeppelin/test-helpers');

contract('ERC20', (accounts) =>{
	let erc20Instance = null;
	let swanInstance = null;

	before(async () => {
        erc20Instance = await ERC20.deployed();
        swanInstance = await SwanStakingContract.deployed();
	});

	//Testing the SWAN Token Contract
	it("Owner is Correct", async () => {
		const owner = await erc20Instance.owner();
		assert.equal(owner,accounts[0],"Owner's address is wrongly assigned");
	});

	it("Name of the token should be SWAN FINANCE",async () => {
		const name = await erc20Instance.name();
		assert.equal(name,"Swan Finance","Name is wrongly assigned");
	})

	it("Symbol should be Swan", async () => {
		const symbol = await erc20Instance.symbol();
		assert.equal(symbol,"SWAN","Token symbol is not correct")
	})

	it("Total Supply Should be 50000000000000000000000000000", async () => {
		const totalSupply = await erc20Instance.totalSupply();
		assert.equal(totalSupply.toString(), '50000000000000000000000000000',"Total Supply is wrongly assigned");
	})
	
	it("Minted tokens should be assigned to Owner", async () => {
		const totalTokens = await erc20Instance.balanceOf(accounts[0]);
		assert.equal(totalTokens.toString(), '50000000000000000000000000000',"Tokens Minted doesn't match tokens owned by Contract")
	});

	it("sendTeamMemberHrWallet function is transferring  tokens as expected", async () => {
		const beforeBalance= await erc20Instance.balanceOf(accounts[1]);
		await erc20Instance.sendTeamMemberHrWallet(accounts[1],1000)
		const teamTokens = await erc20Instance.teamTokensLeft(accounts[1]);
		const afterBalance = await erc20Instance.balanceOf(accounts[1]);
		const walletBalanceAfter = await erc20Instance.teamMemberHrWallet();
		const currentBalance = afterBalance - beforeBalance;
		assert.equal(currentBalance.toString(),"500", "sendTeamMemberHrWallet function didn't transfer tokens as expected")
		assert.equal(walletBalanceAfter.toString(), "4999999999999999999999999000","Wallet Balance didn't change")
		assert.equal(teamTokens.toString(), "500","Team Tokens assigned is wrong")
	});

	it("saleOverSet function is working fine", async () => {
		await erc20Instance.saleOverSet();
		const bool_contractSaleOver = await erc20Instance.contractSaleOver();

		assert.equal(bool_contractSaleOver,true,"Contract Sale over didn't switch to true")
	});

	it("Checked the Burnt function ", async () => {
		const balanceBeforeBurn = await  erc20Instance.balanceOf(accounts[1]);
		await erc20Instance.burn(500,{from: accounts[1]});
		const currentBalance = await erc20Instance.balanceOf(accounts[1]);
		const currentSupply = await erc20Instance.totalSupply();
		const checkBalance = balanceBeforeBurn - 500;
		assert.equal(currentBalance.toString(), checkBalance.toString(),"Burn function is not correct")
		assert.equal(currentSupply.toString(), "49999999999999999999999999500","Total Supply didn't decrease");
	})

	it("Increasing Time",async () => {
		await time.increase(time.duration.minutes(260200));
	})

	it("Should be able to Redeem Team Tokens Left",async () => {

		await erc20Instance.redeemTeamTokensLeft({ from:accounts[1] });
		
		const tokenLeft = await  erc20Instance.teamTokensLeft(accounts[1]);
		const userBalance = await erc20Instance.balanceOf(accounts[1]);
		// console.log(userBalance.toString());
		assert.equal(tokenLeft.toString(),'0',"Token Left is not equal to 0");
	});

})