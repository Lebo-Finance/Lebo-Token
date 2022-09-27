require("@nomiclabs/hardhat-etherscan");
require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "👩🕵👨🙋👷 Prints the list of accounts (only for localhost)", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
  console.log("👩🕵 👨🙋👷 these accounts only for localhost network.");
  console.log('To see their private keys🔑🗝 when you run "npx hardhat node."');
});

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "bsctestnet",
  networks:{
    localhost: {
      // chainId: 1337,
      url: "http://127.0.0.1:8545",
      accounts: [process.env.ETHTESTNET_PRIVATE_KEY],
    },
    hardhat: {
    // chainId: 31337,
    },
    bsctestnet:{
      url: process.env.BSCTESTNET_NETWORK_URL,
      chainId: 97,
      gasPrice: 20000000000,
      accounts: [process.env.BSCTESTNET_PRIVATE_KEY],
    },
    bscmainnet: {
      url: process.env.BSCMAINNET_NETWORK_URL,
      chainId: 56,
      gasPrice: 20000000000,
      accounts: [process.env.BSCMAINNET_PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: process.env.BSCTESTNET_SCAN_KEY,
    // apiKey: {
      // localhost: process.env.ETHTESTNET_SCAN_KEY,
      // bsctestnet: process.env.BSCTESTNET_SCAN_KEY,
      // bscmainnet: process.env.BSCMAINNET_SCAN_KEY,
    // } 
  },
  settings: {
    optimizer: {
        enabled: true,
        runs: 10000,
      },
  },
  solidity: "0.8.16",
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 20000
  }
};