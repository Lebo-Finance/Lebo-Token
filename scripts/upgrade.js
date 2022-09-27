/* eslint no-use-before-define: "warn" */
const fs = require("fs");
const chalk = require("chalk");
const { ethers, upgrades } = require('hardhat');
const { utils } = require("ethers");
const R = require("ramda");
require('@openzeppelin/hardhat-upgrades');

const main = async () => {

    console.log("\n\n 📡 Deploying...\n");
  
    await upgrade(LOGIC_CONTRACT, "TokenUpgrade") // <-- add in constructor args like line 16 vvvv
  
    // const exampleToken = await deploy("ExampleToken")
    // const examplePriceOracle = await deploy("ExamplePriceOracle")
    // const smartContractWallet = await deploy("SmartContractWallet",[exampleToken.address,examplePriceOracle.address])
  
    console.log(
      " 💾  Artifacts (address, abi, and args) saved to: ",
      chalk.blue("packages/hardhat/artifacts/"),
      "\n\n"
    );
  };
  
  const upgrade = async (logic, contractName) => {
    const contractArgs = [];
  
    console.log(` 🛰  Upgrade Proxy`);
  
    const Proxy = await ethers.getContractFactory(contractName);
    const proxy = await upgrades.upgradeProxy(logic, Proxy);
  
    const deployed = await proxy.deployed();
  
    const encoded = abiEncodeArgs(proxy, contractArgs);
    fs.writeFileSync(`artifacts/${contractName}.address`, proxy.address);
    
  
    console.log(
      " 📄",
      chalk.cyan(contractName),
      "Upgrade to:",
      chalk.magenta(deployed.address),
    );
  
    if (!encoded || encoded.length <= 2) return deployed;
    fs.writeFileSync(`artifacts/${contractName}.args`, encoded.slice(2));
  
    return deployed;
  };
  
  // ------ utils -------
  
  // abi encodes contract arguments
  // useful when you want to manually verify the contracts
  // for example, on Etherscan
  const abiEncodeArgs = (deployed, contractArgs) => {
    // not writing abi encoded args if this does not pass
    if (
      !contractArgs ||
      !deployed ||
      !R.hasPath(["interface", "deploy"], deployed)
    ) {
      return "";
    }
    const encoded = utils.defaultAbiCoder.encode(
      deployed.interface.deploy.inputs,
      contractArgs
    );
    return encoded;
  };
  
  // checks if it is a Solidity file
  const isSolidity = (fileName) =>
    fileName.indexOf(".sol") >= 0 && fileName.indexOf(".swp") < 0;
  
  const readArgsFile = (contractName) => {
    let args = [];
    try {
      const argsFile = `./contracts/${contractName}.args`;
      if (!fs.existsSync(argsFile)) return args;
      args = JSON.parse(fs.readFileSync(argsFile));
    } catch (e) {
      console.log(e);
    }
    return args;
  };
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });