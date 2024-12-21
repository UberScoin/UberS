// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20.0;

import {ERC20} from "ERC20.sol";

contract UberSCoin is ERC20 {
    error ZeroValue();
    error InvalidRecipient();
    error Unauthorized();

    // Constants
    uint256 private constant FOUNDER_FEE = 1; // 0.1%
    uint256 private constant FEE_DENOMINATOR = 1000;
    uint256 private constant TOTAL_SUPPLY = 20_000_000 * 1e18;

    // State variables
    address public feeWallet;

    // Events
    event FeeWalletUpdated(address newFeeWallet);
    event TransferLogged(address indexed from, address indexed to, uint256 amount);

    constructor(address _feeWallet) ERC20("UberS Coin", "UBERS") {
        require(_feeWallet != address(0), "Invalid fee wallet address");
        feeWallet = _feeWallet;

        // Mint all tokens to the founder wallet
        _mint(_feeWallet, TOTAL_SUPPLY); // 20M to fee wallet
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        _transferWithFee(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        uint256 currentAllowance = allowance(from, msg.sender);
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(from, msg.sender, currentAllowance - amount);
        _transferWithFee(from, to, amount);
        return true;
    }

    function _transferWithFee(
        address from,
        address to,
        uint256 amount
    ) internal {
        if (to == address(0)) revert InvalidRecipient();
        if (amount == 0) revert ZeroValue();

        uint256 feeAmount = (amount * FOUNDER_FEE) / FEE_DENOMINATOR;
        uint256 transferAmount = amount - feeAmount;

        // Perform transfers in a single step to reduce gas
        super._transfer(from, feeWallet, feeAmount);
        super._transfer(from, to, transferAmount);
    }

    function updateFeeWallet(address newFeeWallet) external {
        if (msg.sender != feeWallet) revert Unauthorized();
        require(newFeeWallet != address(0), "Invalid fee wallet address");
        feeWallet = newFeeWallet;
        emit FeeWalletUpdated(newFeeWallet);
    }
}
