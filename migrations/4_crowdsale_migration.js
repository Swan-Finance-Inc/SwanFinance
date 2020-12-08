const SwanToken = artifacts.require("Swan");
const SwanCrowdsale = artifacts.require("Crowdsale")

module.exports = async (deployer,network,accounts) =>{
	deployer.deploy(SwanCrowdsale,accounts[0],accounts[0],SwanToken.address,10000);
};