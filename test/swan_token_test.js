const ERC20 = artifacts.require("Swan")
const SwanStakingContract = artifacts.require("SwanStake")

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
		assert.equal(symbol,"Swan","Token symbol is not correct")
	})

	it("Total Supply Should be 50000000000000000000000000000", async () => {
		const totalSupply = await erc20Instance.totalSupply();
		assert.equal(totalSupply.toString(), '50000000000000000000000000000',"Total Supply is wrongly assigned");
	})
	
	it("Minted tokens should be assigned to Owner", async () => {
		const totalTokens = await erc20Instance.balanceOf(accounts[0]);
		assert.equal(totalTokens.toString(), '50000000000000000000000000000',"Tokens Minted doesn't match tokens owned by Contract")
	});


	it("sendTokenSaleWallet is transferring tokens as expected", async () => {
		const beforeBalance = await erc20Instance.balanceOf(accounts[1]);
		await erc20Instance.sendTokenSaleWallet(accounts[1],1000);
		const afterBalance = await erc20Instance.balanceOf(accounts[1]);
		const walletBalanceAfter = await erc20Instance.tokenSaleWallet();
		const currentBalance  = afterBalance - beforeBalance;

		assert.equal(currentBalance.toString(), "1000", "sendTokenSaleWallet function didn't transfer tokens as expected.")	
		assert.equal(walletBalanceAfter.toString(), "13999999999999999999999999000","Wallet Balance didn't change")
	});

	it("sendGeneralFundWallet is transferring tokens as expected", async () => {
		const beforeBalance = await erc20Instance.balanceOf(accounts[1]);
		await erc20Instance.sendGeneralFundWallet(accounts[1],1000);
		const afterBalance = await erc20Instance.balanceOf(accounts[1]);
		const walletBalanceAfter = await erc20Instance.generalFundWallet();
		const currentBalance  = afterBalance - beforeBalance;
		
		assert.equal(currentBalance.toString(), "1000", "sendGeneralFundWallet function didn't transfer tokens as expected.")	
		assert.equal(walletBalanceAfter.toString(), "999999999999999999999999000","Wallet Balance didn't change")

	});

	it("sendReserveWalletTokens is transferring tokens as expected", async () => {
		const beforeBalance = await erc20Instance.balanceOf(accounts[1]);
		await erc20Instance.sendReserveWalletTokens(accounts[1],1000);
		const afterBalance = await erc20Instance.balanceOf(accounts[1]);
		const walletBalanceAfter = await erc20Instance.reserveWalletTokens();

		const currentBalance  = afterBalance - beforeBalance;
		assert.equal(currentBalance.toString(), "1000", "sendReserveWalletTokens function didn't transfer tokens as expected.")	
		assert.equal(walletBalanceAfter.toString(), "19999999999999999999999999000","Wallet Balance didn't change")
	});

	it("sendInterestPayoutWallet is transferring tokens as expected", async () => {
		const beforeBalance = await erc20Instance.balanceOf(accounts[1]);
		await erc20Instance.sendInterestPayoutWallet(accounts[1],1000);
		const afterBalance = await erc20Instance.balanceOf(accounts[1]);
		const walletBalanceAfter = await erc20Instance.interestPayoutWallet();
		const currentBalance  = afterBalance - beforeBalance;
		assert.equal(currentBalance.toString(), "1000", "sendInterestPayoutWallet function didn't transfer tokens as expected.")	
		assert.equal(walletBalanceAfter.toString(), "9999999999999999999999999000","Wallet Balance didn't change")
	});

	it("sendTeamMemberHrWallet function is transferring  tokens as expected", async () => {
		const beforeBalance= await erc20Instance.balanceOf(accounts[1]);
		await erc20Instance.sendTeamMemberHrWallet(accounts[1],1000)
		const teamTokens = await erc20Instance.teamTokensLeft(accounts[0]);
		const afterBalance = await erc20Instance.balanceOf(accounts[1]);
		const walletBalanceAfter = await erc20Instance.teamMemberHrWallet();
		const currentBalance = afterBalance - beforeBalance;
		assert.equal(currentBalance.toString(),"500", "sendTeamMemberHrWallet function didn't transfer tokens as expected")
		assert.equal(walletBalanceAfter.toString(), "4999999999999999999999999000","Wallet Balance didn't change")
		assert.equal(teamTokens.toString(), "500","Team Tokens assigned is wrong")
	});

	it("Checked the Burnt function ", async () => {
		const balanceBeforeBurn = await  erc20Instance.balanceOf(accounts[1]);
		await erc20Instance.burn(1000,{from: accounts[1]});
		const currentBalance = await erc20Instance.balanceOf(accounts[1]);
		const currentSupply = await erc20Instance.totalSupply();
		const checkBalance = balanceBeforeBurn - 1000;
		assert.equal(currentBalance.toString(), checkBalance.toString(),"Burn function is not correct")
		assert.equal(currentSupply.toString(), "49999999999999999999999999000","Total Supply didn't decrease");
	})
})