// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { ILendingPool } from "@aave/protocol-v2/contracts/interfaces/ILendingPool.sol";
import { FlashLoanReceiverBase } from "@aave/protocol-v2/contracts/flashloan/base/FlashLoanReceiverBase.sol";

import "./interfaces/IVault.sol";
import "./interfaces/IAddressProvider.sol";
import "./interfaces/IVaultsCore.sol";

contract Leverage is Ownable {
  using SafeMath for uint256;

  event Initialize(address indexed owner);

  IVault public constant BALANCER_VAULT = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

  IAddressProvider public a;
  ILendingPool public lendingPool;

  function initialize(IAddressProvider _a, ILendingPool _lendingPool) external {
    require(address(a) == address(0));
    require(address(_a) != address(0));
    require(address(_lendingPool) != address(0));

    a = _a;
    lendingPool = _lendingPool;
    emit Initialize(msg.sender);
  }

  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address initiator,
    bytes calldata params
  ) external returns (bool) {
    require(msg.sender == address(lendingPool), "caller must be lendingPool");
    require(assets.length == 1, "can only have one asset");

    IERC20 token = IERC20(assets[0]);

    bytes32 poolId = abi.decode(params, (bytes32));

    uint256 repayAmount = amounts[0] + premiums[0];
    uint256 repayValue = a.priceFeed().convertFrom(assets[0], repayAmount);
    token.approve(address(a.core()), token.balanceOf(address(this)));
    a.core().depositAndBorrow(assets[0], token.balanceOf(address(this)), repayValue);

    _swapAsset(poolId, assets[0]);
    token.approve(address(lendingPool), repayAmount);

    return true;
  }

  function leverage(
    address asset,
    uint256 debt,
    bytes32 poolId
  ) external onlyOwner {
    address receiverAddress = address(this);

    address[] memory assets = new address[](1);
    assets[0] = asset;

    uint256[] memory amounts = new uint256[](1);
    amounts[0] = debt;

    uint256[] memory modes = new uint256[](1);
    modes[0] = 0;

    address onBehalfOf = address(this);
    bytes memory params = abi.encode(poolId);
    uint16 referralCode = 0;

    lendingPool.flashLoan(receiverAddress, assets, amounts, modes, onBehalfOf, params, referralCode);
  }

  function withdrawFromVault(uint256 vaultId, uint256 amount) external onlyOwner {
    a.core().withdraw(vaultId, amount);
  }

  function borrowFromVault(uint256 vaultId, uint256 amount) external onlyOwner {
    a.core().borrow(vaultId, amount);
  }

  function withdrawAsset(address asset) external onlyOwner {
    IERC20 token = IERC20(asset);
    token.transfer(msg.sender, token.balanceOf(address(this)));
  }

  function _swapAsset(bytes32 poolId, address asset) internal {
    bytes memory userData = abi.encode();
    IERC20 stablex = IERC20(a.stablex());

    stablex.approve(address(BALANCER_VAULT), stablex.balanceOf(address(this)));
    IVault.SingleSwap memory singleSwap = IVault.SingleSwap(
      poolId,
      IVault.SwapKind.GIVEN_IN,
      IAsset(a.stablex()),
      IAsset(asset),
      stablex.balanceOf(address(this)),
      userData
    );
    IVault.FundManagement memory fundManagement = IVault.FundManagement(
      address(this),
      false,
      payable(address(this)),
      false
    );
    BALANCER_VAULT.swap(singleSwap, fundManagement, 0, type(uint256).max);
  }
}