const SwanCrowdsale = artifacts.require("Crowdsale")
const ERC20 = artifacts.require("Swan")

var BN = require('bignumber.js');

const { time } = require('@openzeppelin/test-helpers');
const Web3 = require('web3');
// const web3 = new Web3('http:localhost:8545')


contract("Swan Crowdsale", (accounts)=>{
	let erc20Instance = null;
	let crowdsaleInstance = null;

	before(async () => {
        erc20Instance = await ERC20.deployed();
        crowdsaleInstance = await SwanCrowdsale.deployed();
	});

	it("Crowdsale constructor should be initialized properly", async () => {
		const value = new BN(30000000000000000000000);
		const tokenAddress = await crowdsaleInstance.token();
		const ownerAddress = await crowdsaleInstance.owner();
		const walletAddress = await crowdsaleInstance.wallet();
		const ethPrice = await crowdsaleInstance.ethPrice();
		const currentStage = await crowdsaleInstance.getStage();
		
		await erc20Instance.transfer(crowdsaleInstance.address,value);

		assert.equal(tokenAddress, erc20Instance.address,"Addresses are not same");
		assert.equal(ownerAddress, accounts[0],"Owner address is not correct");
		assert.equal(walletAddress, accounts[0],"Wallet address is not correc");
		assert.equal(ethPrice.toString(), "10000","EthPrice is not correc");
		assert.equal(currentStage, "CrowdSale Not Started","Stage is not Correct");
	});

	it("Owner should be able to Add WhiteListed Users",async () =>{
		const checkApprovalForUser1_before = await crowdsaleInstance.whitelistedContributors(accounts[1]);
		const checkApprovalForUser2_before = await crowdsaleInstance.whitelistedContributors(accounts[2]);
		const checkApprovalForUser3_before = await crowdsaleInstance.whitelistedContributors(accounts[3]);

		const userArray = [accounts[1],accounts[2],accounts[3]]
		await crowdsaleInstance.authorizeKyc(userArray);

		const checkApprovalForUser1_after = await crowdsaleInstance.whitelistedContributors(accounts[1]);
		const checkApprovalForUser2_after = await crowdsaleInstance.whitelistedContributors(accounts[2]);
		const checkApprovalForUser3_after = await crowdsaleInstance.whitelistedContributors(accounts[3]);
		
		assert.equal(checkApprovalForUser1_before,false,"Before Approval is Wrong for User 1");
		assert.equal(checkApprovalForUser2_before,false,"Before Approval is Wrong for User 2");
		assert.equal(checkApprovalForUser3_before,false,"Before Approval is Wrong for User 3");
		assert.equal(checkApprovalForUser1_after,true,"After Approval is Wrong for User 1");
		assert.equal(checkApprovalForUser2_after,true,"After Approval is Wrong for User 2");
		assert.equal(checkApprovalForUser3_after,true,"After Approval is Wrong for User 3");
	});

	it("Only Owner should be able to Add WhiteListed Users",async () =>{
		const userArray = [accounts[1],accounts[2],accounts[3]]
		try{
			await crowdsaleInstance.authorizeKyc(userArray);
		}catch(error){
			const invalidOpcode = error.message.search("revert") >= 0 
			assert(invalidOpcode,"Expected revert, got '"+ error +"' instead");
		}
	})

	it("Owner should be able to Start A Private Sale",async () =>{
		const bool_SaleStarted_before = await crowdsaleInstance.crowdSaleStarted();

		await crowdsaleInstance.startPrivateSale();
		const bool_SaleStarted_after = await crowdsaleInstance.crowdSaleStarted();
		const currentStage = await crowdsaleInstance.getStage();

		assert.equal(bool_SaleStarted_before,false,"Sale already started");
		assert.equal(bool_SaleStarted_after,true,"Sale didn't start");
		assert.equal(currentStage,"Private Sale Start","Current Stage is not correct");
	})

	it("Owner should be able to End A Private Sale",async () =>{
		const bool_SaleStarted_before = await crowdsaleInstance.crowdSaleStarted();

		await crowdsaleInstance.endPrivateSale();
		const bool_SaleStarted_after = await crowdsaleInstance.crowdSaleStarted();
		const currentStage = await crowdsaleInstance.getStage();

		assert.equal(bool_SaleStarted_before,true,"Sale already started");
		assert.equal(bool_SaleStarted_after,true,"Sale didn't start");
		assert.equal(currentStage,"Private Sale End","Current Stage is not correct");
	})

	it("Only Owner should be able to Start A Private Sale",async () =>{
		try{
			await crowdsaleInstance.startPrivateSale();
		}catch(error){
			const invalidOpcode = error.message.search("revert") >= 0 
			assert(invalidOpcode,"Expected revert, got '"+ error +"' instead");
		}
	});

	it("Owner should be able to Set Ether Price",async () =>{
		const currentPrice_before = await crowdsaleInstance.ethPrice();
		await crowdsaleInstance.setEthPriceInCents(10000);
		const currentPrice_after = await crowdsaleInstance.ethPrice();

		assert.equal(currentPrice_before.toString(),"10000","Before Price is not correct");
		assert.equal(currentPrice_after.toString(),"10000","After Price is not right");

	})

	it("Only Owner should be able to Set Ether Price",async () =>{
		try{
		await crowdsaleInstance.setEthPriceInCents(10000);
		}catch(error){
			const invalidOpcode = error.message.search("revert") >= 0 
			assert(invalidOpcode,"Expected revert, got '"+ error +"' instead");
		}
	})

	it("Owner should be able to Pause the CrowdSale Contract",async () =>{
		const bool_SaleStarted_before = await crowdsaleInstance.crowdSaleStarted();
		await crowdsaleInstance.pause();
	
		const bool_SaleStarted_after = await crowdsaleInstance.crowdSaleStarted(); 
		const currentStage = await crowdsaleInstance.getStage();
		const bool_pause = await crowdsaleInstance.Paused();

		assert.equal(currentStage,"paused","Current Stage is not correct");
		assert.equal(bool_pause,true,"Pause is false");
		assert.equal(bool_SaleStarted_after,true,"Sale Started is False");
		assert.equal(bool_SaleStarted_before,true,"Sale Started is True")
	})

	it("Only Owner should be able to Pause the CrowdSale Contract",async () =>{
		try{
		await crowdsaleInstance.pause();
		}catch(error){
			const invalidOpcode = error.message.search("revert") >= 0 
			assert(invalidOpcode,"Expected revert, got '"+ error +"' instead");
		}
	})

	it("Owner should be able to Restart the the CrowdSale",async () =>{
		await crowdsaleInstance.restartSale();
		const currentStage = await crowdsaleInstance.getStage();
		const bool_pause = await crowdsaleInstance.Paused();

		console.log(currentStage)
		assert.equal(currentStage,"Private Sale End","Current Stage is not correct");
		assert.equal(bool_pause,false,"Pause is true")
	})

	it("Only Owner should be able to Restart the the CrowdSale",async () =>{
		try{
		await crowdsaleInstance.restartSale();
		}catch(error){
			const invalidOpcode = error.message.search("revert") >= 0 
			assert(invalidOpcode,"Expected revert, got '"+ error +"' instead");
		}
	})



	it("Owner should be able to Start Pre Sale",async () =>{
		await crowdsaleInstance.startPreSale();

		const currentStage = await crowdsaleInstance.getStage();
		assert.equal(currentStage,"Presale Started","Current Stage is not Right")
	})

	it("Owner should be able to End Pre Sale",async () =>{
		await crowdsaleInstance.endPreSale();

		const currentStage = await crowdsaleInstance.getStage();
		assert.equal(currentStage,"Presale Ended","Current Stage is not Right")
	})

	it("Owner should be able to Start CrowdSaleRoundOne",async () =>{
		await crowdsaleInstance.startCrowdSaleRoundOne();

		const currentStage = await crowdsaleInstance.getStage();
		assert.equal(currentStage,"CrowdSale Round One Started","Current Stage is not Right")
	})

	it("Owner should be able to End CrowdSaleRoundOne",async () =>{
		await crowdsaleInstance.endCrowdSaleRoundOne();

		const currentStage = await crowdsaleInstance.getStage();
		assert.equal(currentStage,"CrowdSale Round One End","Current Stage is not Right")
	})

	it("Owner should be able to Start CrowdSaleRoundTwo",async () =>{
		await crowdsaleInstance.startCrowdSaleRoundTwo();

		const currentStage = await crowdsaleInstance.getStage();
		assert.equal(currentStage,"CrowdSale Round Two Started","Current Stage is not Right")
	})


	it("Owner should be able to End CrowdSaleRoundTwo",async () =>{
		await crowdsaleInstance.endCrowdSaleRoundTwo();

		const currentStage = await crowdsaleInstance.getStage();
		assert.equal(currentStage,"CrowdSale Round Two End","Current Stage is not Right")
	})

	it("Owner should be able to Start CrowdSaleRoundThree",async () =>{
		await crowdsaleInstance.startCrowdSaleRoundThree();

		const currentStage = await crowdsaleInstance.getStage();
		assert.equal(currentStage,"CrowdSale Round Three Started","Current Stage is not Right")
	})

	it("Owner should be able to End CrowdSaleRoundThree",async () =>{
		await crowdsaleInstance.endCrowdSaleRoundThree();

		const currentStage = await crowdsaleInstance.getStage();
		assert.equal(currentStage,"CrowdSale Round Three End","Current Stage is not Right")
	})

	it("Owner should be able to Start CrowdSaleRoundFour",async () =>{
		await crowdsaleInstance.startCrowdSaleRoundFour();

		const currentStage = await crowdsaleInstance.getStage();
		assert.equal(currentStage,"CrowdSale Round Four Started","Current Stage is not Right")
	})

	it("Owner should be able to End CrowdSaleRoundFour",async () =>{
		await crowdsaleInstance.endCrowdSaleRoundFour();

		const currentStage = await crowdsaleInstance.getStage();
		assert.equal(currentStage,"CrowdSale Round Four End","Current Stage is not Right")
	})

	// it("User should be able to Buy Swan Tokens",async () =>{
	// 	const ethValue = new BN(6000000000000000000);
	// 	//const user1_balance_before = erc20Instance.balanceOf(accounts[1]);

	// 	await crowdsaleInstance.startPrivateSale({from:accounts[0]});
	// 	const buyToken = await crowdsaleInstance.buyTokens(accounts[1],{from:accounts[1],value:web3.utils.toWei('6','Ether')});

	// 	const user1_balance_after = erc20Instance.balanceOf(accounts[1]);

	// 	console.log(user1_balance_after.toString())
	// 	//assert.equal(user1_balance_before.toString(),"0","Balance is not zero");
	// 	// assert.equal(user1_balance_after.toString(),"")
	// });

	it("User should NOT be able to Buy Swan Tokens if Contract is Paused",async () =>{
		try{
		await crowdsaleInstance.pause();
		await crowdsaleInstance.buyTokens(accounts[1],{from:accounts[1],value:web3.utils.toWei('6','Ether')});
		}catch(error){
			const invalidOpcode = error.message.search("revert") >= 0 
			assert(invalidOpcode,"Expected revert, got '"+ error +"' instead");
		}
		await crowdsaleInstance.restartSale();

	})

	it("User should NOT be able to Buy Swan Tokens if he/she is not WhiteListed Investor",async () =>{
		try{
		await crowdsaleInstance.buyTokens(accounts[1],{from:accounts[6],value:web3.utils.toWei('6','Ether')});
		}catch(error){
			const invalidOpcode = error.message.search("revert") >= 0 
			assert(invalidOpcode,"Expected revert, got '"+ error +"' instead");
		}

	})

});



