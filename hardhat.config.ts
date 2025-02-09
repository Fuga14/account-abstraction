import dotenv from "dotenv";
dotenv.config();

import { HardhatUserConfig } from "hardhat/config";

import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-foundry";
import "@matterlabs/hardhat-zksync";

const PRIVATE_KEY = process.env.PRIVATE_KEY || "";

const config: HardhatUserConfig = {
    solidity: {
        compilers: [
            {
                version: "0.8.28",
                settings: {
                    optimizer: { enabled: true, runs: 200 },
                    viaIR: true
                }
            }
        ]
    },
    zksolc: {
        version: "latest"
    },
    networks: {
        sepolia: {
            url: process.env.SEPOLIA_RPC_URL,
            accounts: [PRIVATE_KEY],
            zksync: false
        },
        zkSyncTestnet: {
            url: process.env.ZKSYNC_SEPOLIA_RPC_URL,
            accounts: [PRIVATE_KEY],
            ethNetwork: "sepolia",
            zksync: true,
            deployPaths: "script/zksync/",
            verifyURL: "https://explorer.sepolia.era.zksync.dev/contract_verification"
        }
    }
};

export default config;
