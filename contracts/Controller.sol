// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "./interface/IVaultHandler.sol";
import "./BCAP.sol";
import "./oracles/ChainlinkOracle.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title BCAP Controller
 * @author Cap X Fund
 * @notice Controller contract in charge of managing the settings of the vaults, rewards and BCAP token. It acts as the owner of these contracts.
 */
contract Controller is Ownable {
  /// @dev Enum which saves the available functions to emergency call.
  enum Functions {BURNFEE, LIQUIDATION, PAUSE}

  /// @notice Address that can set to 0 the fees or pause the vaults in an emergency event
  address public guardian;

  /** @dev Interface constants*/
  bytes4 private constant _INTERFACE_ID_IVAULT = 0x9e75ab0c;
  bytes4 private constant _INTERFACE_ID_BCAP = 0xbd115939;
  bytes4 private constant _INTERFACE_ID_CHAINLINK_ORACLE = 0x85be402b;

  /// @dev tracks which vault was emergency called
  mapping(IVaultHandler => mapping(Functions => bool)) private emergencyCalled;

  /// @notice An event emitted when the guardian is updated
  event GuardianSet(address indexed _owner, address guardian);

  /// @notice An event emitted when a transaction is executed
  event TransactionExecuted(
    address indexed target,
    uint256 value,
    string signature,
    bytes data
  );

  /**
   * @notice Constructor
   * @param _guardian The guardian address
   */
  constructor(address _guardian) {
    require(
      _guardian != address(0),
      "Controller::constructor: guardian can't be zero"
    );
    guardian = _guardian;
  }

  /// @notice Throws if called by any account other than the guardian
  modifier onlyGuardian() {
    require(
      msg.sender == guardian,
      "Controller::onlyGuardian: caller is not the guardian"
    );
    _;
  }

  /**
   * @notice Throws if vault is not valid.
   * @param _vault address
   */
  modifier validVault(IVaultHandler _vault) {
    require(
      ERC165Checker.supportsInterface(address(_vault), _INTERFACE_ID_IVAULT),
      "Controller::validVault: not a valid vault"
    );
    _;
  }

  /**
   * @notice Throws if BCAP Token is not valid
   * @param _bcap address
   */
  modifier validBCAP(BCAP _bcap) {
    require(
      ERC165Checker.supportsInterface(address(_bcap), _INTERFACE_ID_BCAP),
      "Controller::validBCAP: not a valid BCAP ERC20"
    );
    _;
  }

  /**
   * @notice Throws if Chainlink Oracle is not valid
   * @param _oracle address
   */
  modifier validChainlinkOracle(address _oracle) {
    require(
      ERC165Checker.supportsInterface(
        address(_oracle),
        _INTERFACE_ID_CHAINLINK_ORACLE
      ),
      "Controller::validChainlinkController: not a valid Chainlink Oracle"
    );
    _;
  }

  /**
   * @notice Sets the guardian of the controller
   * @param _guardian address of the guardian
   * @dev Only owner can call it
   */
  function setGuardian(address _guardian) external onlyOwner {
    require(
      _guardian != address(0),
      "Controller::setGuardian: guardian can't be zero"
    );
    guardian = _guardian;
    emit GuardianSet(msg.sender, _guardian);
  }

  /**
   * @notice Sets the ratio of a vault
   * @param _vault address
   * @param _ratio value
   * @dev Only owner can call it
   */
  function setRatio(IVaultHandler _vault, uint256 _ratio)
    external
    onlyOwner
    validVault(_vault)
  {
    _vault.setRatio(_ratio);
  }

  /**
   * @notice Sets the burn fee of a vault
   * @param _vault address
   * @param _burnFee value
   * @dev Only owner can call it
   */
  function setBurnFee(IVaultHandler _vault, uint256 _burnFee)
    external
    onlyOwner
    validVault(_vault)
  {
    _vault.setBurnFee(_burnFee);
  }

  /**
   * @notice Sets the burn fee to 0, only used on a black swan event
   * @param _vault address
   * @dev Only guardian can call it
   * @dev Validates if _vault is valid
   */
  function setEmergencyBurnFee(IVaultHandler _vault)
    external
    onlyGuardian
    validVault(_vault)
  {
    require(
      emergencyCalled[_vault][Functions.BURNFEE] != true,
      "Controller::setEmergencyBurnFee: emergency call already used"
    );
    emergencyCalled[_vault][Functions.BURNFEE] = true;
    _vault.setBurnFee(0);
  }

  /**
   * @notice Sets the liquidation penalty of a vault
   * @param _vault address
   * @param _liquidationPenalty value
   * @dev Only owner can call it
   */
  function setLiquidationPenalty(
    IVaultHandler _vault,
    uint256 _liquidationPenalty
  ) external onlyOwner validVault(_vault) {
    _vault.setLiquidationPenalty(_liquidationPenalty);
  }

  /**
   * @notice Sets the liquidation penalty of a vault to 0, only used on a black swan event
   * @param _vault address
   * @dev Only guardian can call it
   * @dev Validates if _vault is valid
   */
  function setEmergencyLiquidationPenalty(IVaultHandler _vault)
    external
    onlyGuardian
    validVault(_vault)
  {
    require(
      emergencyCalled[_vault][Functions.LIQUIDATION] != true,
      "Controller::setEmergencyLiquidationPenalty: emergency call already used"
    );
    emergencyCalled[_vault][Functions.LIQUIDATION] = true;
    _vault.setLiquidationPenalty(0);
  }

  /**
   * @notice Pauses the Vault
   * @param _vault address
   * @dev Only guardian can call it
   * @dev Validates if _vault is valid
   */
  function pauseVault(IVaultHandler _vault)
    external
    onlyGuardian
    validVault(_vault)
  {
    require(
      emergencyCalled[_vault][Functions.PAUSE] != true,
      "Controller::pauseVault: emergency call already used"
    );
    emergencyCalled[_vault][Functions.PAUSE] = true;
    _vault.pause();
  }

  /**
   * @notice Unpauses the Vault
   * @param _vault address
   * @dev Only guardian can call it
   * @dev Validates if _vault is valid
   */
  function unpauseVault(IVaultHandler _vault)
    external
    onlyGuardian
    validVault(_vault)
  {
    _vault.unpause();
  }

  /**
   * @notice Enables or disables the BCAP Cap
   * @param _bcap address
   * @param _enable bool
   * @dev Only owner can call it
   * @dev Validates if _bcap is valid
   */
  function enableBCAPCap(BCAP _bcap, bool _enable)
    external
    onlyOwner
    validBCAP(_bcap)
  {
    _bcap.enableCap(_enable);
  }

  /**
   * @notice Sets the BCAP maximum minting value
   * @param _bcap address
   * @param _cap uint value
   * @dev Only owner can call it
   * @dev Validates if _bcap is valid
   */
  function setBCAPCap(BCAP _bcap, uint256 _cap)
    external
    onlyOwner
    validBCAP(_bcap)
  {
    _bcap.setCap(_cap);
  }

  /**
   * @notice Adds Vault to BCAP ERC20
   * @param _bcap address
   * @param _vault address
   * @dev Only owner can call it
   * @dev Validates if _bcap is valid
   * @dev Validates if _vault is valid
   */
  function addBCAPVault(BCAP _bcap, IVaultHandler _vault)
    external
    onlyOwner
    validBCAP(_bcap)
    validVault(_vault)
  {
    _bcap.addVaultHandler(address(_vault));
  }

  /**
   * @notice Removes Vault to BCAP ERC20
   * @param _bcap address
   * @param _vault address
   * @dev Only owner can call it
   * @dev Validates if _bcap is valid
   * @dev Validates if _vault is valid
   */
  function removeBCAPVault(BCAP _bcap, IVaultHandler _vault)
    external
    onlyOwner
    validBCAP(_bcap)
    validVault(_vault)
  {
    _bcap.removeVaultHandler(address(_vault));
  }

  /**
   * @notice Allows the owner to execute custom transactions
   * @param target address
   * @param value uint256
   * @param signature string
   * @param data bytes
   * @dev Only owner can call it
   */
  function executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data
  ) external payable onlyOwner returns (bytes memory) {
    bytes memory callData;
    if (bytes(signature).length == 0) {
      callData = data;
    } else {
      callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }

    require(
      target != address(0),
      "Controller::executeTransaction: target can't be zero"
    );

    // solium-disable-next-line security/no-call-value
    (bool success, bytes memory returnData) =
      target.call{value: value}(callData);
    require(
      success,
      "Controller::executeTransaction: Transaction execution reverted."
    );

    emit TransactionExecuted(target, value, signature, data);
    (target, value, signature, data);

    return returnData;
  }

  /**
   * @notice Retrieves the eth stuck on the Controller
   * @param _to address
   * @dev Only owner can call it
   */
  function retrieveETH(address _to) external onlyOwner {
    require(
      _to != address(0),
      "Controller::retrieveETH: address can't be zero"
    );
    uint256 amount = address(this).balance;
    payable(_to).transfer(amount);
  }

  /// @notice Allows the contract to receive ETH
  receive() external payable {}
}
