import { ethers } from "hardhat";

const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const PAR = "0x68037790A0229e9Ce6EaA8A99ea92964106C4703";
const ADDRESS_PROVIDER = "0x6fAE125De41C03fa7d917CCfa17Ba54eF4FEb014";
const VAULTS_DATA_PROVIDER = "0x9C29d8D359255e524702c7A9c95C6e6ae38274Dc";
const AAVE_LENDING_POOL = "0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9";
const BALANCER_POOL_ID =
  "0x29d7a7e0d781c957696697b94d4bc18c651e358e000200000000000000000049";

const ONE_ETH = "1000000000000000000";
const TWO_ETH = "2000000000000000000";

async function main() {
  const par = await ethers.getContractAt("@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20", PAR);
  const weth = await ethers.getContractAt("IWETH", WETH);
  const vaultsDataProvider = await ethers.getContractAt(
    "IVaultsDataProvider",
    VAULTS_DATA_PROVIDER
  );

  await weth.deposit({
    value: ONE_ETH,
  });
  const Leverage = await ethers.getContractFactory("Leverage");
  const leverage = await Leverage.deploy(ADDRESS_PROVIDER, AAVE_LENDING_POOL);

  // we deposit our initial 1 ETH in the leverage contract
  await weth.transfer(leverage.address, ONE_ETH);
  console.log("Leverage address", leverage.address);

  const wethBalanceBefore = await weth.balanceOf(leverage.address);
  console.log("wethBalanceBefore", ethers.utils.formatUnits(wethBalanceBefore.toString()));

  // get 1 extra ETH, so double our ETH
  await leverage.leverage(WETH, ONE_ETH, BALANCER_POOL_ID);

  const wethBalanceAfter = await weth.balanceOf(leverage.address);
  console.log("wethBalanceAfter", ethers.utils.formatUnits(wethBalanceAfter.toString()));
  const parBalanceAfter = await par.balanceOf(leverage.address);
  console.log("parBalanceAfter", ethers.utils.formatUnits(parBalanceAfter.toString()));

  const lastVaultID = await vaultsDataProvider.vaultCount();

  const vaultCollateralBalance = await vaultsDataProvider.vaultCollateralBalance(lastVaultID);
  console.log("vaultCollateralBalance", ethers.utils.formatUnits(vaultCollateralBalance.toString()));
  const vaultDebt = await vaultsDataProvider.vaultDebt(lastVaultID);
  console.log("vaultDebt", ethers.utils.formatUnits(vaultDebt.toString()));

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
