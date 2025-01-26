install:
    forge install
    npm install

deploy-minimal-account-sepolia:
    source .env
    forge script script/ethereum/DeployMinimalAccount.s.sol:DeployMinimalAccount --rpc-url $SEPOLIA_RPC_URL --account d4 --sender 0x0309004C4fB9943797f5C530abd8cddE564A9fD4 --verify --etherscan-api-key $ETHERSCAN_API_KEY --optimize --optimizer-runs 200 --broadcast -vvvv

execute-from-owner-sepolia:
    source .env
    forge script script/ethereum/OwnerExecution.s.sol:OwnerExecution --rpc-url $SEPOLIA_RPC_URL --account d4 --sender 0x0309004C4fB9943797f5C530abd8cddE564A9fD4 --broadcast -vvvv