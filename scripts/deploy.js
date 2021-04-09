const { ethers, upgrades } = require("hardhat");

var fs = require("fs");

async function main() {

    // npx hardhat run scripts/deploy.js --network ftmprod

    const [deployer] = await ethers.getSigners();

    IceCompound = await ethers.getContractFactory("IceCompound");

    console.log(
        "Deploying contracts with the account:",
        deployer.address
    );

    console.log("Account balance:", (await deployer.getBalance()).toString());

    console.log("deploy ice compound...")
    iceCompound = await upgrades.deployProxy(IceCompound, [], { initializer: 'initialize' })
    console.log("ice compound address: ", iceCompound.address);

    var datetime = new Date();
    var output = './deployed_' + datetime + ".json";

    var deployed = {
        IceCompound: iceCompound.address
    };

    fs.writeFileSync(output, JSON.stringify(deployed, null, 4));

}

main();