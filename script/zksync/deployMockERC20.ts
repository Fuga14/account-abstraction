import { HardhatRuntimeEnvironment } from "hardhat/types";
import chalk from "chalk";
import { verify } from "./helpers";

const deployScript = async (hre: HardhatRuntimeEnvironment) => {
    console.info(chalk.yellow("Running deploy script for the ERC20Mock..."));

    const zkWallet = await hre.deployer.getWallet(0);
    const initialSupply = 0;
    const decimals = 18;

    const artifact = await hre.deployer.loadArtifact("MockERC20");

    const factoryContract = await hre.deployer.deploy(artifact, [initialSupply, decimals]);

    const contractAddress = await factoryContract.getAddress();
    console.info(chalk.green(`${artifact.contractName} was deployed to ${contractAddress}`));

    await verify(hre, artifact.contractName, contractAddress, [initialSupply, decimals]);
};

export default deployScript;
