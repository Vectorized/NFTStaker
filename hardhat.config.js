/**
 * @type import('hardhat/config').HardhatUserConfig
 */
require('@nomiclabs/hardhat-ethers');
module.exports = {
	solidity: "0.8.10",
	settings: {
		optimizer: {
			enabled: true,
			runs: 20000,
		},
	},
};
