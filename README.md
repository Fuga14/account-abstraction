# Setup

## ENV Setup

`.env` file setup needs to be set before installing dependencies

1. Create a .env file with predefined variables
2. `cp .env.example .env`
3. Set all variables

## Dependencies installation

```bash
bun install
forge install
```

## Test

To run scripts for MinimalAccount on ETH chain run:

```bash
forge test --match-path test/ethereum/MinimalAccountTest.t.sol -vv
```

# Scripts running

## ZkSync

Contracts compilation:

```bash
npx hardhat compile --network zkSyncTestnet
```

Deploy ZkMinimalAccount:

```bash
npx hardhat deploy-zksync --script deployZkMinimalAccount.ts --network zkSyncTestnet
```
