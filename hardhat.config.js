/**
 * @type import('hardhat/config').HardhatUserConfig
 */
require("@nomiclabs/hardhat-waffle");
require('@openzeppelin/hardhat-upgrades');

require('dotenv').config()

const PRIVATE_KEY = process.env.PRIVATE_KEY;

module.exports = {
  solidity: {
    version: "0.6.12",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    ftmprod: {
      url: `https://rpcapi.fantom.network`,
      accounts: [`0x${PRIVATE_KEY}`],
      gas: 8000000,
      gasPrice: 22000000000
    }
  },
};
