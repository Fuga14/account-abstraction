import { HardhatRuntimeEnvironment } from "hardhat/types";
import chalk from "chalk";

export async function verify(
    hre: HardhatRuntimeEnvironment,
    contractName: string,
    contractAddress: string,
    constructorArguments: any[]
) {
    console.info(chalk.yellow("Sleep for 10 seconds before verification \n"));
    // Sleep 10 seconds
    await new Promise((resolve) => setTimeout(resolve, 10000));

    console.info(chalk.yellow("Verifying contract on Etherscan... \n"));

    // Verify on Etherscan
    await hre.run("verify:verify", {
        address: contractAddress,
        contract: contractName,
        constructorArguments: constructorArguments
    });
}
