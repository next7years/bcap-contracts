// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;


interface IRewardHandler {
  function stake(address _staker, uint256 amount) external;

  function withdraw(address _staker, uint256 amount) external;

  function getRewardFromVault(address _staker) external;
}