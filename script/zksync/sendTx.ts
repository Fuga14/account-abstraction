import { HardhatRuntimeEnvironment } from "hardhat/types";
import chalk from "chalk";
import { verify } from "./helpers";
import { deployer } from "hardhat";
import { utils, types, EIP712Signer } from "zksync-ethers";
import { ethers } from "hardhat";

const ZK_MINIMAL_ADDRESS = "0x2776c9467dfd1CBd33F177Bb9d8B278F1240C0BE";
const TOKEN = "0x83ab333762f0D3A6A28109962fF37312Dc3c6a69";
const AMOUNT_TO_MINT = "1000000";

const sendTxScript = async (hre: HardhatRuntimeEnvironment) => {
    const zkWallet = await hre.deployer.getWallet(0);

    const artifact = await hre.deployer.loadArtifact("MockERC20");

    const zkMinimalAccount = await hre.ethers.getContractAt("ZkMinimalAccount", ZK_MINIMAL_ADDRESS, zkWallet);
    const token = await hre.ethers.getContractAt("MockERC20", TOKEN, zkWallet);

    // If this doesn't log the owner, you have an issue!
    console.log(`The owner of this minimal account is: ${await zkMinimalAccount.owner()}`);
    console.log(`Current total supply is: ${await token.totalSupply()}\n`);

    console.log(`Populating transaction...\n`);
    let mintData = await token.mint.populateTransaction(zkWallet, AMOUNT_TO_MINT);

    let aaTx = mintData;

    const gasLimit = await token.mint.estimateGas(zkWallet, AMOUNT_TO_MINT);
    const gasPrice = (await hre.ethers.provider.getFeeData()).gasPrice!;

    aaTx = {
        ...aaTx,
        from: ZK_MINIMAL_ADDRESS,
        gasLimit: gasLimit,
        gasPrice: gasPrice,
        chainId: (await hre.ethers.provider.getNetwork()).chainId,
        nonce: await hre.ethers.provider.getTransactionCount(ZK_MINIMAL_ADDRESS),
        type: 113,
        customData: {
            gasPerPubdata: utils.DEFAULT_GAS_PER_PUBDATA_LIMIT
        } as types.Eip712Meta,
        value: 0n
    };

    const signedTxHash = EIP712Signer.getSignedDigest(aaTx);

    console.log("Signing transaction...");

    const signature = hre.ethers.concat([hre.ethers.Signature.from(zkWallet.signingKey.sign(signedTxHash)).serialized]);

    console.log(signature);

    aaTx.customData = {
        ...aaTx.customData,
        customSignature: signature
    };

    console.log(
        `The minimal account nonce before the first tx is ${await hre.ethers.provider.getTransactionCount(
            ZK_MINIMAL_ADDRESS
        )}`
    );

    // const sentTx = await hre.ethers.provider.broadcastTransaction(types.Transaction.from(aaTx).serialized);
    const sentTx = await hre.ethers.provider.broadcastTransaction(types.Transaction.from(aaTx).serialized);

    console.log(`Transaction sent from minimal account with hash ${sentTx.hash}`);
    await sentTx.wait();

    // Checking that the nonce for the account has increased
    console.log(
        `The account's nonce after the first tx is ${await hre.ethers.provider.getTransactionCount(ZK_MINIMAL_ADDRESS)}`
    );

    console.log(`Current total supply is: ${await token.totalSupply()}`);
};

export default sendTxScript;
