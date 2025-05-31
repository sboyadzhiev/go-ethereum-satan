task("deploy", "Deploys the contract")
.addParam("unlockTime", "Timestamp after which the contract will be deployed")
.setAction(async (taskArgs, hre) => {
if (!taskArgs.unlockTime) {
    throw new Error("unlockTime is required");
}

const Contract = await hre.ethers.getContractFactory("Lock");
const contract = await Contract.deploy(taskArgs.unlockTime);
await contract.waitForDeployment();

console.log("Contract deployed to:", contract.target);


const unlockTimeSet = await contract.unlockTime();
  if (unlockTimeSet.toString() !== taskArgs.unlockTime) {
    throw new Error("unlockTime was not set correctly");
  }
});