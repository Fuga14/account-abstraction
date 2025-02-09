import { HardhatRuntimeEnvironment } from "hardhat/types";
import chalk from "chalk";
import { verify } from "./helpers";

const deployScript = async (hre: HardhatRuntimeEnvironment) => {
    console.info(chalk.yellow("Running deploy script for the ZkMinimalAccount... \n"));

    const zkWallet = await hre.deployer.getWallet(0);

    // Deposit some funds to L2 in order to be able to perform deposits.
    // const depositHandle = await zkWallet.deposit({
    //     to: zkWallet.address,
    //     token: zk.utils.ETH_ADDRESS,
    //     amount: ethers.parseEther('0.01'),
    // });
    // await depositHandle.wait();

    const artifact = await hre.deployer.loadArtifact("ZkMinimalAccount");

    const factoryContract = await hre.deployer.deploy(artifact, []);

    const contractAddress = await factoryContract.getAddress();
    console.info(chalk.green(`${artifact.contractName} was deployed to ${contractAddress}\n`));

    // Verify
    await verify(hre, artifact.contractName, contractAddress, []);
};

export default deployScript;
