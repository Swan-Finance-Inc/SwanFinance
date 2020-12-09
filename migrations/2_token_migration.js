const SwanToken = artifacts.require("Swan");

module.exports = async (deployer,network,accounts) =>{
	let token = deployer.deploy(SwanToken);

};
