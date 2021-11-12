// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "./IVaultsCore.sol";
import "./IPriceFeed.sol";

interface IAddressProvider {
  function core() external view returns (IVaultsCore);

  function priceFeed() external view returns (IPriceFeed);

  function stablex() external view returns (address);
}