/* eslint no-use-before-define: "warn" */
const fs = require("fs");
const chalk = require("chalk");
const { ethers, upgrades } = require('hardhat');
const { utils } = require("ethers");
const R = require("ramda");
require('@openzeppelin/hardhat-upgrades');

const main = async () => {

  console.log("\n\n 📡 Deploying...\n");

  const LeboToken = await deploy("LeboToken")
  const Treasury = await deployProxy("Treasury", [])

  //Lock Token
  // const currentTimestampInSeconds = Math.round(Date.now() / 1000);
   // const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
  //  const enableStartDate = 30 * 60;
  //  const lockDuration = 15 * 60;
  //  const enableStartDateUnlockTime = currentTimestampInSeconds + enableStartDate;
  //  const unlockTime = lockDuration;
  
  // const TokenLock = await deployProxy("TokenLock", [LeboToken.address, enableStartDateUnlockTime, unlockTime])
  // const TeamAdvisorLock = await deployProxy("TeamAdvisorLock", [LeboToken.address, enableStartDateUnlockTime, unlockTime])
  // const SeedInvestorLock = await deployProxy("SeedInvestorLock", [LeboToken.address, enableStartDateUnlockTime, unlockTime])

  // Utils
  // const AirDrop = await deploy("AirDrop", [])
  // const Deposit = await deploy("Deposit", [])

  console.log(
    " 💾  Artifacts (address, abi, and args) saved to: ",
    chalk.blue("packages/hardhat/artifacts/"),
    "\n\n"
  );
};

const deploy = async (contractName) => {
  const gas = await ethers.provider.getGasPr
  const Contract = await ethers.getContractFactory(contractName);
  
  console.log(` 🛰  Deploying: ${contractName}`);

  const contract = await Contract.deploy();
  const deployed = await contract.deployed();

  const encoded = abiEncodeArgs(deployed, []);
  fs.writeFileSync(`artifacts/${contractName}.address`, deployed.address);

  console.log(
    " 📄",
    chalk.cyan(contractName),
    "deployed to:",
    chalk.magenta(deployed.address),
  );

  if (!encoded || encoded.length <= 2) return deployed;
  fs.writeFileSync(`artifacts/${contractName}.args`, encoded.slice(2));

  return deployed;
};

const deployProxy = async (contractName, contractArgs) => {
  const gas = await ethers.provider.getGasPr
  const Contract = await ethers.getContractFactory(contractName);

  console.log(` 🛰  Proxy deploying: ${contractName}`);

  const contract = await upgrades.deployProxy(
    Contract, 
    contractArgs, {
    gas: gas,
    initializer: "initialize"
  });
  
  const deployed = await contract.deployed();

  const encoded = abiEncodeArgs(deployed, []);
  fs.writeFileSync(`artifacts/${contractName}.address`, deployed.address);

  console.log(
    " 📄",
    chalk.cyan(contractName),
    "deployed to:",
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