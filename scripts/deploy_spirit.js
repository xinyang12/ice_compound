const { ethers, upgrades } = require("hardhat");

var fs = require("fs");

async function main() {

    // npx hardhat run scripts/deploy.js --network ftmprod

    const [deployer] = await ethers.getSigners();

    SpiritCompound = await ethers.getContractFactory("SpiritCompound");

    console.log(
        "Deploying contracts with the account:",
        deployer.address
    );

    console.log("Account balance:", (await deployer.getBalance()).toString());

    console.log("deploy spirit compound...")
    spiritCompound = await upgrades.deployProxy(SpiritCompound, [], { initializer: 'initialize' })
    console.log("spirit compound address: ", spiritCompound.address);

    var datetime = new Date();
    var output = './deployed_' + datetime + ".json";

    var deployed = {
        SpiritCompound: spiritCompound.address
    };

    fs.writeFileSync(output, JSON.stringify(deployed, null, 4));

}

main();