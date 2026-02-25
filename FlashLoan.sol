// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IFlashLoanSimpleReceiver} from "@aave/core-v3/contracts/flashloan/interfaces/IFlashLoanSimpleReceiver.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";

/**
 * @title FlashLoan
 * @dev Professional implementation of a flash loan receiver for Aave V3.
 */
contract FlashLoan is IFlashLoanSimpleReceiver {
    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;
    IPool public immutable POOL;
    address private immutable owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }

    constructor(address _addressProvider) {
        ADDRESSES_PROVIDER = IPoolAddressesProvider(_addressProvider);
        POOL = IPool(ADDRESSES_PROVIDER.getPool());
        owner = msg.sender;
    }

    /**
     * @dev Initiates a flash loan.
     */
    function requestFlashLoan(address _token, uint256 _amount) public onlyOwner {
        address receiverAddress = address(this);
        address asset = _token;
        uint256 amount = _amount;
        bytes memory params = "";
        uint16 referralCode = 0;

        POOL.flashLoanSimple(
            receiverAddress,
            asset,
            amount,
            params,
            referralCode
        );
    }

    /**
     * @dev Executed by Aave Pool after receiving the flash loan.
     */
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        // 1. ARBITRAGE / LIQUIDATION LOGIC GOES HERE
        // Example: Swap borrowed asset for another, then swap back for profit.
        
        // 2. Ensure contract has enough to repay (Amount + Premium)
        uint256 amountToRepay = amount + premium;
        require(IERC20(asset).balanceOf(address(this)) >= amountToRepay, "Not enough to repay loan");

        // 3. Approve Aave Pool to pull the repayment
        IERC20(asset).approve(address(POOL), amountToRepay);

        return true;
    }

    function getPool() external view returns (address) {
        return address(POOL);
    }

    function withdraw(address _token) external onlyOwner {
        IERC20 token = IERC20(_token);
        token.transfer(owner, token.balanceOf(address(this)));
    }

    receive() external payable {}
}
