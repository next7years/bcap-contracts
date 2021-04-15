// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;


interface CapxInterface {
  function getPriorVotes(address account, uint256 blockNumber)
    external
    view
    returns (uint96);
}