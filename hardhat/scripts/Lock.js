async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying with account:", deployer.address);
  const balance = await deployer.getBalance();
  console.log("Deployer balance:", ethers.utils.formatEther(balance), "ETH");

  const unlockTime = Math.floor(Date.now() / 1000) + 60;

  const Lock = await ethers.getContractFactory("Lock");
 
  const lock = await Lock.deploy(unlockTime, {
    value: ethers.utils.parseEther("0.01"),
  });

  await lock.deployed();

  console.log(`Lock deployed to: ${lock.address}`);
}
