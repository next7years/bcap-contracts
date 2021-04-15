// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interface/ICapx.sol";

contract Treasury {
  using SafeMath for uint256;

  address public capx;
  address public recipient;

  uint256 public vestingAmount;
  uint256 public vestingBegin;
  uint256 public vestingCliff;
  uint256 public vestingEnd;

  uint256 public lastUpdate;

  constructor(
    address capx_,
    address recipient_,
    uint256 vestingAmount_,
    uint256 vestingBegin_,
    uint256 vestingCliff_,
    uint256 vestingEnd_
  ) {
    require(
      vestingBegin_ >= block.timestamp,
      "TreasuryVester::constructor: vesting begin too early"
    );
    require(
      vestingCliff_ >= vestingBegin_,
      "TreasuryVester::constructor: cliff is too early"
    );
    require(
      vestingEnd_ > vestingCliff_,
      "TreasuryVester::constructor: end is too early"
    );

    capx = capx_;
    recipient = recipient_;

    vestingAmount = vestingAmount_;
    vestingBegin = vestingBegin_;
    vestingCliff = vestingCliff_;
    vestingEnd = vestingEnd_;

    lastUpdate = vestingBegin;
  }

  function setRecipient(address recipient_) public {
    require(
      msg.sender == recipient,
      "TreasuryVester::setRecipient: unauthorized"
    );
    recipient = recipient_;
  }

  function claim() public {
    require(
      block.timestamp >= vestingCliff,
      "TreasuryVester::claim: not time yet"
    );
    uint256 amount;
    if (block.timestamp >= vestingEnd) {
      amount = ICapx(capx).balanceOf(address(this));
    } else {
      amount = vestingAmount.mul(block.timestamp - lastUpdate).div(
        vestingEnd - vestingBegin
      );
      lastUpdate = block.timestamp;
    }
    ICapx(capx).transfer(recipient, amount);
  }
}
