// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;


interface ICapx {
  function balanceOf(address account) external view returns (uint256);

  function transfer(address dst, uint256 rawAmount) external returns (bool);
}