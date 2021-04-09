# [Ice](https://popsicle.finance/) LP compound smart contract

1. install dependencies
> npm install
2. create .env file and fill it with your PRIVATE_KEY
3. deploy the contract
> npx hardhat run scripts/deploy.js --network ftmprod
4. call the **approve** of the slp pair
5. call **deposit** of the contract
6. call **harvest** from time to time
7. enjoy your compound

The contract is upgradeable incase of some bugs that make your funds unwithdrawable.